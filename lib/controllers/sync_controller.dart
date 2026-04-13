import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' as drift;
import 'package:sqlite3/sqlite3.dart';
import 'package:stepstones_flt/constants.dart';
import '../locator.dart';
import '../data/app_database.dart';
import '../services/logger_service.dart';
import '../services/file_service.dart';
import '../services/file_picker_service.dart';
import '../utils/media_helper.dart';
import '../utils/metadata_helper.dart';
import '../utils/thumbnail_helper.dart';
import '../providers/status_card_provider.dart';
import 'session_controller.dart';
import 'gallery_controller.dart';
import '../services/bundle_import_service.dart';
import 'package:flutter/foundation.dart';
import 'package:disk_space_2/disk_space_2.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class SyncController extends ChangeNotifier {
  final AppDatabase db;
  final SessionController session;
  final GalleryController gallery;
  final StatusCardProvider jobStatus;

  final FileService _fileService = getIt<FileService>();
  final FilePickerService _filePickerService = getIt<FilePickerService>();

  final List<String> _uploadQueue = [];
  bool _isUploading = false;

  String? _previousPath;

  SyncController(this.db, this.session, this.gallery, this.jobStatus) {
    session.addListener(() {
      if (session.mediaFolderPath != _previousPath) {
        _previousPath = session.mediaFolderPath;

        if (session.mediaFolderPath != null) {
          gallery.clearSearch();
          performFullSync();
        }
      }
    });

    if (Platform.isAndroid || Platform.isIOS) {
      _initIntentListener();
    }
  }

  void _initIntentListener() {
    // listen to media shared while app is running in background
    ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
    }, onError: (err) {
      LogService.e("Share intent stream error: $err");
    });

    // listen to media shared when app is completely closed and launched via share
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
    });
  }

  // process incoming paths from Android OS
  Future<void> _handleSharedFiles(List<SharedMediaFile> sharedFiles) async {
    if (sharedFiles.isEmpty) return;

    while (session.mediaFolderPath == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final paths = sharedFiles.map((f) => f.path).toList();
    final bundleFiles = paths.where((f) => p.extension(f).toLowerCase() == ".stepstone").toList();
    final mediaFiles = paths.where((f) => p.extension(f).toLowerCase() != ".stepstone").toList();

    for (final bundlePath in bundleFiles) {
      _handleBundleImport(bundlePath);
    }

    if (mediaFiles.isNotEmpty) {
      _uploadQueue.addAll(mediaFiles);
      jobStatus.startJob("Receiving shared files...");
      notifyListeners();

      if (!_isUploading) {
        _processUploadQueue();
      }
    }

    // clear intent so it doesn't process again
    ReceiveSharingIntent.instance.reset();
  }

  // --- actions ---
  Future<void> uploadFiles() async {
    if (session.mediaFolderPath == null) {
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

    jobStatus.startJob("Uploading files...");
    notifyListeners();

    if (!_isUploading) {
      _processUploadQueue();
    }
  }

  Future<void> performFullSync() async {
    // get media folder path from Session Controller
    final folderPath = session.mediaFolderPath;
    if (folderPath == null) return;

    jobStatus.startJob("Synchronizing media folder");
    notifyListeners();

    await gallery.fullRefresh(resetScroll: false);

    bool hasError = false;
    try {
      // get DB files for current media folder
      final dbFiles = await db.getFilenamesInFolder(folderPath);

      // get disk files from current media folder
      final dir = Directory(folderPath);
      if (!await dir.exists()) return;

      final diskFilesList = dir.listSync()
        .whereType<File>()
        .where((f) => !p.basename(f.path).endsWith(".tmp"))
        .toList();

      await _handleGhosts(folderPath, dbFiles, diskFilesList);

      // only process orphans on desktop where users can easily drop files outside application
      if (!Platform.isAndroid && !Platform.isIOS) {
        await _handleOrphans(dbFiles.toSet(), diskFilesList);
      }

      await _validateThumbnails(folderPath);
    } catch (e) {
      LogService.e("Sync failed.", e);
      hasError = true;
    } finally {
      if (hasError) {
        jobStatus.finishJob("Synchronization failed", isError: true);
      } else {
        jobStatus.finishJob("Media folder synchronized");
      }
      notifyListeners();
    }
  }

  Future<void> _processUploadQueue({bool silent = false}) async {
    _isUploading = true;
    final folderPath = session.mediaFolderPath!;

    // disk space check
    double totalPayloadBytes = 0;
    for (String path in _uploadQueue) {
      final file = File(path);
      if (await file.exists()) {
        totalPayloadBytes += await file.length();
      }
    }

    final payloadMB = totalPayloadBytes / (1024 * 1024);
    final hasSpace = await _hasEnoughSpace(payloadMB, folderPath);

    // not enough space
    if (!hasSpace) {
      jobStatus.finishJob("Insufficient disk space", isError: true);
      _uploadQueue.clear();
      _isUploading = false;
      notifyListeners();
      return;
    }

    while (_uploadQueue.isNotEmpty) {
      final sourcePath = _uploadQueue.removeAt(0);
      final fileName = p.basename(sourcePath);
      final isImport = p.isWithin(folderPath, sourcePath);

      // update status card subtitle
      jobStatus.updateProgress(fileName);

      // copy / import
      CopyResponse response;
      if (isImport) {
        response = await _fileService.importFile(sourcePath);
      } else {
        response = await _fileService.copyFile(sourcePath, folderPath);
      }

      // DB insert / thumbnail generation
      if (response.status == CopyResult.success) {
        try {
          final finalPath = p.join(folderPath, response.finalFileName!);

          var type = await MediaHelper.inferFileType(finalPath);
          final metadata = await MetadataHelper.extractMetadata(finalPath, type);

          // check if video file type contains only audio
          if (type == "video" && metadata.width == 0 && metadata.height == 0) {
            type = "audio";
            LogService.i("Audio-only video file detected. Reclassifying as audio: ${response.finalFileName}");
          }

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

          await db.insertMediaItem(entry);
        } catch (e) {
          if (e is SqliteException && e.extendedResultCode == 2067) {
            LogService.i("Duplicate database entry skipped: $fileName");
          } else {
            LogService.e("Failed to insert media item into database: $fileName", e);
          }
        }
      } else if (response.status == CopyResult.duplicate) {
        LogService.i("Duplicate file on disk skipped: $fileName");
      } else {
        LogService.w("Failed to copy file: $fileName");
      }
    }

    if (silent) {
      jobStatus.updateProgress("");
    } else {
      // if manual upload (not orphan sync), finish job
      jobStatus.finishJob("Upload complete");
    }

    // queue empty -> refresh
    await gallery.fullRefresh(resetScroll: false);

    session.updateDiskSpace();

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
      final ghostItems = await db.getMediaItemsByFilenames(ghosts, folderPath);

      // delete thumbnail files
      if (session.appSupportPath != null) {
        final thumbDir = Directory(p.join(session.appSupportPath!, AppConstants.thumbnailDirectory));

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
      await db.deleteMediaItems(ghosts, folderPath);

      await gallery.refreshLibrary();

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
      await gallery.fullRefresh();
    }
  }

  // helper: check all valid items in current media folder and ensure they have thumbnails
  Future<void> _validateThumbnails(String folderPath) async {
    if (session.appSupportPath == null) return;

    final items = await db.getItemsInFolder(folderPath);
    final validTypes = const ["image", "video", "gif"];
    final thumbDir = Directory(p.join(session.appSupportPath!, AppConstants.thumbnailDirectory));
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
              await db.updateThumbnail(item.hashedFileName, newThumbPath);
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
      await gallery.refreshLibrary();
    }
  }

  Future<void> _handleBundleImport(String bundlePath) async {
    final destFolder = session.mediaFolderPath;
    if (destFolder == null) return;

    // bundle disk space check
    final bundleFile = File(bundlePath);
    if (await bundleFile.exists()) {
      final bundleBytes = await bundleFile.length();
      final bundleMB = bundleBytes / (1024 * 1024);

      // multiply by 2.2 = unpacked temp folder + final copied files + buffer
      final requiredMB = bundleMB * 2.2;

      final hasSpace = await _hasEnoughSpace(requiredMB, destFolder);
      if (!hasSpace) {
        jobStatus.finishJob("Insufficient disk space for bundle", isError: true);
        notifyListeners();
        return;
      }
    }

    // unpacking
    jobStatus.startJob("Unpacking bundle...");
    notifyListeners();

    final unpackedPath = await BundleImportService.unpackBundle(bundlePath);
    if (unpackedPath == null) {
      jobStatus.finishJob("Unpack failed", isError: true);
      notifyListeners();
      return;
    }

    final metadata = await BundleImportService.readMetadata(unpackedPath);
    if (metadata == null) {
      jobStatus.finishJob("Invalid bundle metadata", isError: true);
      notifyListeners();
      await BundleImportService.cleanup(unpackedPath);
      return;
    }

    jobStatus.finishJob("Unpacking complete");
    notifyListeners();

    // importing
    final itemsToImport = metadata.entries.toList();
    if (itemsToImport.isEmpty) {
      jobStatus.finishJob("Bundle is empty");
      await BundleImportService.cleanup(unpackedPath);
      return;
    }

    jobStatus.startJob("Processing bundle...");
    notifyListeners();

    final mediaDir = p.join(unpackedPath, "media");
    final thumbsDir = p.join(unpackedPath, "thumbs");

    final supportPath = session.appSupportPath;
    final systemThumbsDir = supportPath != null ? p.join(supportPath, AppConstants.thumbnailDirectory) : null;

    for (final entry in itemsToImport) {
      final hashedFileName = entry.key;
      final data = entry.value as Map<String, dynamic>;

      jobStatus.updateProgress(hashedFileName);

      final sourceMedia = p.join(mediaDir, hashedFileName);
      final destMedia = p.join(destFolder, hashedFileName);

      bool isSuccess = true;
      bool isDuplicate = false;

      // copy media file
      if (await File(sourceMedia).exists()) {
        if (!await File(destMedia).exists()) {
          await compute(_copyFileInBackground, [sourceMedia, destMedia]);
        } else {
          isDuplicate = true;
          LogService.w("Duplicate item skipped: $hashedFileName");
        }
      } else {
        isSuccess = false; // missing in bundle
        LogService.w("Import warning: file listed in metadata but missing in bundle: $hashedFileName");
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
      if (isSuccess && !isDuplicate) {
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
            thumbnailPath: drift.Value(thumbPath),
          );

          final insertedId = await db.insertMediaItem(companion);

          // insert tags
          if (data["tags"] != null && data["tags"].toString().isNotEmpty) {
            await db.updateMediaTags(insertedId, data["tags"]);
          }
        } catch (e) {
          LogService.e("Failed to insert media item into database: $hashedFileName", e);
        }
      }
    }

    // cleanup & refresh
    await BundleImportService.cleanup(unpackedPath);
    await gallery.fullRefresh();
    session.updateDiskSpace();

    jobStatus.finishJob("Bundle import complete");
    LogService.i("Bundle import complete.");
    notifyListeners();
  }

  Future<bool> _hasEnoughSpace(double requiredMB, String targetPath) async {
    try {
      final freeSpaceMB = await DiskSpace.getFreeDiskSpaceForPath(targetPath);
      if (freeSpaceMB == null) return true; // if OS denies access, attempt anyway

      // add 200MB buffer to not completely fill up disk
      final safeRequiredMB = requiredMB + 200.0;

      if (safeRequiredMB > freeSpaceMB) {
        LogService.e("Insufficient disk space. Need: ${safeRequiredMB.toStringAsFixed(2)}MB, Free: ${freeSpaceMB.toStringAsFixed(2)}MB");
        return false;
      }

      return true;
    } catch (e) {
      LogService.w("Could not check disk space for $targetPath: $e");
      return true; // if unsuccessful, attempt anyway
    }
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