import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../providers/main_provider.dart';
import '../data/app_database.dart';
import '../utils/min_extra_delegate.dart';

class MediaGrid extends StatelessWidget {
  const MediaGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MainProvider>(
      builder: (context, vm, _) {
        // empty state
        if (vm.mediaFolderPath == null) {
          return const Center(child: Text("Select a folder to begin"));
        }

        // show "no items" only if we are not currently syncing to avoid flicker on startup
        if (vm.totalItemCount == 0 && !vm.isSyncingWorkInProgress) {
          return const Center(child: Text("No media items found"));
        }

        // pass the cached base path to cells
        final thumbBaseDir = vm.appSupportPath != null
          ? p.join(vm.appSupportPath!, 'thumbnails')
          : null;

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: vm.totalItemCount, // virtualization: exact count ensures scrollbar is correct

          // responsive layout
          gridDelegate: const SliverGridDelegateWithMinCrossAxisExtent(
            minCrossAxisExtent: 270, // cells will be around 500px wide
            mainAxisExtent: 250, // cells will be exactly 250px tall
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),

          itemBuilder: (context, index) {
            // ask provider for data, if null trigger fetch
            final MediaItem? item = vm.getItem(index);
            return _MediaCell(
              item: item, 
              index: index,
              thumbBaseDir: thumbBaseDir);
          },
        );
      },
    );
  }
}

class _MediaCell extends StatelessWidget {
  final MediaItem? item;
  final int index;
  final String? thumbBaseDir;

  const _MediaCell({
    required this.item, 
    required this.index,
    required this.thumbBaseDir
  });

  @override
  Widget build(BuildContext context) {
    // 1. Loading State (Virtualization Placeholder)
    if (item == null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    // logic extraction
    final hasThumb = item!.thumbnailPath != null && thumbBaseDir != null;
    final fullThumbPath = hasThumb ? p.join(thumbBaseDir!, item!.thumbnailPath!) : null;
    final isAudio = item!.fileType == 'audio';
    final isVideo = item!.fileType == 'video';

    // loaded state
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // layer 1: visual content
          if (hasThumb && fullThumbPath != null)
            Image.file(
              File(fullThumbPath),
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => const Center(
                child: Icon(
                  Icons.broken_image, color: Colors.grey
                )
              ), // if the file was deleted manually, show broken image
            )
          else if (isAudio)
            Center(
              child: Icon(
                Icons.audiotrack_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.primary
              )
            )
          else
            const Center(
              child: Icon(
                Icons.insert_drive_file_outlined,
                size: 48,
                color: Colors.grey
              )
            ),

          // layer 3: duration badge (video/audio)
          if ((isVideo || isAudio) && (item!.duration ?? 0) > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(item!.duration!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
    } else {
      return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
    }
  }
}