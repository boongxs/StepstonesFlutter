import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/logs_view_provider.dart';
import '../controllers/gallery_controller.dart';
import '../controllers/session_controller.dart';
import '../controllers/sync_controller.dart';
import '../controllers/selection_controller.dart';
import '../providers/review_provider.dart';

enum ActiveView { mediaGrid, logs, review }

class MainToolbar extends StatelessWidget {
  final ActiveView activeView;
  final ValueChanged<ActiveView> onViewChanged;

  const MainToolbar({
    super.key,
    required this.activeView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<LogsViewProvider, GalleryController, ReviewProvider>(
      builder: (context, logs, gallery, review, child) {
        final sessionAction = context.read<SessionController>();
        final syncAction = context.read<SyncController>();
        final selectionAction = context.read<SelectionController>();
        final isOnMediaGrid = activeView == ActiveView.mediaGrid;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Select Folder
            _ActionButton(
              icon: Icons.folder,
              tooltip: "Select Media Folder",
              onPressed: isOnMediaGrid ? sessionAction.selectFolder : null,
            ),

            const SizedBox(width: 10),

            // 2. Upload Files
            _ActionButton(
              icon: Icons.upload_file,
              tooltip: "Upload Files",
              onPressed: isOnMediaGrid ? syncAction.uploadFiles : null,
            ),

            const SizedBox(width: 10),

            // 3. Refresh
            _ActionButton(
              icon: Icons.refresh,
              tooltip: "Refresh App",
              onPressed: isOnMediaGrid ? syncAction.performFullSync : null,
            ),

            const SizedBox(width: 10),

            // 4. Selection Mode
            _ActionButton(
              icon: Icons.checklist_rtl_rounded,
              tooltip: "Selection Mode",
              onPressed: (isOnMediaGrid && gallery.totalItemCount > 0)
                ? selectionAction.toggleSelectionMode
                : null,
            ),

            const SizedBox(width: 10),

            // 5. Media Grid view button
            _ViewButton(
              icon: Icons.grid_view_rounded,
              tooltip: "Media Grid",
              isActive: isOnMediaGrid,
              onPressed: () => onViewChanged(ActiveView.mediaGrid),
            ),

            const SizedBox(width: 10),

            // 6. Logs view button
            Badge(
              isLabelVisible: logs.hasUnseenLogs,
              backgroundColor: logs.logBadgeColor,
              label: Text(
                logs.unseenLogCount > 9 ? "9+" : logs.unseenLogCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: _ViewButton(
                icon: Icons.terminal_rounded,
                tooltip: "Application Logs",
                isActive: activeView == ActiveView.logs,
                onPressed: () => onViewChanged(ActiveView.logs),
              ),
            ),

            const SizedBox(width: 10),

            // 7. Review view button
            Badge(
              isLabelVisible: review.pendingCount > 0,
              backgroundColor: Colors.orange,
              label: Text(
                review.pendingCount > 9 ? "9+" : review.pendingCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: _ViewButton(
                icon: Icons.find_replace_rounded,
                tooltip: "Review Potential Duplicates",
                isActive: activeView == ActiveView.review,
                onPressed: () => onViewChanged(ActiveView.review),
              ),
            ),
          ],
        );
      },
    );
  }
}

// View toggle button — highlighted when active
class _ViewButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;

  const _ViewButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 50,
      height: 50,
      child: Tooltip(
        message: tooltip,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? color : const Color(0xff404040),
            foregroundColor: const Color(0xfff0f0f0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }
}

// private helper widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Tooltip(
        message: tooltip,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff404040),
            foregroundColor: const Color(0xfff0f0f0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }
}