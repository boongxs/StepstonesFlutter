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
import 'session_controller.dart';
import 'gallery_controller.dart';

class SyncController extends ChangeNotifier {
  final AppDatabase _database;
  final SessionController _session;
  final GalleryController _gallery;

  final FileService _fileService = getIt<FileService>();
  final FilePickerService _filePickerService = getIt<FilePickerService>();

  // --- internal state ---
  final List<String> _uploadQueue = [];
  bool _isUploading = false;

  // sync status UI
  bool _showSyncCard = false;
  bool get showSyncCard => _showSyncCard;

  String _syncStatusText = "";
  String get syncStatusText => _syncStatusText;

  Timer? _syncTimer;

  bool _isSyncingWorkInProgress = false;
  bool get isSyncingWorkInProgress => _isSyncingWorkInProgress;

  String _currentSyncingFilename = "";
  String get currentSyncingFilename => _currentSyncingFilename;

  SyncController(
    this._database,
    this._session,
    this._gallery,
  );

  // --- actions ---
  Future<void> uploadFiles() async {
    if (_session.mediaFolderPath == null) {
      LogService.w("No media folder selected.");
      return;
    }

    final files = await _filePickerService.pickMediaFiles();
    if (files == null || files.isEmpty) return;

    _uploadQueue.addAll(files);

    final statusProvider = getIt<UploadStatusProvider>();
    statusProvider.startUpload(files.length);
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
    _syncTimer?.cancel();
    _showSyncCard = true;
    _isSyncingWorkInProgress = true;
    _syncStatusText = "Synchronizing media folder...";

    // show sync status card
    notifyListeners();

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
    } catch (e) {
      LogService.e("Sync failed.", e);
      hasError = true;
      _syncStatusText = "Synchronization failed";
    } finally {
      _isSyncingWorkInProgress = false;

      if (!hasError) {
        _syncStatusText = "Media folder synchronized";
      }
      notifyListeners();

      _syncTimer = Timer(const Duration(seconds: 2), () {
        _showSyncCard = false;
        notifyListeners();
      });
    }
  }

  Future<void> _processUploadQueue({bool silent = false}) async {
    _isUploading = true;
    final statusProvider = getIt<UploadStatusProvider>();
    final folderPath = _session.mediaFolderPath!;

    while (_uploadQueue.isNotEmpty) {
      final sourcePath = _uploadQueue.removeAt(0);
      final fileName = p.basename(sourcePath);
      final isImport = p.isWithin(folderPath, sourcePath);

      // update current filename for the sync card
      if (silent) {
        _currentSyncingFilename = fileName;
        notifyListeners();
      } else {
        statusProvider.updateCurrentFile(fileName, 0);
      }

      // copy / import
      CopyResponse response;
      if (isImport) {
        response = await _fileService.importFileWithProgress(
          sourcePath,
          (p) => !silent ? statusProvider.updateProgress(p) : null
        );
      } else {
        response = await _fileService.copyFileWithProgress(
          sourcePath, 
          folderPath, 
          (p) => !silent ? statusProvider.updateProgress(p) : null
        );
      }

      // DB insert / thumbnail generation
      if (response.status == CopyResult.success) {
        try {
          final type = await MediaHelper.inferFileType(sourcePath);
          final metadata = await MetadataHelper.extractMetadata(sourcePath, type);

          // thumbnail generation on background thread
          final thumb = await ThumbnailHelper.generateThumbnail(
            sourcePath: sourcePath, 
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
          if (!silent) statusProvider.completeFile();
        } catch (e) {
          final isDuplicate = e.toString().contains("2067") || e.toString().contains("UNIQUE constraint failed");
          if (isDuplicate) {
            if (!silent) statusProvider.markDuplicate();
          } else {
            if (!silent) statusProvider.markFailed();
          }
        }
      } else if (response.status == CopyResult.duplicate) {
        if (!silent) statusProvider.markDuplicate();
      } else {
        if (!silent) statusProvider.markFailed();
      }
    }

    if (silent) _currentSyncingFilename = "";

    // queue empty -> refresh
    await _gallery.fullRefresh(resetScroll: false);

    if (!silent) statusProvider.finishUpload();
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

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}