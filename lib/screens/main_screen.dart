import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stepstones_flt/controllers/session_controller.dart';
import '../constants.dart';
import '../widgets/action_button.dart';
import '../widgets/sync_status_card.dart';
import '../widgets/media_grid.dart';
import '../widgets/selection_mode_card.dart';
import '../widgets/logs_viewer.dart';
import '../widgets/storage_status_bar.dart';
import 'package:path/path.dart' as p;
import '../providers/logs_view_provider.dart';
import '../controllers/selection_controller.dart';
import '../controllers/gallery_controller.dart';
import '../controllers/sync_controller.dart';
import '../providers/status_card_provider.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isShowingLogs = context.watch<LogsViewProvider>().isShowingLogs;
    final isSelectionMode = context
        .watch<SelectionController>()
        .isSelectionMode;

    return Scaffold(
      body: Stack(
        children: [
          // --- MAIN CONTENT ---
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // Title
                  const Text("Stepstones", style: TextStyle(fontSize: 90)),

                  const SizedBox(height: 20),

                  // --- SEARCH BOX---
                  Container(
                    width: 600,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF303030),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 7),
                    child: TextField(
                      style: TextStyle(fontSize: 32, height: 1.0),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isCollapsed: true,
                        hintText: "Search...",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onChanged: (value) {
                        context.read<GalleryController>().onSearchTextChanged(
                          value,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- ACTION BUTTONS ROW ---
                  Consumer2<LogsViewProvider, GalleryController>(
                    builder: (context, logs, gallery, child) {
                      final sessionAction = context.read<SessionController>();
                      final syncAction = context.read<SyncController>();
                      final selectionAction = context
                          .read<SelectionController>();

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Select Folder
                          ActionButton(
                            icon: Icons.folder,
                            tooltip: "Select Media Folder",
                            onPressed: logs.isShowingLogs
                                ? null
                                : sessionAction.selectFolder,
                          ),

                          const SizedBox(width: 10),

                          // 2. Upload Files
                          ActionButton(
                            icon: Icons.upload_file,
                            tooltip: "Upload Files",
                            onPressed: logs.isShowingLogs
                                ? null
                                : syncAction.uploadFiles,
                          ),

                          const SizedBox(width: 10),

                          // 3. Refresh
                          ActionButton(
                            icon: Icons.refresh,
                            tooltip: "Refresh File Count",
                            onPressed: logs.isShowingLogs
                                ? null
                                : syncAction.performFullSync,
                          ),

                          const SizedBox(width: 10),

                          // 4. Selection Mode
                          ActionButton(
                            icon: Icons.checklist_rtl_rounded,
                            tooltip: "Selection Mode",
                            onPressed:
                                (!logs.isShowingLogs &&
                                    gallery.totalItemCount > 0)
                                ? selectionAction.toggleSelectionMode
                                : null,
                          ),

                          const SizedBox(width: 10),

                          // 5. Logs View Toggle
                          Badge(
                            isLabelVisible: logs.hasUnseenLogs,
                            backgroundColor: logs.logBadgeColor,
                            label: Text(
                              logs.unseenLogCount > 9
                                  ? "9+"
                                  : logs.unseenLogCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: ActionButton(
                              icon: logs.isShowingLogs
                                  ? Icons.grid_view_rounded
                                  : Icons.terminal_rounded,
                              tooltip: logs.isShowingLogs
                                  ? "Show Media Grid"
                                  : "Show Application Logs",
                              onPressed: () => context
                                  .read<LogsViewProvider>()
                                  .toggleLogsView(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // --- FOLDER INFO & STORAGE STATUS ROW ---
                  // only show the bar if looking at media grid view
                  if (!isShowingLogs)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Folder name & Item count
                          Expanded(
                            child: Row(
                              children: [
                                // Folder icon
                                Icon(Icons.folder_open_rounded, size: 18),

                                const SizedBox(width: 8),

                                // Folder name
                                Flexible(
                                  child: Text(
                                    context
                                                .watch<SessionController>()
                                                .mediaFolderPath !=
                                            null
                                        ? p.basename(
                                            context
                                                .watch<SessionController>()
                                                .mediaFolderPath!,
                                          )
                                        : "No Folder Selected",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // Divider Dot
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    "•",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),

                                // Item count
                                Text(
                                  "Currently showing ${context.watch<GalleryController>().totalItemCount} media items",
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
                          StorageStatusBar(
                            freeSpaceMB: context
                                .watch<SessionController>()
                                .freeSpaceMB,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // --- MAIN CONTENT AREA ---
                  Expanded(
                    child: IndexedStack(
                      index: isShowingLogs ? 1 : 0,
                      children: [
                        MediaGrid(),
                        LogsViewer(
                          lastSeenLogCount: context
                              .read<LogsViewProvider>()
                              .lastSeenLogCount,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- SYNC / JOB STATUS CARD ---
          Positioned(
            bottom: 20,
            right: 20,
            child: Consumer<StatusCardProvider>(
              builder: (context, status, _) {
                return SyncStatusCard(
                  text: status.title,
                  subtext: status.subtitle,
                  isVisible: status.isVisible,
                  isLoading: status.isLoading,
                );
              },
            ),
          ),

          // --- SELECTION MODE CARD ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            top: isSelectionMode ? 20 : -200,
            right: 20,
            child: const SelectionModeCard(),
          ),

          // --- VERSION NUMBER ---
          Positioned(
            top: 10,
            left: 15,
            child: Text(
              "v${AppConstants.appVersion}",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
                fontFamily: "monospace",
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
