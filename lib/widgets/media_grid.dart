import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../providers/main_provider.dart';
import '../data/app_database.dart';
import '../utils/min_extra_delegate.dart';
import 'quadrant_button.dart';
import '../services/media_action_service.dart';
import 'selection_border_painter.dart';

class MediaGrid extends StatelessWidget {
  const MediaGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MainProvider>(
      builder: (context, vm, _) {
        // empty state
        if (vm.session.mediaFolderPath == null) {
          return const Center(child: Text("Select a folder to begin"));
        }

        // show "no items" only if we are not currently syncing to avoid flicker on startup
        if (vm.gallery.totalItemCount == 0 && !vm.sync.isSyncingWorkInProgress) {
          return const Center(child: Text("No media items found"));
        }

        // pass the cached base path to cells
        final thumbBaseDir = vm.session.appSupportPath != null
          ? p.join(vm.session.appSupportPath!, 'thumbnails')
          : null;

        return GridView.builder(
          controller: vm.gallery.scrollController,
          padding: const EdgeInsets.all(10),
          itemCount: vm.gallery.totalItemCount, // virtualization: exact count ensures scrollbar is correct

          // responsive layout
          gridDelegate: const SliverGridDelegateWithMinCrossAxisExtent(
            minCrossAxisExtent: 270, // cells will be around 500px wide
            mainAxisExtent: 250, // cells will be exactly 250px tall
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),

          itemBuilder: (context, index) {
            // ask provider for data, if null trigger fetch
            final MediaItem? item = vm.gallery.getItem(index);
            return _MediaCell(
              key: item != null ? ValueKey(item.id) : ValueKey("loading_$index"),
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    // access provider for selection mode
    final vm = context.watch<MainProvider>();
    final isSelectionMode = vm.selection.isSelectionMode;
    final isSelected = vm.selection.isItemSelected(widget.item!.id);

    // logic extraction
    final hasThumb = widget.item!.thumbnailPath != null && widget.thumbBaseDir != null;
    final fullThumbPath = hasThumb ? p.join(widget.thumbBaseDir!, widget.item!.thumbnailPath!) : null;
    final isAudio = widget.item!.fileType == 'audio';
    final isVideo = widget.item!.fileType == 'video';

    Widget baseContent = Container(
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
              key: ValueKey(_safelyGetMTime(File(fullThumbPath))),
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => const Center(
                child: Icon(Icons.broken_image, color: Colors.grey)
              ),
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
          
          // layer 2 duration badge (video/audio file type)
          if ((isVideo || isAudio) && (widget.item!.duration ?? 0) > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
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
        ],
      ),
    );

    if (isSelectionMode) {
      // MODE: Selection
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => vm.selection.toggleItem(widget.item!.id),
          child: Stack(
            children: [
              // thumbnail and duration badge
              Positioned.fill(child: baseContent),

              // quarter circle background behind checkbox
              Positioned(
                top: 0,
                left: 0,
                width: 60,
                height: 60,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF181a1a),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(60),
                      topLeft: Radius.circular(8),
                    ),
                  ),
                ),
              ),

              // selection overlay
              // only visible if item is selected
              if (isSelected)
                Positioned.fill(
                  child: CustomPaint(
                    painter: SelectionBorderPainter(
                      color: const Color(0xFF65c2b2),
                      cutoutRadius: 60.0,
                      borderRadius: 8.0,
                    ),
                  ),
                ),
              
              // checkbox icon
              Positioned(
                top: 6,
                left: 6,
                child: Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected ? const Color(0xFF65c2b2) : Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // MODE: Default
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Stack(
          children: [
            // thumbnail and duration badge
            Positioned.fill(child: baseContent),

            // hover effects
            // dark overlay
            if (_isHovered)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            
            // quadrant command buttons
            if (_isHovered)
              Positioned.fill(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          QuadrantButton( // copy
                            icon: Icons.content_copy_rounded,
                            hoverColor: const Color(0xFFFFC600),
                            onTap: () => MediaActionService.onCopy(context, widget.item!),
                          ),
                          QuadrantButton( // edit
                            icon: Icons.edit_rounded,
                            hoverColor: const Color(0xFF25BB00),
                            onTap: () => MediaActionService.onEdit(context, widget.item!),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          QuadrantButton( // enlarge
                            icon: Icons.fullscreen_rounded,
                            hoverColor: const Color(0xFF4FAFFF),
                            onTap: () => MediaActionService.onEnlarge(context, widget.item!),
                          ),
                          QuadrantButton(
                            icon: Icons.delete_outline_rounded,
                            hoverColor: const Color(0xFFFF5454),
                            onTap: () => MediaActionService.onDelete(context, widget.item!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
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

  int _safelyGetMTime(File file) {
    try {
      if (!file.existsSync()) return 0;
      return file.lastModifiedSync().millisecondsSinceEpoch;
    } catch (e) {
      return 0;
    }
  }
}