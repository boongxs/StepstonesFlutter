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
import '../utils/audio_fingerprint_helper.dart';
import '../providers/status_card_provider.dart';
import 'session_controller.dart';
import 'gallery_controller.dart';
import 'settings_controller.dart';
import '../services/bundle_import_service.dart';
enum _QueueItemType { upload, bundle, orphan }

class _QueueItem {
  final String path;
  final _QueueItemType type;
  _QueueItem(this.path, this.type);
}

class UploadController extends ChangeNotifier {
  final AppDatabase db;
  final SessionController session;
  final GalleryController gallery;
  final StatusCardProvider jobStatus;
  final SettingsController settings;

  final FileService _fileService = getIt<FileService>();
  final FilePickerService _filePickerService = getIt<FilePickerService>();

  final List<_QueueItem> _uploadQueue = [];
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  UploadController(this.db, this.session, this.gallery, this.jobStatus, this.settings);

  /// Opens the file picker and enqueues selected files.
  /// Bundles (.stepstone) and media files are queued together and dispatched by type.
  Future<void> uploadFiles() async {
    // can't upload files if uploaded files have nowhere to go (no selected media folder)
    if (session.mediaFolderPath == null) {
      LogService.w("No media folder selected.");
      return;
    }

    // open file picker
    final files = await _filePickerService.pickMediaFiles();
    if (files == null || files.isEmpty) return;

    for (final path in files) {
      final isBundle = p.extension(path).toLowerCase() == ".stepstone";
      _uploadQueue.add(_QueueItem(path, isBundle ? _QueueItemType.bundle : _QueueItemType.upload));
    }

    // if not already running, start the queue
    if (!_isUploading) _processUploadQueue();
  }

  /// Enqueues orphan [files] (already on disk) silently and awaits full queue drain.
  /// Called by SyncController after ghost cleanup; awaited so sync doesn't advance until all orphans are in the DB.
  Future<void> enqueueAndProcess(List<String> files) async {
    for (final path in files) {
      _uploadQueue.add(_QueueItem(path, _QueueItemType.orphan));
    }
    if (!_isUploading) await _processUploadQueue();
  }

  /// Drains the upload queue, dispatching each item to the appropriate handler based on its type.
  Future<void> _processUploadQueue() async {
    _isUploading = true;
    notifyListeners(); // disable select folder and refresh buttons (reads _isUploading state)

    bool hadVisibleItems = false;
    bool cardStarted = false;

    while (_uploadQueue.isNotEmpty) {
      final item = _uploadQueue.removeAt(0);

      switch (item.type) {
        case _QueueItemType.upload:
          if (!cardStarted) { 
            jobStatus.startJob("Uploading files..."); 
            cardStarted = true; 
          } else { 
            jobStatus.updateTitle("Uploading files..."); 
          }

          hadVisibleItems = true;

          jobStatus.updateSubtitle(p.basename(item.path));
          await _processFile(item.path, inPlace: false);

        case _QueueItemType.bundle:
          if (!cardStarted) { 
            jobStatus.startJob("Unpacking bundle..."); 
            cardStarted = true; 
          } else { 
            jobStatus.updateTitle("Unpacking bundle..."); 
          }

          hadVisibleItems = true;

          jobStatus.updateSubtitle("");
          await _handleBundleImport(item.path);

        case _QueueItemType.orphan:
          await _processFile(item.path, inPlace: true);
      }
    }

    await gallery.fullRefresh(resetScroll: false);

    if (hadVisibleItems) jobStatus.finishJob("Upload complete");

    _isUploading = false;
    notifyListeners(); // enable select folder and reload buttons
  }

