import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:stepstones_flt/widgets/edit_tags_dialog.dart';
import '../data/app_database.dart';
import 'clipboard_service.dart';
import '../widgets/media_viewer_dialog.dart';
import '../utils/snackbar_helper.dart';
import 'package:provider/provider.dart';
import '../controllers/gallery_controller.dart';

class MediaActionService {
  MediaActionService._();
  static final GlobalKey<ScaffoldMessengerState> rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // copy command
  static Future<void> onCopy(BuildContext context, MediaItem item) async {
    final fullPath = p.join(item.mediaFolderPath, item.hashedFileName);
    final success = await ClipboardService.copyFile(fullPath);

    // UI feedback
    if (context.mounted) {
      context.showStepstonesSnackBar(
        success ? "Media item copied successfully" : "Failed to copy media item",
        isError: !success,
      );
    }
  }

  // edit command
  static Future<void> onEdit(BuildContext context, MediaItem item) async {
    // grab controller before opening dialog
    final gallery = context.read<GalleryController>();

    // open dialog
    final newTags = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => EditTagsDialog(
        initialTags: item.tags ?? "", // pass existing tags or empty
      ),
    );

    // if user cancelled, stop
    if (newTags == null) return;

    // save changes
    final success = await gallery.updateTags(item, newTags);

    // ui feedback
    if (context.mounted) {
      context.showStepstonesSnackBar(
        success ? "Tags updated successfully" : "Failed to update tags",
        isError: !success,
      );
    }
  }

  // enlarge command
  static Future<void> onEnlarge(BuildContext context, int index) async {
    // grab controller before opening dialog
    final gallery = context.read<GalleryController>();

    // look up the item from provider using the index
    final item = gallery.getItem(index);
    if (item == null) return;

    const allowedTypes = ['image', 'gif', 'video', 'audio'];

    if (!allowedTypes.contains(item.fileType)) {
      context.showStepstonesSnackBar(
        "Viewer for ${item.fileType} not implemented.",
        isError: true,
      );
      
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => MediaViewerDialog(initialIndex: index),
    );
  }

  // delete command
  static Future<bool> onDelete(BuildContext context, MediaItem item, {VoidCallback ? onConfirm}) async {
    final gallery = context.read<GalleryController>();
    final messenger = rootMessengerKey.currentState ?? ScaffoldMessenger.of(context);

    // show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Media Item"),
        content: Text("Are you sure you want to delete this media item?\n"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    // if user clicked cancel or outside the box
    if (shouldDelete != true) return false;

    if (onConfirm != null) {
      onConfirm();
      // wait a moment for video player to completely dispose and release file locks before deletion
      await Future.delayed(const Duration(milliseconds: 250));
    }

    // perform delete
    final success = await gallery.deleteItems([item]);

    // show feedback
    messenger.showStepstonesSnackBar(
      success ? "Successfully deleted media item" : "Failed to delete media item",
      isError: !success,
    );

    return success;
  }
}