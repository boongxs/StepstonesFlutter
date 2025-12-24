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
              thumbBaseDir: thumbBaseDir
            );
          },
        );
      },
    );
  }
}

class _MediaCell extends StatefulWidget {
  final MediaItem? item;
  final int index;
  final String? thumbBaseDir;

  const _MediaCell({
    super.key,
    required this.item, 
    required this.index,
    required this.thumbBaseDir
  });

  @override
  State<_MediaCell> createState() => _MediaCellState();
}

class _MediaCellState extends State<_MediaCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // 1. Loading State (Virtualization Placeholder)
    if (widget.item == null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    // logic extraction
    final hasThumb = widget.item!.thumbnailPath != null && widget.thumbBaseDir != null;
    final fullThumbPath = hasThumb ? p.join(widget.thumbBaseDir!, widget.item!.thumbnailPath!) : null;
    final isAudio = widget.item!.fileType == 'audio';
    final isVideo = widget.item!.fileType == 'video';

    // loaded state
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
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
                key: ValueKey(File(fullThumbPath).lastModifiedSync().millisecondsSinceEpoch),
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey)
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

            // layer 2: duration badge (video/audio)
            if ((isVideo || isAudio) && (widget.item!.duration ?? 0) > 0)
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
                    _formatDuration(widget.item!.duration!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14
                    ),
                  ),
                ),
              ),

            // on hover layers
            if (_isHovered) ...[
              // layer 3 dark overlay (on hover)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                ),
              ),

              // layer 4: quadrant command buttons
              Positioned.fill(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _QuadrantButton( // copy
                            icon: Icons.content_copy_rounded,
                            hoverColor: Color(0xFFFFC600),
                            onTap: () => print("Copy"),
                          ),
                          _QuadrantButton( // edit
                            icon: Icons.edit_rounded,
                            hoverColor: Color(0xFF25BB00),
                            onTap: () => print("Edit"),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _QuadrantButton(
                            icon: Icons.fullscreen_rounded,
                            hoverColor: Color(0xFF4FAFFF),
                            onTap: () => print("Enlarge"),
                          ),
                          _QuadrantButton(
                            icon: Icons.delete_outline_rounded,
                            hoverColor: Color(0xFFFF5454),
                            onTap: () => print("Delete"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
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

class _QuadrantButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color hoverColor;

  const _QuadrantButton({
    required this.icon,
    required this.onTap,
    required this.hoverColor,
  });

  @override
  State<_QuadrantButton> createState() => _QuadrantButtonState();
}

class _QuadrantButtonState extends State<_QuadrantButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // MouseRegion tracks hover for this specific quadrant
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,

        // GestureDetector handles clicks
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Icon(
              widget.icon,
              size: 48,
              color: _isHovered ? widget.hoverColor : Colors.white,
            )
          )
        )
      )
    );
  }
}