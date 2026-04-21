import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
import '../utils/phash_helper.dart';
import '../providers/status_card_provider.dart';
import 'session_controller.dart';
import 'gallery_controller.dart';
import '../services/bundle_import_service.dart';
import 'package:disk_space_2/disk_space_2.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class UploadController extends ChangeNotifier {
  final AppDatabase db;
  final SessionController session;
  final GalleryController gallery;
  final StatusCardProvider jobStatus;

  final FileService _fileService = getIt<FileService>();
  final FilePickerService _filePickerService = getIt<FilePickerService>();

  final List<_QueueItem> _uploadQueue = [];
  bool _isUploading = false;

  UploadController(this.db, this.session, this.gallery, this.jobStatus) {
    if (Platform.isAndroid || Platform.isIOS) {
      _initIntentListener();
    }
  }

  /// Subscribes to both the background share stream and the cold-start initial media intent.
  void _initIntentListener() {
    ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
    }, onError: (err) {
      LogService.e("Share intent stream error: $err");
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
    });
  }

  /// Routes files received from the OS share sheet — bundles go to [_handleBundleImport], media files to the upload queue.
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
      final jobId = jobStatus.startJob("Receiving shared files...");
      jobStatus.updateProgress(jobId, "${mediaFiles.length} file(s) queued...");
      _uploadQueue.addAll(mediaFiles.map((path) => _QueueItem(path, jobId)));
      notifyListeners();

      if (!_isUploading) {
        _processUploadQueue();
      }
    }

    ReceiveSharingIntent.instance.reset();
  }

  /// Opens the file picker, checks available disk space, then enqueues selected media files for upload.
  /// Bundles (.stepstone) picked alongside media files are imported first before the queue starts.
  Future<void> uploadFiles() async {
    if (session.mediaFolderPath == null) {
      LogService.w("No media folder selected.");
      return;
    }

    final files = await _filePickerService.pickMediaFiles();
    if (files == null || files.isEmpty) return;

    final bundleFiles = files.where((f) => p.extension(f).toLowerCase() == ".stepstone").toList();
    final mediaFiles = files.where((f) => p.extension(f).toLowerCase() != ".stepstone").toList();

    for (final bundlePath in bundleFiles) {
      await _handleBundleImport(bundlePath);
    }

    if (mediaFiles.isEmpty) return;

    final jobId = jobStatus.startJob("Uploading files...");

    // disk space check
    final folderPath = session.mediaFolderPath!;
    double totalBytes = 0;
    for (final path in mediaFiles) {
      final file = File(path);
      if (await file.exists()) totalBytes += await file.length();
    }
    final hasSpace = await _hasEnoughSpace(totalBytes / (1024 * 1024), folderPath);
    if (!hasSpace) {
      jobStatus.finishJob(jobId, "Insufficient disk space", isError: true);
      notifyListeners();
      return;
    }

    jobStatus.updateProgress(jobId, "${mediaFiles.length} file(s) queued...");
    _uploadQueue.addAll(mediaFiles.map((path) => _QueueItem(path, jobId)));
    notifyListeners();

    if (!_isUploading) {
      _processUploadQueue();
    }
  }

  /// Enqueues orphan [files] (already on disk) and starts the pipeline if not already running.
  /// [onWaiting] is called every ~50ms with the count of non-orphan items still ahead in the queue,
  /// allowing callers to show a countdown on their own status card.
  /// Called by SyncController when orphan files are discovered. No disk space check needed — orphans are already on disk.
  Future<void> enqueueAndProcess(
    List<String> files, {
    void Function(int remaining)? onWaiting,
  }) async {
    _uploadQueue.addAll(files.map((path) => _QueueItem(path, null)));
    if (!_isUploading) {
      await _processUploadQueue();
    } else {
      // Queue already running; wait for it to drain before returning so
      // SyncController doesn't advance to thumbnail/hash steps prematurely.
      while (_isUploading) {
        final ahead = _uploadQueue.where((i) => i.jobId != null).length;
        onWaiting?.call(ahead);
        await Future.delayed(const Duration(milliseconds: 50));
      }
      onWaiting?.call(0);
    }
  }

  /// Drains the upload queue one file at a time: copies the file, infers its type, generates a thumbnail, and inserts the DB record.
  /// Each queued item carries its own job ID; progress and completion are reported per-job automatically.
  Future<void> _processUploadQueue() async {
    _isUploading = true;
    final folderPath = session.mediaFolderPath!;

    while (_uploadQueue.isNotEmpty) {
      final item = _uploadQueue.removeAt(0);
      final sourcePath = item.path;
      final jobId = item.jobId;
      final fileName = p.basename(sourcePath);
      final isImport = p.isWithin(folderPath, sourcePath);

      if (jobId != null) jobStatus.updateProgress(jobId, fileName);

      CopyResponse response;
      if (isImport) {
        response = await _fileService.hashAndRenameInPlace(sourcePath); // orphans (inside media folder)
      } else {
        response = await _fileService.hashAndCopyFile(sourcePath, folderPath); // regular upload (outside media folder)
      }

      if (response.status == CopyResult.success) {
        try {
          final finalPath = p.join(folderPath, response.finalFileName!);

          var type = await MediaHelper.inferFileType(finalPath);
          final metadata = await MetadataHelper.extractMetadata(finalPath, type);

          if (type == "video" && metadata.width == 0 && metadata.height == 0) {
            type = "audio";
            LogService.i("Audio-only video file detected. Reclassifying as audio: ${response.finalFileName}");
          }

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

          final insertedId = await db.insertMediaItem(entry);

          if (type == "image") {
            await _checkPerceptualDuplicates(insertedId, finalPath, folderPath);
          }
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

      // Finish this job's card when its last item has been processed
      if (jobId != null && !_uploadQueue.any((i) => i.jobId == jobId)) {
        jobStatus.finishJob(jobId, "Upload complete");
      }
    }

    await gallery.fullRefresh(resetScroll: false);
    session.updateDiskSpace();

    _isUploading = false;
    LogService.i("Queue empty. Upload complete.");
    notifyListeners();
  }

  /// Unpacks a .stepstone bundle, copies its media and thumbnails into the library, and inserts DB records with tags.
  Future<void> _handleBundleImport(String bundlePath) async {
    final destFolder = session.mediaFolderPath;
    if (destFolder == null) return;

    final jobId = jobStatus.startJob("Unpacking bundle...");
    notifyListeners();

    final bundleFile = File(bundlePath);
    if (await bundleFile.exists()) {
      final bundleBytes = await bundleFile.length();
      final bundleMB = bundleBytes / (1024 * 1024);

      // multiply by 2.2 = unpacked temp folder + final copied files + buffer
      final requiredMB = bundleMB * 2.2;

      final hasSpace = await _hasEnoughSpace(requiredMB, destFolder);
      if (!hasSpace) {
        jobStatus.finishJob(jobId, "Insufficient disk space for bundle", isError: true);
        notifyListeners();
        return;
      }
    }

    final unpackedPath = await BundleImportService.unpackBundle(bundlePath);
    if (unpackedPath == null) {
      jobStatus.finishJob(jobId, "Unpack failed", isError: true);
      notifyListeners();
      return;
    }

    final metadata = await BundleImportService.readMetadata(unpackedPath);
    if (metadata == null) {
      jobStatus.finishJob(jobId, "Invalid bundle metadata", isError: true);
      notifyListeners();
      await BundleImportService.cleanup(unpackedPath);
      return;
    }

    final itemsToImport = metadata.entries.toList();
    if (itemsToImport.isEmpty) {
      jobStatus.finishJob(jobId, "Bundle is empty");
      await BundleImportService.cleanup(unpackedPath);
      return;
    }

    jobStatus.updateJobTitle(jobId, "Processing bundle...");
    notifyListeners();

    final mediaDir = p.join(unpackedPath, "media");
    final thumbsDir = p.join(unpackedPath, "thumbs");

    final supportPath = session.appSupportPath;
    final systemThumbsDir = supportPath != null ? p.join(supportPath, AppConstants.thumbnailDirectory) : null;

    for (final entry in itemsToImport) {
      final hashedFileName = entry.key;
      final data = entry.value as Map<String, dynamic>;

      jobStatus.updateProgress(jobId, hashedFileName);

      final sourceMedia = p.join(mediaDir, hashedFileName);
      final destMedia = p.join(destFolder, hashedFileName);

      bool isSuccess = true;
      bool isDuplicate = false;

      if (await File(sourceMedia).exists()) {
        if (!await File(destMedia).exists()) {
          await compute(_copyFileInBackground, [sourceMedia, destMedia]);
        } else {
          isDuplicate = true;
          LogService.w("Duplicate item skipped: $hashedFileName");
        }
      } else {
        isSuccess = false;
        LogService.w("Import warning: file listed in metadata but missing in bundle: $hashedFileName");
      }

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

          if (data["tags"] != null && data["tags"].toString().isNotEmpty) {
            await db.updateMediaTags(insertedId, data["tags"]);
          }

          final fileType = data["fileType"] ?? "unknown";
          if (fileType == "image") {
            final mediaPath = p.join(destFolder, hashedFileName);
            await _checkPerceptualDuplicates(insertedId, mediaPath, destFolder);
          }
        } catch (e) {
          LogService.e("Failed to insert media item into database: $hashedFileName", e);
        }
      }
    }

    await BundleImportService.cleanup(unpackedPath);
    await gallery.fullRefresh();
    session.updateDiskSpace();

    jobStatus.finishJob(jobId, "Bundle import complete");
    LogService.i("Bundle import complete.");
    notifyListeners();
  }

  /// Computes a perceptual hash for the newly uploaded image and flags any existing items above the 95% similarity threshold for review.
  Future<void> _checkPerceptualDuplicates(int uploadedId, String filePath, String folderPath) async {
    final hash = await PhashHelper.computePhash(filePath);
    if (hash == null) {
      LogService.w("Could not compute perceptual hash for $filePath — skipping similarity check.");
      return;
    }

    await db.updatePerceptualHash(uploadedId, PhashHelper.hashToString(hash));

    final existing = await db.getItemsWithPhash(folderPath);
    int flagged = 0;

    for (final item in existing) {
      if (item.id == uploadedId) continue;
      final existingHash = PhashHelper.hashFromString(item.perceptualHash!);
      if (existingHash == null) continue;

      final sim = PhashHelper.similarity(hash, existingHash);
      if (sim >= 95.0) {
        await db.insertPendingReview(uploadedId, item.id, sim);
        flagged++;
      }
    }

    if (flagged > 0) {
      LogService.i("Flagged $flagged potential duplicate(s) for review.");
    }
  }

  /// Returns true if [targetPath]'s drive has at least [requiredMB] + 200 MB free. Fails open if the OS cannot report disk space.
  Future<bool> _hasEnoughSpace(double requiredMB, String targetPath) async {
    try {
      final freeSpaceMB = await DiskSpace.getFreeDiskSpaceForPath(targetPath);
      if (freeSpaceMB == null) return true;

      final safeRequiredMB = requiredMB + 200.0;

      if (safeRequiredMB > freeSpaceMB) {
        LogService.e("Insufficient disk space. Need: ${safeRequiredMB.toStringAsFixed(2)}MB, Free: ${freeSpaceMB.toStringAsFixed(2)}MB");
        return false;
      }

      return true;
    } catch (e) {
      LogService.w("Could not check disk space for $targetPath: $e");
      return true;
    }
  }
}

class _QueueItem {
  final String path;
  final int? jobId; // null = orphan (no status card update)
  _QueueItem(this.path, this.jobId);
}

Future<void> _copyFileInBackground(List<String> paths) async {
  final sourcePath = paths[0];
  final destPath = paths[1];

  final source = File(sourcePath);
  if (await source.exists()) {
    await source.copy(destPath);
  }
}
