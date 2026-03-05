import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/main_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/bundle_service.dart';
import '../services/logger_service.dart';
import '../utils/snackbar_helper.dart';

class SelectionModeCard extends StatelessWidget {
  const SelectionModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MainProvider>();
    final selection = vm.selection;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181a1a),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title
          Text(
            "Selected ${selection.selectedCount} items",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          // select all / unselect all button
          _HoverButton(
            height: 40,
            baseColor: Colors.transparent,
            hoverColor: const Color(0xFF202b29),
            contentColor: const Color(0xFF65c2b2),
            defaultContentColor: Colors.white,
            onTap: selection.toggleSelectAll,
            builder: (isHovered) {
              final color = isHovered ? const Color(0xFF65c2b2) : Colors.white;
              return Row(
                children: [
                  Icon(
                    selection.areAllSelected
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                    color: color,
                    size: 20,
                  ),
                  
                  const SizedBox(width: 12),

                  Text(
                    selection.areAllSelected ? "Unselect all" : "Select all",
                    style: TextStyle(color: color, fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),

          // bundle/extract button
          if (selection.selectedCount > 0) ...[
            const SizedBox(height: 4),

            _HoverButton(
              height: 40,
              baseColor: Colors.transparent,
              hoverColor: const Color(0xFF1a2733),
              contentColor: const Color(0xFF64B5F6),
              defaultContentColor: Colors.white,
              onTap: () async {
                final provider = context.read<MainProvider>();
                final selectedItems = await provider.selection.getSelectedItems();

                if (selectedItems.isEmpty) return;

                provider.status.startJob("Packing media items...");

                // create bundle in temp
                final tempZipPath = await BundleService.createBundle(
                  selectedItems,
                  onProgress: (fileName) {
                    // update card subtitle with current file
                    provider.status.updateProgress(fileName);
                  },
                );

                // error occurred
                if (tempZipPath == null) {
                  provider.status.finishJob("Packing failed", isError: true);
                  if (context.mounted) {
                    context.showStepstonesSnackBar(
                      "Failed to create bundle",
                      isError: true,
                    );
                  }

                  return;
                }

                // packing successful
                provider.status.finishJob("Packing complete");

                // ask user where to save
                String? savePath = await FilePicker.platform.saveFile(
                  dialogTitle: "Save Stepstones Bundle",
                  fileName: "MyCollection.stepstone",
                  type: FileType.custom,
                  allowedExtensions: ["stepstone"],
                );

                if (savePath != null) {
                  // update UI to show saving status
                  provider.status.startJob("Saving to disk...");
                  provider.status.updateProgress(savePath); // update subtitle text to show destination path

                  LogService.i("Attempting to save bundle from: $tempZipPath to: $savePath");
                  try {
                    await compute(_moveFileInBackground, [tempZipPath, savePath]);

                    LogService.i("Bundle saved successfully to: $savePath");
                    provider.status.finishJob("Bundle saved");

                    if (context.mounted) {
                      context.showStepstonesSnackBar(
                        "Bundle saved successfully",
                      );

                      // exit selection mode on success
                      provider.selection.toggleSelectionMode();
                    }
                  } catch (e) {
                    LogService.e("Failed to save bundle file", e);

                    provider.status.finishJob("Save failed", isError: true);

                    if (context.mounted) {
                      context.showStepstonesSnackBar(
                        "Error saving file: $e",
                        isError: true,
                      );
                    }
                  }
                } else {
                  try {
                    // user cancelled save dialog, clean up temp file
                    await compute(_cleanupTempFile, tempZipPath);

                    provider.status.finishJob("Export cancelled");
                  } catch (e) {
                    LogService.w("Failed to delete temp bundle file: $tempZipPath");
                  }
                }
              },
              builder: (isHovered) {
                final color = isHovered ? const Color(0xFF64B5F6) : Colors.white;
                return Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: color, size: 20),

                    const SizedBox(width: 12),

                    Text(
                      "Bundle selected",
                      style: TextStyle(color: color, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              },
            ),
          ],

          // delete selected button
          if (selection.areAllSelected || selection.selectedCount > 0) ...[
            _HoverButton(
              height: 40,
              baseColor: Colors.transparent,
              hoverColor: const Color(0xFF2e1e1e),
              contentColor: const Color(0xFFf87171),
              defaultContentColor: Colors.white,
              onTap: selection.isDeleting ? () {} : selection.deleteSelected,
              builder: (isHovered) {
                // if deleting, show spinner
                if (selection.isDeleting) {
                  return Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: const Color(0xFFf87171),
                      ),
                    ),
                  );
                }

                // otherwise, show standard icon + text
                final color = isHovered ? const Color(0xFFf87171) : Colors.white;
                return Row(
                  children: [
                    Icon(Icons.delete_outline, color: color, size: 20),

                    const SizedBox(width: 12),

                    Text(
                      "Delete selected",
                      style: TextStyle(color: color, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 16),

          // cancel button (bottom right)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _HoverButton(
                isFullWidth: false,
                baseColor: Colors.transparent,
                hoverColor: const Color(0xFF432323),
                contentColor: const Color(0xFFf87171),
                defaultContentColor: const Color(0xFFf87171),
                onTap: selection.toggleSelectionMode,
                builder: (isHovered) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Color(0xFFf87171),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _moveFileInBackground(List<String> paths) async {
  final sourcePath = paths[0];
  final destPath = paths[1];

  final source = File(sourcePath);
  if (!await source.exists()) {
    throw FileSystemException("Source bundle missing", sourcePath);
  }

  // heavy copy
  await source.copy(destPath);
  await source.delete(); // clean up temp file
}

Future<void> _cleanupTempFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {
    // ignore errors during cleanup
  }
}

// helper widget to handle hover logic
class _HoverButton extends StatefulWidget {
  final double? height;
  final bool isFullWidth;
  final Color baseColor;
  final Color hoverColor;
  final Color contentColor;
  final Color defaultContentColor;
  final VoidCallback onTap;
  final Widget Function(bool isHovered) builder;

  const _HoverButton({
    this.height,
    this.isFullWidth = true,
    required this.baseColor,
    required this.hoverColor,
    required this.contentColor,
    required this.defaultContentColor,
    required this.onTap,
    required this.builder,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: widget.height,
          width: widget.isFullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor : widget.baseColor,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: widget.height == null ? null : const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          child: widget.builder(_isHovered),
        ),
      ),
    );
  }
}