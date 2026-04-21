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

  Future<void> performFullSync() async {
    final folderPath = session.mediaFolderPath;
    if (folderPath == null) return;

    _isSyncing = true;
    notifyListeners();

    await gallery.fullRefresh(resetScroll: false);

    final syncJobId = jobStatus.startJob("Removing stale entries");

    try {
      final dbFiles = await db.getFilenamesInFolder(folderPath);

      final dir = Directory(folderPath);
      if (!await dir.exists()) return;

      final diskFilesList = dir.listSync()
        .whereType<File>()
        .where((f) => !p.basename(f.path).endsWith(".tmp"))
        .toList();

      await _handleGhosts(folderPath, dbFiles, diskFilesList);

      // only process orphans on desktop where users can easily drop files outside application
      if (!Platform.isAndroid && !Platform.isIOS) {
        jobStatus.updateJobTitle(syncJobId, "Importing new files");
        await _handleOrphans(dbFiles.toSet(), diskFilesList, syncJobId);
      }

      jobStatus.updateJobTitle(syncJobId, "Restoring thumbnails");
      await _validateThumbnails(folderPath);

      jobStatus.updateJobTitle(syncJobId, "Backfilling image hashes");
      await _backfillPerceptualHashes(folderPath);

      jobStatus.finishJob(syncJobId, "Media folder synchronized");
    } catch (e) {
      LogService.e("Sync failed.", e);
      jobStatus.finishJob(syncJobId, "Synchronization failed", isError: true);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

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

      final ghostItems = await db.getMediaItemsByFilenames(ghosts, folderPath);

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

      await db.deleteMediaItems(ghosts, folderPath);
      await gallery.refreshLibrary();

      LogService.i("Removed ${ghosts.length} ghosts.");
    }
  }

  /// [syncJobId] is passed so the sync card subtitle can show a countdown
  /// when the upload queue has other items ahead of the orphans.
  Future<void> _handleOrphans(
    Set<String> dbFileSet,
    List<File> diskFiles,
    int syncJobId,
  ) async {
    final orphans = <String>[];

    for (var file in diskFiles) {
      if (!dbFileSet.contains(p.basename(file.path))) {
        orphans.add(file.path);
      }
    }

    if (orphans.isNotEmpty) {
      LogService.i("Syncing ${orphans.length} orphans...");
      await uploadController.enqueueAndProcess(
        orphans,
        onWaiting: (remaining) {
          jobStatus.updateProgress(
            syncJobId,
            remaining > 0 ? "$remaining file(s) ahead in queue..." : "",
          );
        },
      );
    } else {
      await gallery.fullRefresh();
    }
  }

  Future<void> _validateThumbnails(String folderPath) async {
    if (session.appSupportPath == null) return;

    final items = await db.getItemsInFolder(folderPath);
    final validTypes = const ["image", "video", "gif"];
    final thumbDir = Directory(p.join(session.appSupportPath!, AppConstants.thumbnailDirectory));
    int restoredCount = 0;

    for (var item in items) {
      if (!validTypes.contains(item.fileType)) continue;

      String? currentThumbPath = item.thumbnailPath;
      bool needsGeneration = false;

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

        if (await File(sourcePath).exists()) {
          try {
            final newThumbPath = await ThumbnailHelper.generateThumbnail(
              sourcePath: sourcePath,
              fileType: item.fileType,
              fileHash: item.fileHash,
              durationMs: item.duration ?? 0,
            );

            if (item.thumbnailPath != newThumbPath) {
              await db.updateThumbnail(item.hashedFileName, newThumbPath);
            }

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

  Future<void> _backfillPerceptualHashes(String folderPath) async {
    final items = await db.getItemsNeedingPhash(folderPath);
    if (items.isEmpty) return;

    int successCount = 0;
    for (final item in items) {
      final sourcePath = p.join(folderPath, item.hashedFileName);
      final hash = await PhashHelper.computePhash(sourcePath);
      if (hash != null) {
        await db.updatePerceptualHash(item.id, PhashHelper.hashToString(hash));
        successCount++;
      }
    }

    LogService.i("Backfilled perceptual hash for $successCount/${items.length} image items.");
  }
}
