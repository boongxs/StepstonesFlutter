import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' as drift;
import '../locator.dart';
import '../data/app_database.dart';
import '../services/logger_service.dart';
import '../services/file_service.dart';
import '../services/file_picker_service.dart';
import '../utils/media_helper.dart';
import '../utils/metadata_helper.dart';
import '../utils/thumbnail_helper.dart';
import '../providers/upload_status_provider.dart';
import '../providers/status_card_provider.dart';
import 'session_controller.dart';
import 'gallery_controller.dart';
import '../services/bundle_import_service.dart';
import 'package:flutter/foundation.dart';

class SyncController extends ChangeNotifier {
  final AppDatabase _database;
  final SessionController _session;
  final GalleryController _gallery;
  final StatusCardProvider _jobStatus;

  final FileService _fileService = getIt<FileService>();
  final FilePickerService _filePickerService = getIt<FilePickerService>();

  final List<String> _uploadQueue = [];
  bool _isUploading = false;

  SyncController(
    this._database,
    this._session,
    this._gallery,
    this._jobStatus,
  );

  // --- actions ---
  Future<void> uploadFiles() async {
    if (_session.mediaFolderPath == null) {
      LogService.w("No media folder selected.");
      return;
    }

    final files = await _filePickerService.pickMediaFiles();
    if (files == null || files.isEmpty) return;

    // separate stepstones bundles from regular media files
    final bundleFiles = files.where((f) => p.extension(f).toLowerCase() == ".stepstone").toList();
    final mediaFiles = files.where((f) => p.extension(f).toLowerCase() != ".stepstone").toList();

    // process bundles first, sequentially
    for (final bundlePath in bundleFiles) {
      await _handleBundleImport(bundlePath);
    }

    // if there are no regular media files, end
    if (mediaFiles.isEmpty) return;

    // process regular media files
    _uploadQueue.addAll(files);

    final uploadProgress = getIt<UploadStatusProvider>();
    uploadProgress.startUpload(files.length);
    notifyListeners();

    if (!_isUploading) {
      _processUploadQueue();
    }
  }

  Future<void> performFullSync() async {
    // get media folder path from Session Controller
    final folderPath = _session.mediaFolderPath;
    if (folderPath == null) return;

    // set up sync status card
    _jobStatus.startJob("Synchronizing media folder");

    // show sync status card
    notifyListeners();

    await _gallery.fullRefresh(resetScroll: false);

    bool hasError = false;
    try {
      // get DB files for current media folder
      final dbFiles = await _database.getFilenamesInFolder(folderPath);

      // get disk files from current media folder
      final dir = Directory(folderPath);
      if (!await dir.exists()) return;

      final diskFilesList = dir.listSync()
        .whereType<File>()
        .where((f) => !p.basename(f.path).endsWith(".tmp"))
        .toList();

      await _handleGhosts(folderPath, dbFiles, diskFilesList);
      await _handleOrphans(dbFiles.toSet(), diskFilesList);
      await _validateThumbnails(folderPath);
    } catch (e) {
      LogService.e("Sync failed.", e);
      hasError = true;
    } finally {
      if (hasError) {
        _jobStatus.finishJob("Synchronization failed", isError: true);
      } else {
        _jobStatus.finishJob("Media folder synchronized");
      }
      notifyListeners();
    }
  }

  Future<void> _processUploadQueue({bool silent = false}) async {
    _isUploading = true;
    final uploadProgress = getIt<UploadStatusProvider>();
    final folderPath = _session.mediaFolderPath!;

    while (_uploadQueue.isNotEmpty) {
      final sourcePath = _uploadQueue.removeAt(0);
      final fileName = p.basename(sourcePath);
      final isImport = p.isWithin(folderPath, sourcePath);

      // update current filename for the sync card
      if (silent) {
        _jobStatus.updateProgress(fileName);
      } else {
        uploadProgress.updateCurrentFile(fileName, 0);
      }

      // copy / import
      CopyResponse response;
      if (isImport) {
        response = await _fileService.importFileWithProgress(
          sourcePath,
          (p) => !silent ? uploadProgress.updateProgress(p) : null
        );
      } else {
        response = await _fileService.copyFileWithProgress(
          sourcePath, 
          folderPath, 
          (p) => !silent ? uploadProgress.updateProgress(p) : null
        );
      }

      // DB insert / thumbnail generation
      if (response.status == CopyResult.success) {
        try {
          final finalPath = p.join(folderPath, response.finalFileName!);

          final type = await MediaHelper.inferFileType(finalPath);
          final metadata = await MetadataHelper.extractMetadata(finalPath, type);

          // thumbnail generation on background thread
          final thumb = await ThumbnailHelper.generateThumbnail(
            sourcePath: finalPath, 
            fileType: type, 
            fileHash: response.hash!, 
            durationMs: metadata.durationMs,
          );

          final entry = MediaItemsCompanion(
            fileHash: drift.Value(response.hash!),
            hashedFileName: drift.Value(response.finalFileName!),
            mediaFolderPath: drift.Value(folderPath),
            originalFileName: drift.Value(fileName),
            fileType: drift.Value(type),
            width: drift.Value(metadata.width),
            height: drift.Value(metadata.height),
            duration: drift.Value(metadata.durationMs),
            thumbnailPath: drift.Value(thumb),
          );

          await _database.insertMediaItem(entry);
          if (!silent) uploadProgress.completeFile();
        } catch (e) {
          final isDuplicate = e.toString().contains("2067") || e.toString().contains("UNIQUE constraint failed");
          if (isDuplicate) {
            if (!silent) uploadProgress.markDuplicate();
          } else {
            if (!silent) uploadProgress.markFailed();
          }
        }
      } else if (response.status == CopyResult.duplicate) {
        if (!silent) uploadProgress.markDuplicate();
      } else {
        if (!silent) uploadProgress.markFailed();
      }
    }

    if (silent) {
      _jobStatus.updateProgress("");
    }

    // queue empty -> refresh
    await _gallery.fullRefresh(resetScroll: false);

    if (!silent) uploadProgress.finishUpload();
    _isUploading = false;
    LogService.i("Queue empty. Sync complete.");
    notifyListeners();
  }

