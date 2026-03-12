import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../controllers/session_controller.dart';
import '../controllers/gallery_controller.dart';

class LibraryHeader extends StatelessWidget {
  const LibraryHeader({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final gallery = context.watch<GalleryController>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 29),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xff222222),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Folder name & item count
          Expanded(
            child: Row(
              children: [
                // Folder icon
                const Icon(Icons.folder_open_rounded, size: 18),

                const SizedBox(width: 8),

                // Folder name
                Flexible(
                  child: Text(
                    session.mediaFolderPath != null
                      ? p.basename(session.mediaFolderPath!)
                      : "No Folder Selected",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Divider dot
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "•",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),

                // Item count
                Text(
                  "Currently showing ${gallery.totalItemCount} media items",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Disk storage status indicator
          _StorageStatusBar(
            freeSpaceMB: session.freeSpaceMB,
          ),
        ],
      ),
    );
  }
}

// private helper widget
class _StorageStatusBar extends StatelessWidget {
  final double freeSpaceMB;

  const _StorageStatusBar({
    required this.freeSpaceMB,
  });

  String _formatSize(double sizeMB) {
    if (sizeMB > 1024) {
      return "${(sizeMB / 1024).toStringAsFixed(1)} GB";
    }

    return "${sizeMB.toStringAsFixed(0)} MB";
  }

  @override
  Widget build(BuildContext context) {
    if (freeSpaceMB <= 0) return const SizedBox.shrink();

    // change color to warn user if low on space
    final isLowSpace = freeSpaceMB < 5120;
    final color = isLowSpace ? Colors.redAccent : Colors.grey[200];
    final icon = isLowSpace ? Icons.warning_amber_rounded : Icons.sd_storage_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          
          const SizedBox(width: 8),

          Text(
            "${_formatSize(freeSpaceMB)} Free",
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}