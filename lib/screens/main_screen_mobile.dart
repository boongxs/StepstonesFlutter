import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stepstones_flt/utils/snackbar_helper.dart';
import '../widgets/media_grid_mobile.dart';
import '../widgets/primary_search_bar.dart';
import '../controllers/gallery_controller.dart';
import '../controllers/selection_controller.dart';
import '../controllers/session_controller.dart';
import '../providers/status_card_provider.dart';
import '../controllers/export_controller.dart';
import '../locator.dart';

class MainScreenMobile extends StatelessWidget {
  const MainScreenMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final gallery = context.watch<GalleryController>();
    final selection = context.watch<SelectionController>();
    final isSelecting = selection.isSelectionMode;

    return Scaffold(
      appBar: isSelecting
          ? AppBar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => selection.toggleSelectionMode(),
              ),
              title: Text(
                "${selection.selectedCount} Selected",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              actions: [
                // export selected button
                IconButton(
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: () async {
                    final selectionController = context.read<SelectionController>();
                    final itemsToExport = await selectionController.getSelectedItems();

                    if (itemsToExport.isEmpty) return;

                    final exportController = getIt<ExportController>();
                    final statusProvider = context.read<StatusCardProvider>();
                    final session = context.read<SessionController>();

                    if (session.appSupportPath == null) return;

                    final result = await exportController.exportBundleMobile(
                      itemsToExport: itemsToExport,
                      status: statusProvider,
                      tempDirPath: session.appSupportPath!,
                    );

                    if (!context.mounted) return;

                    switch (result.status) {
                      case ExportStatus.success:
                        selectionController.toggleSelectionMode();
                        break;
                      case ExportStatus.cancelled:
                        break;
                      case ExportStatus.error:
                        context.showStepstonesSnackBar(
                          result.errorMessage ?? "An unknown error occurred.",
                          isError: true,
                        );
                        break;
                    }
                  },
                ),

                // delete selcted button
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final count = selection.selectedCount;
                    final confirmed = await _showDeleteConfirmation(context, count);
                    
                    if (confirmed == true) {
                      await selection.deleteSelected(); 
                      if (context.mounted && context.read<SelectionController>().isSelectionMode) {
                        context.read<SelectionController>().toggleSelectionMode();
                      }
                    }
                  },
                ),
              ],
            )
          : AppBar(
              title: const Text(
                "Stepstones",
                style: TextStyle(
                  fontSize: 28.0, 
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
            child: PrimarySearchBar(
              controller: gallery.searchController,
              onChanged: gallery.onSearchTextChanged,
              width: double.infinity,
              height: 48,
              fontSize: 18,
            ),
          ),
          // 2. Currently showing media items text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "${gallery.totalItemCount} items",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // 3. Media grid
          const Expanded(child: MediaGridMobile()), 
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, int count) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Media"),
        content: Text("Are you sure you want to permanently delete $count selected item(s)?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text("Delete"),
          ),
        ],
      )
    );
  }
}