  /// Copies or renames a single file into the media folder, generates metadata, thumbnail, and DB record.
  /// [inPlace] = true for orphans already inside the media folder (rename only); false for external uploads (copy).
  Future<void> _processFile(String sourcePath, {required bool inPlace}) async {
    final folderPath = session.mediaFolderPath!; // destination folder 
    final fileName = p.basename(sourcePath); // original filename

    // rename the file to a unique hash
    final CopyResponse response;
    if (inPlace) {
      response = await _fileService.hashAndRenameInPlace(sourcePath); // only rename to unique hash
    } else {
      response = await _fileService.hashAndCopyFile(sourcePath, folderPath); // rename and copy to current media folder
    }

    // at this point the current file is in media folder and renamed
    if (response.status == CopyResult.success) {
      try {
        final finalPath = p.join(folderPath, response.finalFileName!);

        // file metadata extraction
        var type = await MediaHelper.inferFileType(finalPath); // get file type (image/video/GIF/audio/unknown)
        final metadata = await MetadataHelper.extractMetadata(finalPath, type); // extract width, height, duration

        // if file is "video" type and contains no video track, reclassify as "audio" file
        if (type == "video" && metadata.width == 0 && metadata.height == 0) {
          type = "audio";
          LogService.i("Audio-only video file detected. Reclassifying as audio: ${response.finalFileName}");
        }

        // generate a thumbnail for file
        final thumb = await ThumbnailHelper.generateThumbnail(
          sourcePath: finalPath,
          fileType: type,
          fileHash: response.hash!,
          durationMs: metadata.durationMs,
        );

        // insert a record into database for file
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

        // if file is "image" type, run a potential duplicate check
        if (type == "image") {
          await _checkPerceptualDuplicates(insertedId, finalPath, folderPath);
        }
        if (type == "video" || type == "audio") {
          await _checkAudioDuplicates(insertedId, finalPath, folderPath);
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
  }

  /// Unpacks a .stepstone bundle and imports its contents into the library.
  /// Updates the shared status card title/subtitle; does not manage card lifecycle (caller's responsibility).
  Future<void> _handleBundleImport(String bundlePath) async {
    final destFolder = session.mediaFolderPath;
    if (destFolder == null) return;

    // unpack everything from bundle file into a temp directory
    final unpackedPath = await BundleImportService.unpackBundle(bundlePath);
    if (unpackedPath == null) {
      return;
    }

    // read JSON file and parse it into a Map
    final metadata = await BundleImportService.readMetadata(unpackedPath);
    if (metadata == null) {
      await BundleImportService.cleanup(unpackedPath);
      return;
    }

    // convert Map into a List
    final itemsToImport = metadata.entries.toList();

    jobStatus.updateTitle("Processing bundle...");

    // build paths to the two subfolders inside the unpacked folder
    final mediaDir = p.join(unpackedPath, "media");
    final thumbsDir = p.join(unpackedPath, "thumbs");

    // build destination folder for thumbnail files
    final systemThumbsDir = p.join(session.appSupportPath, AppConstants.thumbnailDirectory);

    // main loop to process unpacked media files one by one
    for (final entry in itemsToImport) {
      // unpack key (filename) and value (metadata map)
      final hashedFileName = entry.key; 
      final data = entry.value as Map<String, dynamic>;

      // update subtitle to current file being processed
      jobStatus.updateSubtitle(hashedFileName);

      final sourceMedia = p.join(mediaDir, hashedFileName);
      final destMedia = p.join(destFolder, hashedFileName);

      // guards to prevent duplicate database insert
      bool isSuccess = true;
      bool isDuplicate = false;

      // copy media file from unpackedPath to media folder
      if (await File(sourceMedia).exists()) { // does the file from unpacked bundle exist? is in manifest but doesn't have to be on disk
        if (!await File(destMedia).exists()) { // is a file with this filename already in media folder?
          await compute(_copyFileInBackground, [sourceMedia, destMedia]);
        } else {
          isDuplicate = true;
          LogService.w("Duplicate item skipped: $hashedFileName");
        }
      } else {
        isSuccess = false;
        LogService.w("Import warning: file listed in metadata but missing in bundle: $hashedFileName");
      }

      // copy media file's thumbnail file from unpackedPath to thumbnails folder
      final thumbPath = data["thumbnailPath"] as String?;
      if (isSuccess && !isDuplicate && thumbPath != null) {
        final sourceThumb = p.join(thumbsDir, thumbPath);
        final destThumb = p.join(systemThumbsDir, thumbPath);

        if (await File(sourceThumb).exists() && !await File(destThumb).exists()) {
          if (!await Directory(systemThumbsDir).exists()) {
            await Directory(systemThumbsDir).create(recursive: true);
          }
          await compute(_copyFileInBackground, [sourceThumb, destThumb]);
        }
      }

      // insert database record for media file
      if (isSuccess && !isDuplicate) {
        try {
          // first insert the media item
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

          // after that insert media item's tags to properly link the tags to the media item
          if (data["tags"] != null && data["tags"].toString().isNotEmpty) {
            await db.updateMediaTags(insertedId, data["tags"]);
          }

          // for "image" type media items, check for potential duplicates
          if (data["fileType"] == "image") {
            final mediaPath = p.join(destFolder, hashedFileName);
            await _checkPerceptualDuplicates(insertedId, mediaPath, destFolder);
          }
          if (data["fileType"] == "video" || data["fileType"] == "audio") {
            final mediaPath = p.join(destFolder, hashedFileName);
            await _checkAudioDuplicates(insertedId, mediaPath, destFolder);
          }
        } catch (e) {
          LogService.e("Failed to insert media item into database: $hashedFileName", e);
        }
      }
    }

    await BundleImportService.cleanup(unpackedPath);
    LogService.i("Bundle import complete.");
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
      if (sim >= settings.similarityThreshold) {
        await db.insertPendingReview(uploadedId, item.id, sim);
        flagged++;
      }
    }

    if (flagged > 0) {
      LogService.i("Flagged $flagged potential duplicate(s) for review.");
    }
  }

  Future<void> _checkAudioDuplicates(int uploadedId, String filePath, String folderPath) async {
    final (:fingerprint, :tooShort) = await AudioFingerprintHelper.computeFingerprint(filePath);
    if (fingerprint.isEmpty) {
      if (tooShort) {
        LogService.w("Audio fingerprint skipped for $filePath — file is too short for Chromaprint to analyze (requires ~3+ seconds of audio).");
      } else {
        LogService.w("No audio fingerprint for $filePath — skipping duplicate check.");
      }
      await db.updateAudioFingerprint(uploadedId, "");
      return;
    }

    await db.updateAudioFingerprint(uploadedId, AudioFingerprintHelper.fingerprintToString(fingerprint));

    final existingItems = await db.getItemsWithAudioFingerprint(folderPath);
    final existing = existingItems
        .where((item) => item.id != uploadedId)
        .map((item) => {
              'id': item.id,
              'fingerprint': AudioFingerprintHelper.fingerprintFromString(item.audioFingerprint!) ?? <int>[],
            })
        .where((e) => (e['fingerprint'] as List).isNotEmpty)
        .toList();

    if (existing.isEmpty) return;

    final matches = await AudioFingerprintHelper.compareAll(fingerprint, existing, settings.similarityThreshold);
    for (final match in matches) {
      await db.insertPendingReview(uploadedId, match['id'] as int, match['similarity'] as double);
    }
    if (matches.isNotEmpty) {
      LogService.i("Flagged ${matches.length} potential audio/video duplicate(s) for review.");
    }
  }
}

Future<void> _copyFileInBackground(List<String> paths) async {
  final source = File(paths[0]);
  if (await source.exists()) {
    await source.copy(paths[1]);
  }
}
