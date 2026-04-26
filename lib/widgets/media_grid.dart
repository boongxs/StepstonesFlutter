import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:stepstones_flt/constants.dart';
import '../data/app_database.dart';
import '../utils/min_extra_delegate.dart';
import '../services/media_action_service.dart';
import '../controllers/session_controller.dart';
import '../controllers/gallery_controller.dart';
import '../controllers/selection_controller.dart';
import '../providers/status_card_provider.dart';

class MediaGrid extends StatelessWidget {
  const MediaGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final status = context.watch<StatusCardProvider>();
    final totalItemCount = context.select<GalleryController, int>((g) => g.totalItemCount); // only rebuild grid if total item count changes
    final gallery = context.read<GalleryController>(); // to pass to scrollController but doesn't cause rebuild

    // empty state
    if (session.mediaFolderPath == null) {
      return const Center(
        child: Text(
          "Select a folder to begin"
        )
      );
    }

    if (totalItemCount == 0 && !status.isLoading) {
      return const Center(
        child: Text(
          "No media items found"
        )
      );
    }

    final thumbBaseDir = p.join(session.appSupportPath, AppConstants.thumbnailDirectory);

    return RawScrollbar(
      controller: gallery.scrollController,
      thumbVisibility: true,
      trackVisibility: true,
      trackColor: const Color(0xFF3a3a3a),
      interactive: true,
      minThumbLength: 70,
      thickness: 20,
      radius: const Radius.circular(5),
      thumbColor: const Color(0xFF6f6f6f),
      padding: const EdgeInsets.only(right: 5.0),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: GridView.builder(
          controller: gallery.scrollController,
          padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
          itemCount: totalItemCount, // item count ensures scrollbar resizes properly
        
          // responsive layout
          gridDelegate: const SliverGridDelegateWithMinCrossAxisExtent(
            minCrossAxisExtent: 270, // cells will be around 500px wide
            mainAxisExtent: 250, // cells will be exactly 250px tall
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
        
          itemBuilder: (context, index) {
            return Selector<GalleryController, MediaItem?>(
              selector: (context, galleryController) => galleryController.getItem(index),
              builder: (context, item, child) {
                return _MediaCell(
                  key: item != null ? ValueKey(item.id) : ValueKey("loading_$index"),
                  item: item,
                  index: index,
                  thumbBaseDir: thumbBaseDir
                );
              }
            );
          },
        ),
      ),
    );
  }
}


class _MediaCell extends StatefulWidget {
  final MediaItem? item;
  final int index;
  final String thumbBaseDir;

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

    // only rebuild this cell if its selection state changes
    final isSelectionMode = context.select<SelectionController, bool>((s) => s.isSelectionMode);
    final isSelected = context.select<SelectionController, bool>((s) => s.isItemSelected(widget.item!.id));

    // logic extraction
    final hasThumb = widget.item!.thumbnailPath != null;
    final fullThumbPath = hasThumb ? p.join(widget.thumbBaseDir, widget.item!.thumbnailPath!) : null;
    final isAudio = widget.item!.fileType == "audio";
    final isVideo = widget.item!.fileType == "video";

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
          
          if (widget.item!.fileType == "gif")
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "GIF",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 0.5,
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
          onTap: () => context.read<SelectionController>().toggleItem(widget.item!.id),
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
                    painter: _SelectionBorderPainter(
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
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  )
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
                          _QuadrantButton( // copy
                            icon: Icons.content_copy_rounded,
                            hoverColor: const Color(0xFFFFC600),
                            onTap: () => MediaActionService.onCopy(context, widget.item!),
                          ),
                          _QuadrantButton( // edit
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
                          _QuadrantButton( // enlarge
                            icon: Icons.fullscreen_rounded,
                            hoverColor: const Color(0xFF4FAFFF),
                            onTap: () => MediaActionService.onEnlarge(context, widget.index),
                          ),
                          _QuadrantButton(
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

// private CustomPainter for selection overlay of media cell
class _SelectionBorderPainter extends CustomPainter {
  final Color color;
  final double cutoutRadius;
  final double borderRadius;

  _SelectionBorderPainter({
    required this.color,
    this.cutoutRadius = 60.0,
    this.borderRadius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(cutoutRadius, 0)
      ..lineTo(w - borderRadius, 0)
      ..arcToPoint(Offset(w, borderRadius), radius: Radius.circular(borderRadius))
      ..lineTo(w, h - borderRadius)
      ..arcToPoint(Offset(w - borderRadius, h), radius: Radius.circular(borderRadius))
      ..lineTo(borderRadius, h)
      ..arcToPoint(Offset(0, h - borderRadius), radius: Radius.circular(borderRadius))
      ..lineTo(0, cutoutRadius)
      ..arcToPoint(
        Offset(cutoutRadius, 0),
        radius: Radius.circular(cutoutRadius),
        clockwise: false,
    );

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SelectionBorderPainter oldDelegate) {
    return color != oldDelegate.color || cutoutRadius != oldDelegate.cutoutRadius || borderRadius != oldDelegate.borderRadius;
  }
}

// private helper widget for quadrant actions of a single media item
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