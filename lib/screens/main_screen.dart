import 'package:flutter/material.dart';
import '../widgets/action_button.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ActionButton(
                  icon: Icons.folder, 
                  tooltip: "Select Folder",
                  onPressed: () => print("Select"),
                ),

                const SizedBox(width: 10), // gap between 'Folder' and 'Upload' buttons

                ActionButton(
                  icon: Icons.upload_file, 
                  tooltip: "Upload File",
                  onPressed: () => print("Upload File"),
                ),

                const SizedBox(width: 10), // gap between 'Upload' and 'Refresh' buttons

                ActionButton(
                  icon: Icons.refresh, 
                  tooltip: "Refresh",
                  onPressed: () => print("Refresh"),
                ),  
              ],
            ),

            const SizedBox(height: 20), // gap between action buttons and main content

            // row 3 - main content
            Expanded( // expanded makes the child fill the remaining space
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                color: Colors.black12,
                child: const Center(
                  child: Text(
                    "Main Content goes here",
                    style: TextStyle(color: Colors.grey),
                  )
                )
              )
            )
          ],
        ),
      ),
    );
  }
}