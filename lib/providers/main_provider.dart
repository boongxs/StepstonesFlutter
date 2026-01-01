import 'package:path_provider/path_provider.dart';
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
import '../utils/metadata_helper.dart';
import '../utils/thumbnail_helper.dart';
import 'package:flutter/material.dart';

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

  // virtualization / cache state
  static const int _pageSize = 50;
  static const int _maxPagesInMemory = 4;
  final Map<int, List<MediaItem>> _pageCache = {};
  Map<int, List<MediaItem>> _stalePageCache = {};
  final List<int> _pageUsageHistory = []; //usage history: first element -> oldest, last element -> newest
  final Set<int> _pagesBeingFetched = {}; // prevent duplicate fetches

  String? _appSupportPath;
  String? get appSupportPath => _appSupportPath;

  final AppDatabase _database;

  final ScrollController scrollController = ScrollController();
  String? _currentSearchQuery = "";
  Timer? _searchDebounceTimer;

  MainProvider(
    this._folderPickerService, 
    this._settingsService,
    this._filePickerService,
    this._fileService,
    this._database,
  );

  // load saved settings when app starts
  Future<void> initialize() async {
    final dir = await getApplicationSupportDirectory();
    _appSupportPath = dir.path;
    
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
      await _refreshFileCountInner(database);

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
        _invalidateCache();
        _totalItemCount = await database.getCountForFolder(_mediaFolderPath!);
        notifyListeners();
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

  // public accessor (used by UI)
  MediaItem? getItem(int index) {
    final pageIndex = index ~/ _pageSize;
    final indexInPage = index % _pageSize;

    // check if we have the page
    if (_pageCache.containsKey(pageIndex)) {
      // mark as recently used
      _touchPage(pageIndex);

      final page = _pageCache[pageIndex]!;
      // safety check for bounds
      if (indexInPage < page.length) {
        return page[indexInPage];
      }
    }

    // cache miss: trigger fetch
    _fetchPage(pageIndex);

    // while waiting for the fetch, show the old data
    if (_stalePageCache.containsKey(pageIndex)) {
      final page = _stalePageCache[pageIndex]!;
      if (indexInPage < page.length) {
        return page[indexInPage];
      }
    }

    // return null so UI shows "loading..."
    return null;
  }

  void _touchPage(int pageIndex) {
    _pageUsageHistory.remove(pageIndex);
    _pageUsageHistory.add(pageIndex);
  }

  // internal fetcher
  void _fetchPage(int pageIndex) {
    if (_pagesBeingFetched.contains(pageIndex)) return;
    if (_mediaFolderPath == null) return;

    _pagesBeingFetched.add(pageIndex);
    final db = getIt<AppDatabase>();
    final offset = pageIndex * _pageSize;

    db.getPagedMediaItems(
      _mediaFolderPath!,
      _pageSize, 
      offset,
      searchQuery: _currentSearchQuery
    ).then((items) {
      if (items.isEmpty && _totalItemCount > 0) {
        // edge case: DB count might be out of sync, but ignore for now
        _pagesBeingFetched.remove(pageIndex);
        return;
      }

      // store data
      _pageCache[pageIndex] = items;
      _touchPage(pageIndex);
      _pagesBeingFetched.remove(pageIndex);

      // eviction: if too many pages, drop the oldest
      if (_pageUsageHistory.length > _maxPagesInMemory) {
        final oldestPageIndex = _pageUsageHistory.removeAt(0);
        _pageCache.remove(oldestPageIndex);
      }
      notifyListeners();
    }).catchError((e) {
      LogService.e("Fetch failed for page $pageIndex", e);
      _pagesBeingFetched.remove(pageIndex);
    });
  }

  // cache clearing
  // called whenever data changes
  void _invalidateCache() {
    _stalePageCache = Map.from(_pageCache);

    _pageCache.clear();
    _pageUsageHistory.clear();
    _pagesBeingFetched.clear();
  }

  /// serialized loop to process files one by one until the queue is empty
  Future<void> _processUploadQueue({bool silent = false}) async {
    _isUploading = true;
    final statusProvider = getIt<UploadStatusProvider>();
    final database = getIt<AppDatabase>();

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
            final type = await MediaHelper.inferFileType(sourcePath); // get file type
            final metadata = await MetadataHelper.extractMetadata(sourcePath, type); // get width, height, duration
            final thumbFileName = await ThumbnailHelper.generateThumbnail(
              sourcePath: sourcePath,
              fileType: type,
              fileHash: response.hash!,
              durationMs: metadata.durationMs,
            );

            // create the database record to be inserted
            final entry = MediaItemsCompanion(
              fileHash: drift.Value(response.hash!),
              hashedFileName: drift.Value(response.finalFileName!),
              mediaFolderPath: drift.Value(_mediaFolderPath!),
              originalFileName: drift.Value(fileName),
              fileType: drift.Value(type),
              width: drift.Value(metadata.width),
              height: drift.Value(metadata.height),
              duration: drift.Value(metadata.durationMs),
              thumbnailPath: drift.Value(thumbFileName),
            );

            // insert into SQLite
            await database.insertMediaItem(entry);
            LogService.i("DB record inserted for ${response.finalFileName}");
            if (!silent) statusProvider.completeFile();
          } catch (e) {
            // check if this is a unique constraint error
            final isDuplicate = e.toString().contains("2067") ||
                                e.toString().contains("UNIQUE constraint failed");

            if (isDuplicate) {
              LogService.w("Database constraint: Item already exists. Marking as duplicate.");
              if (!silent) statusProvider.markDuplicate();
            } else {
              // if it's a real error
              LogService.e("Failed to insert DB record", e);
              if (!silent) statusProvider.markFailed();
            }
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

    _invalidateCache();
    await _refreshFileCountInner(database);

    if (!silent) {
      statusProvider.finishUpload();
    }

    _isUploading = false;
    LogService.i('Queue empty. Upload batch complete.');
    notifyListeners();
  }

  Future<bool> deleteItem(MediaItem item) async {
    try {
      // delete source file
      if (_mediaFolderPath != null) {
        final sourceFile = File(p.join(_mediaFolderPath!, item.hashedFileName));
        if (await sourceFile.exists()) {
          await sourceFile.delete();
        }
      }

      // delete thumbnail file
      if (item.thumbnailPath != null && _appSupportPath != null) {
        final thumbFile = File(p.join(_appSupportPath!, 'thumbnails', item.thumbnailPath));
        if (await thumbFile.exists()) {
          await thumbFile.delete();
        }
      }

      // delete from database
      await _database.deleteMediaItem(item.id);

      // update UI and shrink scrollbar appropriately
      _invalidateCache();
      await _refreshFileCountInner(_database);
      notifyListeners();
      return true;
    } catch (e) {
      LogService.e("Failed to delete item: $e");
      return false;
    }
  }

  Future<bool> updateTags(MediaItem item, String rawTags) async {
    try {
      // sanitize input
      var cleaned = rawTags.trim(); // trim whitespace from start and end
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' '); // replace multiple spaces between tags with just one space

      // update database
      await _database.updateMediaTags(item.id, cleaned);

      // update local state
      _invalidateCache();
      notifyListeners();

      return true;
    } catch (e) {
      LogService.e("Failed to update tags: $e");
      return false;
    }
  }

  // helper to avoid infinite recursion calling refreshFileCount()
  Future<void> _refreshFileCountInner(AppDatabase db) async {
    if (_mediaFolderPath == null) return;

    _totalItemCount = await db.getCountForFolder(
      _mediaFolderPath!,
      searchQuery: _currentSearchQuery
    );

    notifyListeners();
  }

  void onSearchTextChanged(String text) {
    _searchDebounceTimer?.cancel();

    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      _currentSearchQuery = text;
      _invalidateCache();
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }

      final db = getIt<AppDatabase>();
      await _refreshFileCountInner(db);
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}