  // helper: identify and remove ghosts
  Future<void> _handleGhosts(
    String folderPath,
    List<String> dbFiles,
    List<File> diskFiles,
  ) async {
    final diskFileSet = diskFiles.map((f) => p.basename(f.path)).toSet();
    final ghosts = <String>[];

    for (var dbName in dbFiles) {
      if (!diskFileSet.contains(dbName)) {
        ghosts.add(dbName);
      }
    }

    if (ghosts.isNotEmpty) {
      LogService.i("Removing ${ghosts.length} ghosts...");

      // fetch full items so we know which thumbnails to delete
      final ghostItems = await _database.getMediaItemsByFilenames(ghosts, folderPath);

      // delete thumbnail files
      if (_session.appSupportPath != null) {
        final thumbDir = Directory(p.join(_session.appSupportPath!, "thumbnails"));

        for (var item in ghostItems) {
          if (item.thumbnailPath != null) {
            try {
              final thumbFile = File(p.join(thumbDir.path, item.thumbnailPath));
              if (await thumbFile.exists()) {
                await thumbFile.delete();
              }
            } catch (e) {
              LogService.e("Failed to delete ghost thumbnail: ${item.thumbnailPath}", e);
            }
          }
        }
      }

      // delete ghost database records
      await _database.deleteMediaItems(ghosts, folderPath);

      await _gallery.refreshLibrary();

      LogService.i("Removed ${ghosts.length} ghosts.");
    }
  }

  // helper: identify and process orphans
  Future<void> _handleOrphans(
    Set<String> dbFileSet,
    List<File> diskFiles
  ) async {
    final orphans = <String>[];

    for (var file in diskFiles) {
      if (!dbFileSet.contains(p.basename(file.path))) {
        orphans.add(file.path);
      }
    }

    if (orphans.isNotEmpty) {
      LogService.i("Syncing ${orphans.length} orphans...");
      _uploadQueue.addAll(orphans);

      // if we aren't already uploading, start the queue silently (no progress indicator)
      if (!_isUploading) {
        await _processUploadQueue(silent: true);
      }
    } else {
      // if nothing was added, just ensure gallery is synced up
      await _gallery.fullRefresh();
    }
  }

  // helper: check all valid items in current media folder and ensure they have thumbnails
  Future<void> _validateThumbnails(String folderPath) async {
    if (_session.appSupportPath == null) return;

    final items = await _database.getItemsInFolder(folderPath);
    final validTypes = const ["image", "video", "gif"];
    final thumbDir = Directory(p.join(_session.appSupportPath!, "thumbnails"));
    int restoredCount = 0;

    for (var item in items) {
      // skip types that don't need thumbnails (audio, unknown)
      if (!validTypes.contains(item.fileType)) continue;

      String? currentThumbPath = item.thumbnailPath;
      bool needsGeneration = false;

      // path exists in DB, but file is missing from disk
      if (currentThumbPath != null) {
        final thumbFile = File(p.join(thumbDir.path, currentThumbPath));
        if (!await thumbFile.exists()) {
          needsGeneration = true;
        }
      } else {
        // path is NULL in DB which shouldn't happen for valid media items so regenerate thumbnail
        needsGeneration = true;
      }

      if (needsGeneration) {
        final sourcePath = p.join(folderPath, item.hashedFileName);

        // only generate if source file actually exists
        if (await File(sourcePath).exists()) {
          try {
            final newThumbPath = await ThumbnailHelper.generateThumbnail(
              sourcePath: sourcePath,
              fileType: item.fileType,
              fileHash: item.fileHash,
              durationMs: item.duration ?? 0,
            );

            // if the thumbnailPath was null or path changed, update DB record
            if (item.thumbnailPath != newThumbPath) {
              await _database.updateThumbnail(item.hashedFileName, newThumbPath);
            }

            // evict old image from Flutter's cache
            if (newThumbPath != null) {
              final fullThumbPath = p.join(thumbDir.path, newThumbPath);
              await FileImage(File(fullThumbPath)).evict();
              restoredCount++;
            }
          } catch (e) {
            LogService.e("Failed to restore thumbnail for ${item.hashedFileName}", e);
          }
        }
      }
    }

    if (restoredCount > 0) {
      LogService.i("Restored $restoredCount missing thumbnails.");
      await _gallery.refreshLibrary();
    }
  }

