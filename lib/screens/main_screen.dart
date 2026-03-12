import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../widgets/sync_status_card.dart';
import '../widgets/media_grid.dart';
import '../widgets/selection_mode_card.dart';
import '../widgets/logs_viewer.dart';
import '../providers/logs_view_provider.dart';
import '../controllers/selection_controller.dart';
import '../controllers/gallery_controller.dart';
import '../providers/status_card_provider.dart';
import '../widgets/primary_search_bar.dart';
import '../widgets/main_toolbar.dart';
import '../widgets/library_header.dart';

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
                  PrimarySearchBar(
                    onChanged: (value) {
                      context.read<GalleryController>().onSearchTextChanged(value);
                    },
                  ),

                  const SizedBox(height: 20),

                  // --- ACTION BUTTONS ROW ---
                  const MainToolbar(),

                  const SizedBox(height: 20),

                  // --- FOLDER INFO & STORAGE STATUS ROW ---
                  if (!isShowingLogs) const LibraryHeader(),

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
