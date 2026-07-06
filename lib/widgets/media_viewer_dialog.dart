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
  final TextEditingController _tagsController = TextEditingController();
  String _loadedTags = '';

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
    _tagsController.dispose();
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
      initialEntryMode: DatePickerEntryMode.calendarOnly,
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

  Future<void> _loadTagsForItem(int itemId) async {
    final tags = await getIt<AppDatabase>().getTagsForMediaItem(itemId);
    if (!mounted || _lastLoadedItemId != itemId) return;
    _loadedTags = tags;
    _tagsController.text = tags;
  }

  Future<void> _openTagsEditor() async {
    final currentTags = _tagsController.text.trim().isEmpty
      ? <String>[]
      : _tagsController.text.trim().split(RegExp(r'\s+'));
    
    final result = await showDialog<List<String>>(
      context: context,
      barrierDismissible: true,
      builder: (_) => TagsEditorDialog(initialTags: currentTags),
    );

    if (result == null || !mounted) return;

    _tagsController.text = result.join(' ');
    await _saveTags();
  }

  Future<void> _saveTags() async {
    final item = _gallery.getItem(_currentIndex);
    if (item == null) return;
    if (_tagsController.text == _loadedTags) return;
    await _gallery.updateTags(item, _tagsController.text);
    _loadedTags = _tagsController.text;
  }

  Future<void> _goToPrevious() async {
    if (_currentIndex > 0) {
      await _saveTags();
      _evictCurrentImage();
      _resetZoom();
      setState(() => _currentIndex--);
    }
  }

  Future<void> _goToNext() async {
    final totalCount = _gallery.totalItemCount;
    if (_currentIndex < totalCount - 1) {
      await _saveTags();
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
        _saveTags().then((_) { if (mounted) Navigator.pop(context); });
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
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadTagsForItem(item.id));
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
                          onTap: () async {
                            final nav = Navigator.of(context);
                            await _saveTags();
                            nav.pop();
                          },
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
                              // edit tags
                              _ToolbarButton(
                                icon: Icons.edit_outlined,
                                color: const Color.fromARGB(255, 58, 182, 0),
                                tooltip: "Edit tags",
                                onPressed: _openTagsEditor,
                              ),

                              const SizedBox(width: 8),

                              // copy
                              _ToolbarButton(
                                icon: Icons.content_copy_rounded, 
                                color: const Color(0xFFFFC600), 
                                tooltip: "Copy to clipboard", 
                                onPressed: () => MediaActionService.onCopy(dialogContext, item),
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

                              const SizedBox(width: 5),

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
                                onPressed: () async {
                                  final nav = Navigator.of(context);
                                  await _saveTags();
                                  nav.pop();
                                },
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

// dialog for viewing, adding, and removing tags on a media item
// shown via showDialog(...) -- returns the final List<String> of tags if
// user pressed Save, or null if dismissed/cancelled
class TagsEditorDialog extends StatefulWidget {
  final List<String> initialTags;

  const TagsEditorDialog({
    super.key,
    required this.initialTags,
  });

  @override
  State<TagsEditorDialog> createState() => _TagsEditorDialogState();
}

class _TagsEditorDialogState extends State<TagsEditorDialog> {
  late List<String> _tags;
  final TextEditingController _newTagController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _lastMaxScrollExtent = 0;

  static const _bgColor = Color(0xFF282828);
  static const _pillColor = Color(0xFF9C9C9C);
  static const _hintColor = Color(0xFF424242);

  static const double _maxDialogHeight = 450;
  static const double _titleSectionHeight = 48;
  static const double _textFieldSectionHeight = 60;
  static const double _buttonSectionHeight = 48;
  static const double _maxTagsAreaHeight = _maxDialogHeight - _titleSectionHeight - _textFieldSectionHeight - _buttonSectionHeight;

  @override
  void initState() {
    super.initState();
    _tags = List<String>.from(widget.initialTags);
    _newTagController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollExtent());
  }

  @override
  void dispose() {
    _newTagController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncScrollExtent() {
    if (_scrollController.hasClients) {
      _lastMaxScrollExtent = _scrollController.position.maxScrollExtent;
    }
  }

  void _addTag(String raw) {
    final tag = raw.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() => _tags.add(tag));
    _newTagController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeScrollToBottom());
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollExtent());
  }

  // scrolls to the bottom only if content actually went into a new row
  // if the added tag pill fit in the current row, scroll position is left untouched
  void _maybeScrollToBottom() {
    if (!_scrollController.hasClients) return;
    final newMax = _scrollController.position.maxScrollExtent;
    if (newMax > _lastMaxScrollExtent + 0.5) {
      _scrollController.animateTo(
        newMax,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
    _lastMaxScrollExtent = newMax;
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  void _handleSave() {
    final pending = _newTagController.text.trim();
    final finalTags = List<String>.from(_tags);
    if (pending.isNotEmpty && !finalTags.contains(pending)) {
      finalTags.add(pending);
    }
    Navigator.of(context).pop(finalTags);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: _maxDialogHeight),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // title
            SizedBox(
              height: _titleSectionHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Tags",
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 20, 
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
              ),
            ),
        
            // tag pills area (scrollable, wraps into rows)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: _maxTagsAreaHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(right: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags
                          .map((t) => _TagPill(
                              tag: t,
                              pillColor: _pillColor,
                              textColor: _bgColor,
                              onRemove: () => _removeTag(t),
                            ))
                          .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        
            // tag writing text field
            SizedBox(
              height: _textFieldSectionHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _newTagController,
                  autofocus: true,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: Colors.white,
                  onSubmitted: _addTag,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: _bgColor,
                    contentPadding: const EdgeInsets.only(top: 8, bottom: 11),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Text(
                        '#',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ),
                    hintText: 'Create new tag',
                    hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
                    border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    suffixIcon: Visibility(
                      visible: _newTagController.text.isNotEmpty,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: () => _addTag(_newTagController.text),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: _pillColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 16, color: _bgColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        
            // cancel, save row
            SizedBox(
              height: _buttonSectionHeight,
              child: Row(
                children: [
                  Expanded(
                    child: _DialogActionButton(label: "Cancel", onTap: _handleCancel),
                  ),
                  Container(width: 1, height: 24, color: Colors.white),
                  Expanded(
                    child: _DialogActionButton(label: "Save", onTap: _handleSave),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// individual tag pill
// shows "#tag" normally, switches to "Xtag" on hover to indicate it's clickable for removal
class _TagPill extends StatefulWidget {
  final String tag;
  final Color pillColor;
  final Color textColor;
  final VoidCallback onRemove;

  const _TagPill({
    required this.tag,
    required this.pillColor,
    required this.textColor,
    required this.onRemove,
  });

  @override
  State<_TagPill> createState() => _TagPillState();
}

class _TagPillState extends State<_TagPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final displayTag = widget.tag.length > 20 ? '${widget.tag.substring(0, 20)}...' : widget.tag;
    final symbol = _hovered ? 'X' : '#';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onRemove,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.pillColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$symbol$displayTag',
            style: TextStyle(
              color: widget.textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// shared style for the Cancel / Save buttons
class _DialogActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _DialogActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  State<_DialogActionButton> createState() => _DialogActionButtonState();
}

class _DialogActionButtonState extends State<_DialogActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF3D3D3D) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 14, 
              fontWeight: FontWeight.w500
            ),
          ),
        ),
      ),
    );
  }
}