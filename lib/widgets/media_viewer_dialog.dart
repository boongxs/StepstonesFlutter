import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../data/app_database.dart';
import 'universal_player.dart';

class MediaViewerDialog extends StatelessWidget {
  final MediaItem item;

  const MediaViewerDialog({
    super.key,
    required this.item
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
        ],
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

    // constraint 1: upscale if below 400x400 (small media files)
    if (w < 400 && h < 400) {
      // scale until the smaller side hits 400
      if (w < h) {
        w = 400;
        h = w / aspectRatio;
      } else {
        h = 400;
        w = h * aspectRatio;
      }
    }

    // constraint 2: shrink to fit the application window
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