import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../services/bundle_service.dart';
import '../services/logger_service.dart';
import '../providers/status_card_provider.dart';
import '../data/app_database.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

enum ExportStatus {
  success,
  cancelled,
  error,
}

class ExportResult {
  final ExportStatus status;
  final String? errorMessage;

  ExportResult.success() : status = ExportStatus.success, errorMessage = null;
  ExportResult.cancelled() : status = ExportStatus.cancelled, errorMessage = null;
  ExportResult.error(this.errorMessage) : status = ExportStatus.error;
}

class ExportController {
  /// Handles the flow of exporting media items to a .stepstone bundle
  Future<ExportResult> exportBundle({
    required List<MediaItem> itemsToExport,
    required StatusCardProvider status,
  }) async {
    if (itemsToExport.isEmpty) return ExportResult.error("No items selected.");

    // 1. ask user where to save
    String? savePath = await FilePicker.platform.saveFile(
      dialogTitle: "Save Stepstones Bundle",
      fileName: "MyCollection.stepstone",
      type: FileType.custom,
      allowedExtensions: ["stepstone"],
    );

    // if cancelled, return
    if (savePath == null) return ExportResult.cancelled();

    // 2. start packing to selected destination
    status.startJob("Packing media items...");
    LogService.i("Creating bundle at: $savePath");

    try {
      final successPath = await BundleService.createBundle(
        itemsToExport,
        outputPath: savePath,
        onProgress: (fileName) => status.updateSubtitle(fileName),
      );

      if (successPath == null) {
        await _cleanupFailedBundle(savePath);
        status.finishJob("Packing failed", isError: true);
        return ExportResult.error("Failed to construct the bundle.");
      }

      status.finishJob("Bundle saved successfully");
      return ExportResult.success();
    } catch (e) {
      LogService.e("Exception during bundle creation", e);
      await _cleanupFailedBundle(savePath);
      status.finishJob("Packing failed", isError: true);

      return ExportResult.error("An error occurred while packing: $e");
    }
  }

  /// Handles the flow of exporting media items to a .stepstone bundle on mobile
  /// Builds the file in temp directory and pushes it to Share Sheet
  Future<ExportResult> exportBundleMobile({
    required List<MediaItem> itemsToExport,
    required StatusCardProvider status,
    required String tempDirPath,
  }) async {
    if (itemsToExport.isEmpty) return ExportResult.error("No items selected.");

    // define temp path to build the bundle file
    final savePath = p.join(tempDirPath, "SharedCollection.stepstone");

    // start packing
    status.startJob("Packing media items...");
    LogService.i("Creating temporary bundle at: $savePath");

    try {
      final successPath = await BundleService.createBundle(
        itemsToExport,
        outputPath: savePath,
        onProgress: (fileName) => status.updateSubtitle(fileName),
      );

      if (successPath == null) {
        await _cleanupFailedBundle(savePath);
        status.finishJob("Packing failed", isError: true);
        return ExportResult.error("Failed to construct bundle.");
      }

      status.finishJob("Bundle ready.");

      // immediately trigger Android Share Sheet with finished file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(savePath)],
          text: "Stepstones Media Bundle",
        ),
      );

      return ExportResult.success();
    } catch (e) {
      LogService.e("Exception during bundle creation", e);
      await _cleanupFailedBundle(savePath);
      status.finishJob("Packing failed", isError: true);

      return ExportResult.error("An error occurred while packing: $e");
    }
  }

  Future<void> _cleanupFailedBundle(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        LogService.i("Cleaned up partial bundle file at $path");
      }
    } catch (e) {
      LogService.w("Could not clean up partial bundle file: $e");
    }
  }
}