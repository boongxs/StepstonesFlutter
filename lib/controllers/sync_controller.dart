import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:stepstones_flt/constants.dart';
import '../data/app_database.dart';
import '../services/logger_service.dart';
import '../utils/thumbnail_helper.dart';
import '../utils/phash_helper.dart';
import '../providers/status_card_provider.dart';
import 'session_controller.dart';
import 'gallery_controller.dart';
import 'upload_controller.dart';

class SyncController extends ChangeNotifier {
  final AppDatabase db;
  final SessionController session;
  final GalleryController gallery;
  final StatusCardProvider jobStatus;
  final UploadController uploadController;

  String? _previousPath;
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  SyncController(this.db, this.session, this.gallery, this.jobStatus, this.uploadController) {
    session.addListener(() {
      if (session.mediaFolderPath != _previousPath) {
        _previousPath = session.mediaFolderPath;

        if (session.mediaFolderPath != null) {
          gallery.clearSearch();
          performFullSync();
        }
      }
    });
  }

  /// Runs a full library synchronization in four sequential stages:
  /// ghost cleanup → orphan import → thumbnail validation → perceptual hash backfill
  Future<void> performFullSync() async {
    final folderPath = session.mediaFolderPath;
    if (folderPath == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await gallery.fullRefresh(resetScroll: false);
      jobStatus.startJob("Starting synchronization...");

      final dbFilenames = await db.getFilenamesInFolder(folderPath);

      final dir = Directory(folderPath);
      if (!await dir.exists()) {
        jobStatus.finishJob("Folder not found", isError: true);
        return;
      }

      final diskFilesList = dir.listSync()
        .whereType<File>()
        .where((f) => !p.basename(f.path).endsWith(".tmp"))
        .toList();

      jobStatus.updateTitle("Removing stale entries");
      await _handleGhosts(folderPath, dbFilenames, diskFilesList);

      jobStatus.updateTitle("Importing new files");
      await _handleOrphans(dbFilenames.toSet(), diskFilesList);

      jobStatus.updateTitle("Restoring thumbnails");
      await _validateThumbnails(folderPath);

      jobStatus.updateTitle("Backfilling image hashes");
      await _backfillPerceptualHashes(folderPath);

      jobStatus.finishJob("Media folder synchronized");
    } catch (e) {
      LogService.e("Sync failed.", e);
      jobStatus.finishJob("Synchronization failed", isError: true);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Deletes database records that have no actual files on disk
  /// In cases where user deletes media items via their OS file manager
  Future<void> _handleGhosts(
    String folderPath,
    List<String> dbFiles,
    List<File> diskFiles,
  ) async {
    // 1. Find ghosts
    final diskFileSet = diskFiles.map((f) => p.basename(f.path)).toSet(); // extract just filenames
    final ghosts = <String>[];

    // for each database record that is not in diskFileSet
    for (var dbName in dbFiles) {
      if (!diskFileSet.contains(dbName)) {
        ghosts.add(dbName); // add that database record to ghosts List
      }
    }

    // 2. Delete ghost thumbnails
    if (ghosts.isNotEmpty) {
      LogService.i("Removing ${ghosts.length} ghost(s)...");

      final ghostItems = await db.getMediaItemsByFilenames(ghosts, folderPath); // get actual MediaItem objects just for ghosts

      // check if AppData folder exists
      if (session.appSupportPath != null) {
        final thumbDir = Directory(p.join(session.appSupportPath!, AppConstants.thumbnailDirectory)); // paths to /thumbnails folder

        for (var item in ghostItems) {
          // if item does not have a thumbnail (e.g. audio files), skip
          if (item.thumbnailPath != null) {
            try {
              final thumbFile = File(p.join(thumbDir.path, item.thumbnailPath)); // build the full path to item's thumbnail
              // check if thumbnail file wasn't already deleted
              if (await thumbFile.exists()) {
                await thumbFile.delete();
                LogService.i("Removed ${item.thumbnailPath}.");
              }
            } catch (e) {
              LogService.e("Failed to delete ghost thumbnail: ${item.thumbnailPath}", e);
            }
          }
        }
      }

      // 3. Delete ghosts' database records and refresh grid
      await db.deleteMediaItems(ghosts, folderPath);
      await gallery.refreshLibrary();

      LogService.i("Removed ${ghosts.length} ghosts.");
    }
  }

  /// Uploads files that have no database record
  /// In cases where user drops files directly into the media folder instead of the Upload button
  Future<void> _handleOrphans(
    Set<String> dbFileSet,
    List<File> diskFiles,
  ) async {
    final orphans = <String>[];

    // 1. Find orphans
    for (var file in diskFiles) {
      // if the [file]'s filename does not exist in [dbFileSet], add to [orphans] List 
      if (!dbFileSet.contains(p.basename(file.path))) {
        orphans.add(file.path);
      }
    }

    // 2. Process found orphans
    if (orphans.isNotEmpty) {
      LogService.i("Syncing ${orphans.length} orphans...");
      await uploadController.enqueueAndProcess(orphans); // await orphans that have been sent to the import pipeline
      // grid refresh happens after upload queue drains (when all orphans are imported)
    }
  }

  /// Regenerates thumbnail file for media item if it's missing
  Future<void> _validateThumbnails(String folderPath) async {
    // check if AppData folder exists
    if (session.appSupportPath == null) return;

    final items = await db.getItemsInFolder(folderPath); // get all media items
    final validTypes = const ["image", "video", "gif"]; // exclude audio and unknown file types
    final thumbDir = Directory(p.join(session.appSupportPath!, AppConstants.thumbnailDirectory)); // build full thumbnail folder path
    int restoredCount = 0;

    for (var item in items) {
      // check if [item] needs their thumbnail regenerated
      if (!validTypes.contains(item.fileType)) continue;

      String? currentThumbPath = item.thumbnailPath;
      bool needsGeneration = false;

      // [needsGeneration] turns true if
      // database has a path but the file is gone from disk (e.g. thumbnails folder was cleared manually)
      // database has [null] for [thumbnailPath] which shouldn't happen for image/video/GIF media items
      if (currentThumbPath != null) {
        final thumbFile = File(p.join(thumbDir.path, currentThumbPath));
        if (!await thumbFile.exists()) {
          needsGeneration = true; // thumbnail file doesn't exist, regenerate
        }
      } else {
        needsGeneration = true; // thumbnail path is null for valid media item, regenerate
      }

      // thumbnail regeneration
      if (needsGeneration) {
        final sourcePath = p.join(folderPath, item.hashedFileName);

        if (await File(sourcePath).exists()) {
          try {
            final newThumbPath = await ThumbnailHelper.generateThumbnail(
              sourcePath: sourcePath,
              fileType: item.fileType, // to determine whether to use thumbnail generation for image/GIF or video/audio
              fileHash: item.fileHash, // for unique thumbnail name
              durationMs: item.duration ?? 0, // video-only, to calculate 10% of total duration
            );

            if (newThumbPath == null) {
              throw Exception("Thumbnail generation failed.");
            }

            // update [thumbnailPath] value in database with newly generated one
            await db.updateThumbnail(item.hashedFileName, newThumbPath);

            final fullThumbPath = p.join(thumbDir.path, newThumbPath);
            await FileImage(File(fullThumbPath)).evict(); // remove cached entry for old thumbnail file from memory to update with new one

            restoredCount++;
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

  /// Generates a perceptual hash for any image media item that doesn't have one yet
  /// New uploads already generate the hash so this is primarily for migration between versions
  Future<void> _backfillPerceptualHashes(String folderPath) async {
    // get only image type media items where [perceptualHash] is null
    final items = await db.getItemsNeedingPhash(folderPath);

    if (items.isEmpty) return;

    int successCount = 0;
    for (final item in items) {
      final sourcePath = p.join(folderPath, item.hashedFileName);

      final hash = await PhashHelper.computePhash(sourcePath);

      // if hash computation fails (e.g. corrupted file), .computePhash returns null and that file is skipped
      if (hash != null) {
        await db.updatePerceptualHash(item.id, PhashHelper.hashToString(hash));
        successCount++;
      }
    }

    LogService.i("Backfilled perceptual hash for $successCount/${items.length} image items.");
  }
}
