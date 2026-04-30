import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../../data/app_database.dart';
import '../../locator.dart';
import '../services/media_action_service.dart';
import 'universal_player.dart';
import 'package:provider/provider.dart';
import '../controllers/gallery_controller.dart';

class MediaViewerDialog extends StatefulWidget {
  final int initialIndex;

  const MediaViewerDialog({
    super.key,
    required this.initialIndex,
  });

  @override
  State<MediaViewerDialog> createState() => _MediaViewerDialogState();
}

class _MediaViewerDialogState extends State<MediaViewerDialog> {
  late int _currentIndex;
  late FocusNode _focusNode;
  late TransformationController _transformationController;
  late GalleryController _gallery;
  double _zoomLevel = 1.0;
  Size _displaySize = Size.zero;
  String? _localDate;
  String? _localTime;
  int? _lastLoadedItemId;
  final Map<int, String?> _dateOverrides = {};
  final Map<int, String?> _timeOverrides = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _focusNode = FocusNode();
    _transformationController = TransformationController();
    _gallery = context.read<GalleryController>();

    _transformationController.addListener(() {
      final scale = _transformationController.value.getMaxScaleOnAxis().clamp(1.0, 4.0);
      if ((scale - _zoomLevel).abs() > 0.01) {
        setState(() => _zoomLevel = scale);
      }
    });

