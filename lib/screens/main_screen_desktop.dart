import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../widgets/job_status_card.dart';
import '../widgets/media_grid.dart';
import '../widgets/selection_mode_card.dart';
import '../widgets/logs_viewer.dart';
import '../widgets/review_view.dart';
import '../providers/logs_view_provider.dart';
import '../controllers/selection_controller.dart';
import '../controllers/gallery_controller.dart';
import '../providers/status_card_provider.dart';
import '../widgets/primary_search_bar.dart';
import '../widgets/main_toolbar.dart';
import '../widgets/library_header.dart';
import '../widgets/settings_dialog.dart';

class MainScreenDesktop extends StatefulWidget {
  const MainScreenDesktop({super.key});

  @override
  State<MainScreenDesktop> createState() => _MainScreenDesktopState();
}

class _MainScreenDesktopState extends State<MainScreenDesktop> {
  ActiveView _activeView = ActiveView.mediaGrid;

  void _onViewChanged(ActiveView view) {
    final logsProvider = context.read<LogsViewProvider>();
    if (_activeView == ActiveView.logs && view != ActiveView.logs) {
      logsProvider.setLogsVisible(false);
    } else if (view == ActiveView.logs && _activeView != ActiveView.logs) {
      logsProvider.setLogsVisible(true);
    }
    setState(() => _activeView = view);
  }

  @override
  Widget build(BuildContext context) {
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
                  PrimarySearchBar(
                    controller: context.read<GalleryController>().searchController,
                    onChanged: (value) {
                      context.read<GalleryController>().onSearchTextChanged(value);
                    },
                  ),

                  const SizedBox(height: 20),

                  // --- ACTION BUTTONS ROW ---
                  MainToolbar(
                    activeView: _activeView,
                    onViewChanged: _onViewChanged,
                  ),

                  const SizedBox(height: 20),

                  // --- FOLDER INFO & STORAGE STATUS ROW ---
                  if (_activeView == ActiveView.mediaGrid) const LibraryHeader(),

                  // --- MAIN CONTENT AREA ---
                  Expanded(
                    child: IndexedStack(
                      index: _activeView.index,
                      children: [
                        MediaGrid(),
                        LogsViewer(
                          lastSeenLogCount: context
                              .read<LogsViewProvider>()
                              .lastSeenLogCount,
                        ),
                        const ReviewView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- SYNC / JOB STATUS CARDS ---
          Positioned(
            bottom: 20,
            right: 20,
            child: Consumer<StatusCardProvider>(
              builder: (context, status, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: status.jobs.map((job) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SyncStatusCard(
                      text: job.title,
                      subtext: job.subtitle.isNotEmpty ? job.subtitle : null,
                      isVisible: job.isVisible,
                      isLoading: job.isLoading,
                    ),
                  )).toList(),
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
            right: 15,
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

          // --- SETTINGS BUTTON ---
          Positioned(
            top: 15,
            left: 15,
            child: SizedBox(
              width: 50,
              height: 50,
              child: Tooltip(
                message: "Settings",
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => const SettingsDialog(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff404040),
                    foregroundColor: const Color(0xfff0f0f0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.settings, size: 32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
