import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../data/app_database.dart';
import '../services/media_action_service.dart';
import 'universal_player.dart';
import 'toolbar_button.dart';
import '../providers/main_provider.dart';

class MediaViewerDialog extends StatelessWidget {
  final MediaItem item;
  final MainProvider provider;

  const MediaViewerDialog({
    super.key,
    required this.item,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
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

    Widget contentWidget;

    if (item.fileType == 'image' || item.fileType == 'gif') {
      contentWidget = Image.file(
        File(fullPath),
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white, size: 48),
        ),
      );
    } else {
      contentWidget = UniversalPlayer(
        filePath: fullPath,
        isAudio: item.fileType == 'audio',
      );
    }

    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Builder(
          builder: (dialogContext) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0, // no shadow from the dialog container itself
              insetPadding: EdgeInsets.zero, // the dark area around the viewer
              child: Stack(
                children: [
                  // background click listener, catches any click that isn't on image itself
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox.expand(),
                    ),
                  ),
            
                  // content
                  Center(
                    child: GestureDetector(
                      onTap: () {}, // swallow clicks on the image so that it doesn't close the dialog
                      child: SizedBox(
                        width: displaySize.width,
                        height: displaySize.height,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: contentWidget,
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
                          ToolbarButton(
                            icon: Icons.content_copy_rounded,
                            color: const Color(0xFFFFC600),
                            tooltip: "Copy to clipboard",
                            onPressed: () => MediaActionService.onCopy(dialogContext, item),
                          ),
            
                          const SizedBox(width: 8),
            
                          // edit tags
                          ToolbarButton(
                            icon: Icons.edit_rounded,
                            color: const Color(0xFF25BB00),
                            tooltip: "Edit Tags",
                            onPressed: () => MediaActionService.onEdit(dialogContext, provider, item),
                          ),
            
                          const SizedBox(width: 8),
            
                          // delete
                          ToolbarButton(
                            icon: Icons.delete_outline_rounded,
                            color: const Color(0xFFFF5454),
                            tooltip: "Delete",
                            onPressed: () async {
                              await MediaActionService.onDelete(
                                context,
                                provider,
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
              ),
            );
          }
        ),
      ),
    );
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
}