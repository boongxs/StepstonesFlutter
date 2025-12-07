import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../locator.dart';
import '../providers/main_provider.dart';
import '../widgets/action_button.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<MainProvider>()..initialize(),
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Align to top
            crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
            children: [
              const SizedBox(height: 10), // gap between app top edge and title

              // row 0 - title
              const Text(
                "Stepstones",
                style: TextStyle(fontSize: 90),
              ),

              const SizedBox(height: 20), // gap between title and search box

              // row 1 - search box
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
                  style: TextStyle(fontSize: 32),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(height: 20), // gap between search box and action buttons

              // row 2 - action buttons
              Consumer<MainProvider>(
                builder: (context, vm, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ActionButton(
                        icon: Icons.folder, 
                        tooltip: "Select Folder",
                        onPressed: vm.selectFolder,
                      ),

                      const SizedBox(width: 10), // gap between 'Folder' and 'Upload' buttons

                      ActionButton(
                        icon: Icons.upload_file, 
                        tooltip: "Upload File",
                        onPressed: vm.uploadFiles,
                      ),

                      const SizedBox(width: 10), // gap between 'Upload' and 'Refresh' buttons

                      ActionButton(
                        icon: Icons.refresh, 
                        tooltip: "Refresh",
                        onPressed: () => print("Refresh"),
                      ),  
                    ],
                  );
                }
              ),

              const SizedBox(height: 20), // gap between action buttons and main content

              // row 3 - main content
              Expanded( // expanded makes the child fill the remaining space
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  color: Colors.black12,
                  child: Center(
                    child: Consumer<MainProvider>(
                      builder: (context, vm, child) {
                        return Text(
                          vm.mediaFolderPath ?? "No media folder selected.\nClick the Folder button to choose one.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 18),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}