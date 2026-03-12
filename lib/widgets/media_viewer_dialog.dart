import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../../data/app_database.dart';
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _focusNode = FocusNode();

    // request focus when dialog opens so that keyboard events can be captured
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _goToNext() {
    final totalCount = context.read<GalleryController>().totalItemCount;

    if (_currentIndex < totalCount - 1) {
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

        final fullPath = p.join(item.mediaFolderPath, item.hashedFileName);

        // build content
        Widget contentWidget;

        if (item.fileType == 'image' || item.fileType == 'gif') {
          contentWidget = Image.file(
            File(fullPath),
            key: ValueKey(item.id),
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white, size: 48),
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
                              child: contentWidget,
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

                              const SizedBox(width: 16),

                              // close button
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