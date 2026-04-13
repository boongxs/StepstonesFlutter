import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:stepstones_flt/constants.dart';
import '../controllers/gallery_controller.dart';
import '../controllers/session_controller.dart';
import '../data/app_database.dart';
import '../controllers/selection_controller.dart';
import 'media_viewer_dialog_mobile.dart';

class MediaGridMobile extends StatelessWidget {
  const MediaGridMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final gallery = context.watch<GalleryController>();

    if (gallery.totalItemCount == 0) {
      return const Center(child: Text("No media found."));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130.0,
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
      ),
      itemCount: gallery.totalItemCount,
      itemBuilder: (context, index) {
        final item = gallery.getItem(index);

        // if item is null, the GalleryController is currently fetching this page
        if (item == null) {
          return Container(
            color: Colors.grey[800],
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // pass both the item AND the index to the cell
        return _MobileMediaCell(item: item, index: index);
      },
    );
  }
}

class _MobileMediaCell extends StatelessWidget {
  final MediaItem item;
  final int index;

  const _MobileMediaCell({
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final selectionController = context.watch<SelectionController>();
    
    final isSelected = selectionController.isItemSelected(item.id); 
    final isSelectionMode = selectionController.isSelectionMode;
    
    final thumbFile = _getThumbnailFile(context, item);

    return GestureDetector(
      onLongPress: () {
        // If we aren't in selection mode yet, turn it on
        if (!isSelectionMode) {
          selectionController.toggleSelectionMode();
        }
        
        // If the item isn't already selected, select it
        if (!isSelected) {
          selectionController.toggleItem(item.id);
        }
      },
      onTap: () {
        if (isSelectionMode) {
          // If already selecting, tap just toggles the item
          selectionController.toggleItem(item.id);
        } else {
          // Otherwise, open the viewer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MediaViewerDialogMobile(initialIndex: index),
            ),
          );
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. The Thumbnail Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: thumbFile != null && thumbFile.existsSync()
                ? Image.file(thumbFile, fit: BoxFit.cover)
                : Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.image, color: Colors.white54),
                  ),
          ),

          // 2. The Video Play Icon Overlay
          if (item.fileType == "video")
            const Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 36),
            ),
            
          // 3. The Selection Overlay
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3.0,
                  ),
                ),
                alignment: Alignment.topRight,
                padding: const EdgeInsets.all(4.0),
                child: const Icon(Icons.check_circle, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  File? _getThumbnailFile(BuildContext context, MediaItem item) {
    final session = context.read<SessionController>();
    if (session.appSupportPath == null || item.thumbnailPath == null) return null;
    final fullPath = p.join(session.appSupportPath!, AppConstants.thumbnailDirectory, item.thumbnailPath!);
    return File(fullPath);
  }
}