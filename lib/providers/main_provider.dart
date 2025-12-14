import 'package:flutter/foundation.dart';
import '../services/folder_picker_service.dart';
import '../services/settings_service.dart';
import '../services/logger_service.dart';
import '../services/file_picker_service.dart';
import '../services/file_service.dart';
import 'upload_status_provider.dart';
import '../locator.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' as drift;
import '../data/app_database.dart';
import 'dart:io';
import 'dart:async';
import '../utils/media_helper.dart';

class MainProvider extends ChangeNotifier {
  final FolderPickerService _folderPickerService;
  final SettingsService _settingsService;
  final FilePickerService _filePickerService;
  final FileService _fileService;

  String? _mediaFolderPath;
  String? get mediaFolderPath => _mediaFolderPath;

  int _totalItemCount = 0;
  int get totalItemCount => _totalItemCount;

  final List<String> _uploadQueue = [];
  bool _isUploading = false;

  bool _showSyncCard = false;
  String _syncStatusText = "";
  Timer? _syncTimer;

  bool get showSyncCard => _showSyncCard;
  String get syncStatusText => _syncStatusText;
  
  bool _isSyncingWorkInProgress = false;
  bool get isSyncingWorkInProgress => _isSyncingWorkInProgress;

  MainProvider(
    this._folderPickerService, 
    this._settingsService,
    this._filePickerService,
    this._fileService,
  );

  // load saved settings when app starts
  Future<void> initialize() async {
    _mediaFolderPath = await _settingsService.loadMediaFolderPath();
    if (_mediaFolderPath != null) {
      await refreshFileCount();
      notifyListeners();
    }
  }

  Future<void> selectFolder() async {
    final selectedPath = await _folderPickerService.pickFolder();

    if (selectedPath != null) {
      _mediaFolderPath = selectedPath;
      await _settingsService.saveMediaFolderPath(selectedPath);
      await refreshFileCount();
      notifyListeners();
    }
  }

  Future<void> uploadFiles() async {
    // check if folder is selected
    if (_mediaFolderPath == null) {
      LogService.w('No media folder selected. Cannot upload files.');
      return;
    }

    // 1. pick files to upload
    final files = await _filePickerService.pickMediaFiles();
    if (files == null || files.isEmpty) return;

    // 2. add to queue
    _uploadQueue.addAll(files);
    LogService.i('Added ${files.length} files to queue. Total pending: ${_uploadQueue.length}');

    // 3. update total count in UI immediately
    final statusProvider = getIt<UploadStatusProvider>();
    statusProvider.startUpload(files.length);

    if (!_isUploading) {
      _processUploadQueue();
    }
  }

  Future<void> refreshFileCount() async 
  {
    if (_mediaFolderPath == null) return;

    // start sync state
    _syncTimer?.cancel(); // cancel existing timer
    _showSyncCard = true;
    _isSyncingWorkInProgress = true;
    _syncStatusText = "Synchronizing media folder...";
    notifyListeners();

    try {
      // update count UI immediately
      final database = getIt<AppDatabase>();
      _totalItemCount = await database.getCountForFolder(_mediaFolderPath!);
      notifyListeners();

      // perform sync check
      // get DB files
      final dbFiles = await database.getFilenamesInFolder(_mediaFolderPath!);
      final dbFileSet = dbFiles.toSet();

      // get disk files
      final dir = Directory(_mediaFolderPath!);
      if (!await dir.exists()) return;

      // filter out only files
      final diskFilesList = dir.listSync()
          .whereType<File>()
          .where((f) => !p.basename(f.path).endsWith('.tmp'))
          .toList();
      
      // find orphans (on disk but not in DB)
      final orphans = <String>[];
      for (var file in diskFilesList) {
        final name = p.basename(file.path);
        if (!dbFileSet.contains(name)) {
          orphans.add(file.path);
        }
      }

      // find ghosts (in DB but not on disk)
      final diskFileSet = diskFilesList.map((f) => p.basename(f.path)).toSet();
      final ghosts = <String>[];
      for (var dbName in dbFiles) {
        if (!diskFileSet.contains(dbName)) {
          ghosts.add(dbName);
        }
      }

      // process ghosts
      if (ghosts.isNotEmpty) {
        LogService.i("Found ${ghosts.length} ghost records. Removing from DB...");
        await database.deleteMediaItems(ghosts, _mediaFolderPath!);

        // update count immediately after deletion
        _totalItemCount = await database.getCountForFolder(_mediaFolderPath!);
        notifyListeners();
      }

      // process orphans
      if (orphans.isNotEmpty) {
        LogService.i("Found ${orphans.length} unindexed files. Syncing...");
        _uploadQueue.addAll(orphans);

        // if we are already uploading (user action), we just add to the queue
        // if not, we start a "silent" process
        if (!_isUploading) {
          await _processUploadQueue(silent: true);
        }
      } else {
        _totalItemCount = await database.getCountForFolder(_mediaFolderPath!);
      }
    } catch (e) {
      LogService.e("Sync failed", e);
      _syncStatusText = "Synchronization failed";
    } finally {
      // end sync state
      _isSyncingWorkInProgress = false;
      _syncStatusText = "Media folder synchronized";
      notifyListeners();

      // start 2 second lingering timer
      _syncTimer = Timer(const Duration(seconds: 2), () {
        _showSyncCard = false; // hide the card
        notifyListeners();
      });
    }
  }

