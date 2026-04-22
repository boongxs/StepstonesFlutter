import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_database.dart';
import '../providers/review_provider.dart';
import 'media_preview_dialog.dart';

class ReviewView extends StatelessWidget {
  const ReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Consumer<ReviewProvider>(
        builder: (context, review, _) {
          if (!review.hasPendingReviews) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 48, color: Colors.white24),
                  SizedBox(height: 12),
                  Text(
                    "No pending reviews",
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final uploaded = review.uploadedItem;
          final matched  = review.matchedItem;
          final similarity = review.currentReview?.similarityPercent;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "POTENTIAL DUPLICATE REVIEW",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${review.pendingCount} remaining",
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 20),

                // --- THUMBNAILS ROW ---
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _FilePanel(
                          label: "Uploaded file",
                          item: uploaded,
                          thumbnailPath: review.uploadedThumbnailPath,
                          fileName: uploaded?.hashedFileName ?? "—",
                          detail: null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _FilePanel(
                          label: "Possible duplicate",
                          item: matched,
                          thumbnailPath: review.matchedThumbnailPath,
                          fileName: matched?.hashedFileName ?? "—",
                          detail: similarity != null
                              ? "${similarity.toStringAsFixed(1)}% similar"
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 20),

                // --- ACTION BUTTONS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: review.keep,
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text(
                          "KEEP",
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff404040),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 140,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: review.discard,
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        label: const Text(
                          "DISCARD",
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilePanel extends StatelessWidget {
  final String label;
  final MediaItem? item;
  final String? thumbnailPath;
  final String fileName;
  final String? detail;

  const _FilePanel({
    required this.label,
    required this.item,
    required this.thumbnailPath,
    required this.fileName,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        MouseRegion(
          cursor: item != null ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            onTap: item != null
                ? () => showDialog(
                      context: context,
                      builder: (_) => MediaPreviewDialog(item: item!),
                    )
                : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a2a2a),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: thumbnailPath != null
                      ? Image.file(
                          File(thumbnailPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Center(
                            child: Icon(Icons.broken_image, color: Colors.white24, size: 40),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.image_outlined, color: Colors.white24, size: 40),
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Tooltip(
          message: fileName,
          child: Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontFamily: "monospace",
            ),
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: 4),
          Text(
            detail!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
