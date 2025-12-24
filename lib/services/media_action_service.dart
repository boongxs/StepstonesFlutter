import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../data/app_database.dart';
import 'clipboard_service.dart';

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
    print("TODO: Open Edit Dialog for ${item.originalFileName}");
  }

  // enlarge command
  static Future<void> onEnlarge(BuildContext context, MediaItem item) async {
    print("TODO: Open Viewer for ${item.originalFileName}");
  }

  // edit command
  static Future<void> onDelete(BuildContext context, MediaItem item) async {
    print("TODO: Show Delete Confirmation for ${item.originalFileName}");
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