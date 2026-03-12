import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/logs_view_provider.dart';
import '../controllers/gallery_controller.dart';
import '../controllers/session_controller.dart';
import '../controllers/sync_controller.dart';
import '../controllers/selection_controller.dart';

class MainToolbar extends StatelessWidget {
  const MainToolbar({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<LogsViewProvider, GalleryController>(
      builder: (context, logs, gallery, child) {
        final sessionAction = context.read<SessionController>();
        final syncAction = context.read<SyncController>();
        final selectionAction = context.read<SelectionController>();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Select Folder
            _ActionButton(
              icon: Icons.folder,
              tooltip: "Select Media Folder",
              onPressed: logs.isShowingLogs 
                ? null 
                : sessionAction.selectFolder,
            ),

            const SizedBox(width: 10),

            // 2. Upload Files
            _ActionButton(
              icon: Icons.upload_file,
              tooltip: "Upload Files",
              onPressed: logs.isShowingLogs
                ? null
                : syncAction.uploadFiles
            ),

            const SizedBox(width: 10),

            // 3. Refresh
            _ActionButton(
              icon: Icons.refresh,
              tooltip: "Refresh App",
              onPressed: logs.isShowingLogs
                ? null
                : syncAction.performFullSync,
            ),

            const SizedBox(width: 10),

            // 4. Selection Mode
            _ActionButton(
              icon: Icons.checklist_rtl_rounded,
              tooltip: "Selection Mode",
              onPressed: (!logs.isShowingLogs && gallery.totalItemCount > 0)
                ? selectionAction.toggleSelectionMode
                : null,
            ),

            const SizedBox(width: 10),

            // 5. Logs View -- Media Grid Toggle
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
              child: _ActionButton(
                icon: logs.isShowingLogs 
                  ? Icons.grid_view_rounded 
                  : Icons.terminal_rounded,
                tooltip: logs.isShowingLogs
                  ? "Show Media Grid"
                  : "Show Application Logs",
                onPressed: () => context.read<LogsViewProvider>().toggleLogsView(),
              ),
            ),
          ],
        );
      },
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