import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../locator.dart';
import '../providers/main_provider.dart';
import '../widgets/action_button.dart';
import '../widgets/upload_status_card.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Wrap the screen in the MainProvider so the UI can listen to state changes
    return ChangeNotifierProvider(
      create: (_) => getIt<MainProvider>()..initialize(),
      child: Scaffold(
        // 2. Use a Stack to allow the UploadStatusCard to float above the main content
        body: Stack(
          children: [
            // --- LAYER 1: MAIN CONTENT ---
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top Gap
                    const SizedBox(height: 10),

                    // Title
                    const Text(
                      "Stepstones",
                      style: TextStyle(fontSize: 90, fontWeight: FontWeight.bold),
                    ),

                    // Gap
                    const SizedBox(height: 20),

                    // --- SEARCH BOX (Static UI for now) ---
                    Container(
                      width: 600,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF303030),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 7),
                      child: const TextField(
                        style: TextStyle(fontSize: 32, height: 1.0),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isCollapsed: true,
                          hintText: "Search...",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                    // Gap
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
                              onPressed: vm.selectFolder,
                            ),
                            const SizedBox(width: 10),

                            // 2. Upload Files
                            ActionButton(
                              icon: Icons.upload_file,
                              tooltip: "Upload Files",
                              onPressed: vm.uploadFiles,
                            ),
                            const SizedBox(width: 10),

                            // 3. Refresh
                            ActionButton(
                              icon: Icons.refresh,
                              tooltip: "Refresh File Count",
                              onPressed: vm.refreshFileCount,
                            ),
                          ],
                        );
                      },
                    ),

                    // Gap
                    const SizedBox(height: 20),

                    // --- MAIN CONTENT AREA (Displays Path & Count) ---
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          // Consumer listens to MainProvider to update Path and Count
                          child: Consumer<MainProvider>(
                            builder: (context, vm, child) {
                              if (vm.mediaFolderPath == null) {
                                return const Text(
                                  "No media folder selected.\nClick the Folder icon to begin.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 18),
                                );
                              }

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    vm.mediaFolderPath!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 18),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Total items: ${vm.totalItemCount}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

            // --- LAYER 2: FLOATING UPLOAD STATUS CARD ---
            const Positioned(
              right: 20,
              bottom: 20,
              // This widget handles its own visibility via its internal Consumer
              child: UploadStatusCard(),
            ),
          ],
        ),
      ),
    );
  }
}