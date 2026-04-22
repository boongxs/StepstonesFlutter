import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../data/app_database.dart';
import 'universal_player.dart';

class MediaPreviewDialog extends StatefulWidget {
  final MediaItem item;

  const MediaPreviewDialog({
    super.key,
    required this.item,
  });

  @override
  State<MediaPreviewDialog> createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<MediaPreviewDialog> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();

    imageCache.clear();
    imageCache.clearLiveImages();

    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final screenSize = MediaQuery.of(context).size;

    const double margin = 48.0;
    final maxAvailableSize = Size(
      screenSize.width - (margin * 2),
      screenSize.height - (margin * 2),
    );

    final displaySize = _calculateOptimalSize(item.width, item.height, maxAvailableSize);
    final fullPath = p.join(item.mediaFolderPath, item.hashedFileName);

    Widget contentWidget;

    if (item.fileType == 'image' || item.fileType == 'gif') {
      contentWidget = Image.file(
        File(fullPath),
        key: ValueKey(item.id),
        fit: BoxFit.contain,
        cacheWidth: displaySize.width.toInt(),
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
          child: Stack(
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
                  onTap: () {},
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
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: contentWidget,
                    ),
                  ),
                ),
              ),

              // top-right toolbar — close only
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
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: "Close",
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Size _calculateOptimalSize(int dbWidth, int dbHeight, Size maxSize) {
  if (dbWidth <= 0 || dbHeight <= 0) {
    return const Size(400, 400);
  }

  double w = dbWidth.toDouble();
  double h = dbHeight.toDouble();
  final aspectRatio = w / h;

  if (w < 400 || h < 400) {
    double scaleW = 400 / w;
    double scaleH = 400 / h;
    double finalScale = (scaleW > scaleH) ? scaleW : scaleH;
    w = w * finalScale;
    h = h * finalScale;
  }

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
