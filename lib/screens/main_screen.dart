import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../locator.dart';
import '../providers/main_provider.dart';
import '../constants.dart';
import '../widgets/action_button.dart';
import '../widgets/sync_status_card.dart';
import '../widgets/media_grid.dart';
import '../widgets/selection_mode_card.dart';
import '../widgets/logs_viewer.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          getIt<MainProvider>()..initialize(), // initialize Main Provider
      child: Builder(
        builder: (context) {
          final vm = context.watch<MainProvider>();

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
                        const Text(
                          "Stepstones",
                          style: TextStyle(fontSize: 90),
                        ),

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
                              context
                                  .read<MainProvider>()
                                  .gallery
                                  .onSearchTextChanged(value);
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- ACTION BUTTONS ROW ---
                        Consumer<MainProvider>(
                          builder: (context, vm, child) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 1. Select Folder
                                ActionButton(
                                  icon: Icons.folder,
                                  tooltip: "Select Media Folder",
                                  onPressed: vm.isShowingLogs
                                      ? null
                                      : vm.session.selectFolder,
                                ),

                                const SizedBox(width: 10),

                                // 2. Upload Files
                                ActionButton(
                                  icon: Icons.upload_file,
                                  tooltip: "Upload Files",
                                  onPressed: vm.isShowingLogs
                                      ? null
                                      : vm.sync.uploadFiles,
                                ),

                                const SizedBox(width: 10),

                                // 3. Refresh
                                ActionButton(
                                  icon: Icons.refresh,
                                  tooltip: "Refresh File Count",
                                  onPressed: vm.isShowingLogs
                                      ? null
                                      : vm.sync.performFullSync,
                                ),

                                const SizedBox(width: 10),

                                // 4. Selection Mode
                                ActionButton(
                                  icon: Icons.checklist_rtl_rounded,
                                  tooltip: "Selection Mode",
                                  onPressed:
                                      (!vm.isShowingLogs &&
                                          vm.gallery.totalItemCount > 0)
                                      ? vm.selection.toggleSelectionMode
                                      : null,
                                ),

                                const SizedBox(width: 10),

                                // 5. Logs View Toggle
                                ActionButton(
                                  icon: vm.isShowingLogs
                                      ? Icons.grid_view_rounded
                                      : Icons.terminal_rounded,
                                  tooltip: vm.isShowingLogs
                                      ? "Show Media Grid"
                                      : "Show Application Logs",
                                  onPressed: () => context
                                      .read<MainProvider>()
                                      .toggleLogsView(),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // --- MAIN CONTENT AREA ---
                        Expanded(
                          child: IndexedStack(
                            index: vm.isShowingLogs ? 1 : 0,
                            children: const [
                              MediaGrid(),
                              LogsViewer(),
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
                  child: Consumer<MainProvider>(
                    builder: (context, vm, _) {
                      return SyncStatusCard(
                        text: vm.status.title,
                        subtext: vm.status.subtitle,
                        isVisible: vm.status.isVisible,
                        isLoading: vm.status.isLoading,
                      );
                    },
                  ),
                ),

                // --- SELECTION MODE CARD ---
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  top: vm.selection.isSelectionMode ? 20 : -200,
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
        },
      ),
    );
  }
}
