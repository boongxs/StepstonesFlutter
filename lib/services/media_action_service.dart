import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:stepstones_flt/widgets/edit_tags_dialog.dart';
import '../data/app_database.dart';
import 'clipboard_service.dart';
import '../providers/main_provider.dart';
import 'package:provider/provider.dart';

class MediaActionService {
  MediaActionService._();

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
  static Future<void> onEdit(BuildContext context, MediaItem item) async {
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
    final provider = context.read<MainProvider>();
    final success = await provider.updateTags(item, newTags);

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
  static Future<void> onEnlarge(BuildContext context, MediaItem item) async {
    print("TODO: Open Viewer for ${item.originalFileName}");
  }

  // edit command
  static Future<void> onDelete(BuildContext context, MediaItem item) async {
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
    if (shouldDelete != true) return;

    // perform deletion
    final provider = context.read<MainProvider>();
    final success = await provider.deleteItem(item);

    // show feedback
    if (context.mounted) {
      _showSnackBar(
        context,
        success ? "Successfully deleted media item" : "Failed to delete media item",
        isError: !success,
      );
    }
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