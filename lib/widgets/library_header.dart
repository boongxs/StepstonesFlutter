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
        ],
      ),
    );
  }
}