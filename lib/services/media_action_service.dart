import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:stepstones_flt/widgets/edit_tags_dialog.dart';
import '../data/app_database.dart';
import 'clipboard_service.dart';
import '../providers/main_provider.dart';
import '../widgets/media_viewer_dialog.dart';

class MediaActionService {
  MediaActionService._();
  static final GlobalKey<ScaffoldMessengerState> rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // copy command
  static Future<void> onCopy(BuildContext context, MediaItem item) async {
    final fullPath = p.join(item.mediaFolderPath, item.hashedFileName);
    final success = await ClipboardService.copyFile(fullPath);

    // UI feedback
    if (context.mounted) {
      _showSnackBar(
        context,
        success ? "Media item copied successfully" : "Failed to copy media item",
        isError: !success,
      );
    }
  }

  // edit command
  static Future<void> onEdit(BuildContext context, MainProvider provider, MediaItem item) async {
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
    final success = await provider.gallery.updateTags(item, newTags);

    // ui feedback
    if (context.mounted) {
      _showSnackBar(
        context,
        success ? "Tags updated successfully" : "Failed to update tags",
        isError: !success,
      );
    }
  }

  // enlarge command
  static Future<void> onEnlarge(BuildContext context, MainProvider provider, int index) async {
    // look up the item from provider using the index
    final item = provider.gallery.getItem(index);
    if (item == null) return;

    const allowedTypes = ['image', 'gif', 'video', 'audio'];

    if (!allowedTypes.contains(item.fileType)) {
      _showSnackBar(context, "Viewer for ${item.fileType} not implemented.", isError: true);
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => MediaViewerDialog(initialIndex: index, provider: provider),
    );
  }

  // delete command
  static Future<bool> onDelete(BuildContext context, MainProvider provider, MediaItem item, {VoidCallback ? onConfirm}) async {
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

    // perform deletion
    await provider.gallery.performOptimisticDelete(item.id);
    final success = await provider.gallery.deleteItem(item);

    // show feedback
    _showSnackBarWithMessenger(
      messenger,
      success ? "Successfully deleted media item" : "Failed to delete media item",
      isError: !success,
    );

    return success;
  }

  // helper to show notifications when context might be unmounted
  static void _showSnackBarWithMessenger(ScaffoldMessengerState messenger, String message, {bool isError = false}) {
    messenger.clearSnackBars();

    final iconColor = isError ? Colors.redAccent : Colors.greenAccent;
    final iconData = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF303030),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        width: 350,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // helper to show notifications
  static void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    // clear any existing notifications
    ScaffoldMessenger.of(context).clearSnackBars();

    final iconColor = isError ? Colors.redAccent : Colors.greenAccent;
    final iconData = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF303030),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        width: 350,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}