  Future<void> _handleBundleImport(String bundlePath) async {
    final destFolder = _session.mediaFolderPath;
    if (destFolder == null) return;

    // unpacking
    _jobStatus.startJob("Unpacking bundle...");
    notifyListeners();

    final unpackedPath = await BundleImportService.unpackBundle(bundlePath);
    if (unpackedPath == null) {
      _jobStatus.finishJob("Unpack failed", isError: true);
      notifyListeners();
      return;
    }

    final metadata = await BundleImportService.readMetadata(unpackedPath);
    if (metadata == null) {
      _jobStatus.finishJob("Invalid bundle metadata", isError: true);
      notifyListeners();
      await BundleImportService.cleanup(unpackedPath);
      return;
    }

    _jobStatus.finishJob("Unpacking complete");
    notifyListeners();

    // importing
    final itemsToImport = metadata.entries.toList();
    if (itemsToImport.isEmpty) {
      _jobStatus.finishJob("Bundle is empty");
      await BundleImportService.cleanup(unpackedPath);
      return;
    }

    _jobStatus.startJob("Processing bundle...");
    notifyListeners();

    final mediaDir = p.join(unpackedPath, "media");
    final thumbsDir = p.join(unpackedPath, "thumbs");

    final supportPath = _session.appSupportPath;
    final systemThumbsDir = supportPath != null ? p.join(supportPath, "thumbnails") : null;

    for (final entry in itemsToImport) {
      final hashedFileName = entry.key;
      final data = entry.value as Map<String, dynamic>;

      _jobStatus.updateProgress(hashedFileName);

      final sourceMedia = p.join(mediaDir, hashedFileName);
      final destMedia = p.join(destFolder, hashedFileName);

      bool isSuccess = true;

      // copy media file
      if (await File(sourceMedia).exists()) {
        if (!await File(destMedia).exists()) {
          await compute(_copyFileInBackground, [sourceMedia, destMedia]);
        }
      } else {
        isSuccess = false; // missing in bundle
      }

      // copy thumbnail
      final thumbPath = data["thumbnailPath"] as String?;
      if (thumbPath != null && systemThumbsDir != null) {
        final sourceThumb = p.join(thumbsDir, thumbPath);
        final destThumb = p.join(systemThumbsDir, thumbPath);

        if (await File(sourceThumb).exists() && !await File(destThumb).exists()) {
          if (!await Directory(systemThumbsDir).exists()) {
            await Directory(systemThumbsDir).create(recursive: true);
          }
          await compute(_copyFileInBackground, [sourceThumb, destThumb]);
        }
      }

      // database insert
      if (isSuccess) {
        try {
          final companion = MediaItemsCompanion(
            fileHash: drift.Value(hashedFileName.split(".").first),
            hashedFileName: drift.Value(hashedFileName),
            mediaFolderPath: drift.Value(destFolder),
            originalFileName: drift.Value(hashedFileName),
            fileType: drift.Value(data["fileType"] ?? "unknown"),
            width: drift.Value(data["width"]),
            height: drift.Value(data["height"]),
            duration: drift.Value(data["duration"]),
            tags: drift.Value(data["tags"]),
            thumbnailPath: drift.Value(thumbPath),
          );

          await _database.insertMediaItem(companion);
        } catch (_) {}
      }
    }

    // cleanup & refresh
    await BundleImportService.cleanup(unpackedPath);
    await _gallery.fullRefresh();

    _jobStatus.finishJob("Bundle import complete");
    LogService.i("Bundle import complete.");
    notifyListeners();
  }
}

Future<void> _copyFileInBackground(List<String> paths) async {
  final sourcePath = paths[0];
  final destPath = paths[1];

  final source = File(sourcePath);
  if (await source.exists()) {
    await source.copy(destPath);
  }
}