    // request focus when dialog opens so that keyboard events can be captured
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _transformationController.dispose();
    _evictCurrentImage();
    _gallery.fullRefresh(resetScroll: false);
    super.dispose();
  }

  void _setZoom(double zoom) {
    final cx = _displaySize.width / 2;
    final cy = _displaySize.height / 2;
    _transformationController.value = Matrix4.identity()
      ..translateByDouble(cx, cy, 0, 1)
      ..scaleByDouble(zoom, zoom, 1, 1)
      ..translateByDouble(-cx, -cy, 0, 1);
    setState(() => _zoomLevel = zoom);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    _zoomLevel = 1.0;
  }

  void _evictCurrentImage() {
    final item = _gallery.getItem(_currentIndex);
    if (item == null) return;
    if (item.fileType != 'image' && item.fileType != 'gif') return;
    final path = p.join(item.mediaFolderPath, item.hashedFileName);
    FileImage(File(path)).evict();
  }

  Future<void> _pickDate(MediaItem item) async {
    DateTime initial;
    try {
      initial = _localDate != null ? DateTime.parse(_localDate!) : DateTime.now();
    } catch (_) {
      initial = DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.inputOnly,
    );
    if (picked == null) return;

    final formatted =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    await getIt<AppDatabase>().updateMediaDateTime(item.id, formatted, _localTime);
    if (!mounted) return;
    _dateOverrides[item.id] = formatted;
    setState(() => _localDate = formatted);
  }

  Future<void> _pickTime(MediaItem item) async {
    TimeOfDay initial = TimeOfDay.now();
    if (_localTime != null) {
      final parts = _localTime!.split(':');
      if (parts.length >= 2) {
        initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.inputOnly,
    );
    if (picked == null) return;

    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    await getIt<AppDatabase>().updateMediaDateTime(item.id, _localDate, formatted);
    if (!mounted) return;
    _timeOverrides[item.id] = formatted;
    setState(() => _localTime = formatted);
  }

  Future<void> _clearDate(MediaItem item) async {
    await getIt<AppDatabase>().updateMediaDateTime(item.id, null, _localTime);
    if (!mounted) return;
    _dateOverrides[item.id] = null;
    setState(() => _localDate = null);
  }

  Future<void> _clearTime(MediaItem item) async {
    await getIt<AppDatabase>().updateMediaDateTime(item.id, _localDate, null);
    if (!mounted) return;
    _timeOverrides[item.id] = null;
    setState(() => _localTime = null);
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _evictCurrentImage();
      _resetZoom();
      setState(() => _currentIndex--);
    }
  }

  void _goToNext() {
    final totalCount = context.read<GalleryController>().totalItemCount;
    if (_currentIndex < totalCount - 1) {
      _evictCurrentImage();
      _resetZoom();
      setState(() => _currentIndex++);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _goToPrevious();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _goToNext();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryController>(
      builder: (context, gallery, _) {
        // fetch current item
        final MediaItem? item = gallery.getItem(_currentIndex);
        final int totalCount = gallery.totalItemCount;

        // if item hasn't loaded from the DB yet, show a loading indicator
        if (item == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        // sync local date/time when navigating to a different item
        if (_lastLoadedItemId != item.id) {
          _lastLoadedItemId = item.id;
          _localDate = _dateOverrides.containsKey(item.id) ? _dateOverrides[item.id] : item.date;
          _localTime = _timeOverrides.containsKey(item.id) ? _timeOverrides[item.id] : item.time;
        }

        // get screen size
        final screenSize = MediaQuery.of(context).size;

        // define margins (48px on all sides)
        const double margin = 48.0;
        final maxAvailableSize = Size(
          screenSize.width - (margin * 2),
          screenSize.height - (margin * 2),
        );

        // calculate final display size
        final displaySize = _calculateOptimalSize(
          item.width,
          item.height,
          maxAvailableSize
        );
        _displaySize = displaySize;

        final fullPath = p.join(item.mediaFolderPath, item.hashedFileName);
        final isImageOrGif = item.fileType == 'image' || item.fileType == 'gif';
        final isUnknown = item.fileType == 'unknown';

        // build content
        Widget contentWidget;

        if (isImageOrGif) {
          contentWidget = Image.file(
            File(fullPath),
            key: ValueKey(item.id),
            fit: BoxFit.contain,
            cacheWidth: displaySize.width.toInt(),
            errorBuilder: (ctx, err, stack) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white, size: 48),
            ),
          );
        } else if (isUnknown) {
          contentWidget = Container(
            color: const Color(0xFF282828),
            child: Center(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.insert_drive_file_outlined, size: 80, color: Colors.white54),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text("Show in File Explorer"),
                  onPressed: () {
                    final winPath = fullPath.replaceAll('/', '\\');
                    Process.run('powershell', [
                      '-NoProfile',
                      '-NonInteractive',
                      '-Command',
                      'explorer /select,"$winPath"',
                    ]);
                  },
                ),
              ],
            ),
          ),
          );
        } else {
          contentWidget = UniversalPlayer(
            key: ValueKey(item.id),
            filePath: fullPath,
            isAudio: item.fileType == 'audio',
          );
        }

        return ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: KeyboardListener(
              focusNode: _focusNode,
              onKeyEvent: _handleKeyEvent,
              child: Builder(
                builder: (dialogContext) {
                  return Stack(
                    children: [
                      // background tap to close
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.pop(context),
                          child: const SizedBox.expand(),
                        ),
                      ),

                      // main content
                      Center(
                        child: GestureDetector(
                          onTap: () {}, // swallow taps on the content
                          child: SizedBox(
                            width: displaySize.width,
                            height: displaySize.height,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 20,
                                    spreadRadius: 5
                                  )
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: isImageOrGif
                                  ? InteractiveViewer(
                                        transformationController: _transformationController,
                                        scaleFactor: 1000,
                                        minScale: 1.0,
                                        maxScale: 4.0,
                                        panEnabled: _zoomLevel > 1.0,
                                        boundaryMargin: EdgeInsets.zero,
                                        child: contentWidget,
                                    )
                                  : contentWidget,
                            ),
                          ),
                        ),
                      ),

                      // navigation arrows (left)
                      Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: Icon(
                              Icons.chevron_left_rounded, 
                              size: 64,
                              color: (_currentIndex == 0) ? Colors.white24 : Colors.white
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: "Previous",
                            onPressed: (_currentIndex == 0) ? null : _goToPrevious,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black26,
                              hoverColor: Colors.black54,
                              disabledBackgroundColor: Colors.black12,
                            ),
                          ),
                        ),
                      ),

                      // navigation arrows (right)
                      Positioned(
                        right: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: Icon(
                              Icons.chevron_right_rounded,
                              size: 64,
                              color: (_currentIndex == totalCount - 1) ? Colors.white24 : Colors.white
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: "Next",
                            onPressed: (_currentIndex == totalCount - 1) ? null : _goToNext,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black26,
                              hoverColor: Colors.black54,
                              disabledBackgroundColor: Colors.black12,
                            ),
                          ),
                        ),
                      ),

                      // top right toolbar
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // copy
                              _ToolbarButton(
                                icon: Icons.content_copy_rounded, 
                                color: const Color(0xFFFFC600), 
                                tooltip: "Copy to clipboard", 
                                onPressed: () => MediaActionService.onCopy(dialogContext, item),
                              ),

                              const SizedBox(width: 8),

                              // edit tags
                              _ToolbarButton(
                                icon: Icons.edit_rounded,
                                color: const Color(0xFF25BB00), 
                                tooltip: "Edit Tags", 
                                onPressed: () => MediaActionService.onEdit(dialogContext, item),
                              ),

                              const SizedBox(width: 8),

                              // delete
                              _ToolbarButton(
                                icon: Icons.delete_outline_rounded,
                                color: const Color(0xFFFF5454), 
                                tooltip: "Delete", 
                                onPressed: () async {
                                  await MediaActionService.onDelete(
                                    dialogContext,
                                    item,
                                    onConfirm: () {
                                      Navigator.pop(context);
                                    }
                                  );
                                },
                              ),

                              // zoom slider
                              if (isImageOrGif) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 120,
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                    ),
                                    child: Slider(
                                      value: _zoomLevel,
                                      min: 1.0,
                                      max: 4.0,
                                      onChanged: _setZoom,
                                    ),
                                  ),
                                ),
                                Text(
                                  "${_zoomLevel.toStringAsFixed(1)}x",
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(width: 16),
                              ],

                              Container(
                                width: 1,
                                height: 24,
                                color: Colors.white24,
                              ),

                              const SizedBox(width: 8),

                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white),
                                tooltip: "Close Viewer",
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // info panel (date & time)
                      Positioned(
                          top: 88,
                          right: 20,
                          child: Container(
                            width: 210,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoRow(
                                  label: "Date",
                                  value: _localDate,
                                  placeholder: "Not set",
                                  onTap: () => _pickDate(item),
                                  onClear: _localDate != null ? () => _clearDate(item) : null,
                                ),
                                const SizedBox(height: 8),
                                _InfoRow(
                                  label: "Time",
                                  value: _localTime,
                                  placeholder: "Not set",
                                  onTap: () => _pickTime(item),
                                  onClear: _localTime != null ? () => _clearTime(item) : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

Size _calculateOptimalSize(int dbWidth, int dbHeight, Size maxSize) {
  // fallback if DB has no data (audio files or bad data (0x0))
  if (dbWidth <= 0 || dbHeight <= 0) {
    return const Size(400, 400);
  }

  double w = dbWidth.toDouble();
  double h = dbHeight.toDouble();
  final aspectRatio = w / h;

  // constraint 1: upscale so both sides are at least 400px
  if (w < 400 || h < 400) {
    double scaleW = 400 / w;
    double scaleH = 400 / h;

    double finalScale = (scaleW > scaleH) ? scaleW : scaleH;

    w = w * finalScale;
    h = h * finalScale;
  }

  // constraint 2: shrink to fit the application window if previous result is too large
  if (w > maxSize.width) {
    w = maxSize.width;
    h = w / aspectRatio;
  }

  if (h > maxSize.height) {
    h = maxSize.height;
    w = h * aspectRatio;
  }

  return Size(w, h);
}

// private helper widget for date/time info panel rows
class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
            Expanded(
              child: Text(
                value ?? placeholder,
                style: TextStyle(
                  color: value != null ? Colors.white : Colors.white24,
                  fontSize: 12,
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white38),
              ),
          ],
        ),
      ),
    );
  }
}

// private helper widget for media viewer's top-right toolbar
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        hoverColor: color.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}