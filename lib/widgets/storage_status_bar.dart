import 'package:flutter/material.dart';

class StorageStatusBar extends StatelessWidget {
  final double freeSpaceMB;

  const StorageStatusBar({
    super.key,
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
    final color = isLowSpace ? Colors.redAccent : Colors.grey[400];
    final icon = isLowSpace ? Icons.warning_amber_rounded : Icons.sd_storage_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // Aligns the badge to the right
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color!.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
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
          ),
        ],
      ),
    );
  }
}