  /// serialized loop to process files one by one until the queue is empty
  Future<void> _processUploadQueue({bool silent = false}) async {
    _isUploading = true;
    final statusProvider = getIt<UploadStatusProvider>();
    final database = getIt<AppDatabase>();

    if (!silent) {
      statusProvider.startUpload(_uploadQueue.length);
    }

    // keep looping as long as there are files in the queue
    while (_uploadQueue.isNotEmpty) {
      final sourcePath = _uploadQueue.removeAt(0);
      final fileName = p.basename(sourcePath);
      final isImport = p.isWithin(_mediaFolderPath!, sourcePath);

      if (!silent) {
        statusProvider.updateCurrentFile(fileName, 0);
      }
      CopyResponse response;

      if (isImport) { // no need for copying (manually added files)
        response = await _fileService.importFileWithProgress(
          sourcePath,
          (percent) {
            if (!silent) statusProvider.updateProgress(percent);
          }
        );
      } else { // copy as well (upload button files)
        response = await _fileService.copyFileWithProgress(
          sourcePath,
          _mediaFolderPath!,
          (percent) {
            if (!silent) statusProvider.updateProgress(percent);
          }
        );
      }

      // handle response and insert to DB
      switch (response.status) {
        case CopyResult.success:
          try {
            // create the database record to be inserted
            final entry = MediaItemsCompanion(
              fileHash: drift.Value(response.hash!),
              hashedFileName: drift.Value(response.finalFileName!),
              mediaFolderPath: drift.Value(_mediaFolderPath!),
              originalFileName: drift.Value(fileName),
              fileType: drift.Value(await MediaHelper.inferFileType(sourcePath)),
              // defaults for now:
              width: const drift.Value(0),
              height: const drift.Value(0),
              duration: const drift.Value(0),
            );

            // insert into SQLite
            await database.insertMediaItem(entry);
            LogService.i("DB record inserted for ${response.finalFileName}");
            if (!silent) statusProvider.completeFile();
          } catch (e) {
            LogService.e("Failed to insert DB record", e);
            if (!silent) statusProvider.markFailed();
          }
          break;

        case CopyResult.duplicate:
           if (!silent) statusProvider.markDuplicate();
          break;

        case CopyResult.failure:
          if (!silent) statusProvider.markFailed();
          break;
      }
    }

    await _refreshFileCountInner(database);

    if (!silent) {
      statusProvider.finishUpload();
    }

    _isUploading = false;
    LogService.i('Queue empty. Upload batch complete.');
    notifyListeners();
  }

  // helper to avoid infinite recursion calling refreshFileCount()
  Future<void> _refreshFileCountInner(AppDatabase db) async {
    if (_mediaFolderPath != null) {
      _totalItemCount = await db.getCountForFolder(_mediaFolderPath!);
      notifyListeners();
    }
  }
}