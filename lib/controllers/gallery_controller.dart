import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../data/app_database.dart';
import '../services/logger_service.dart';
import 'session_controller.dart';
import '../constants.dart';

class GalleryController extends ChangeNotifier {
  final AppDatabase _database;
  final SessionController _session;

  // --- view state ---
  int _totalItemCount = 0;
  int get totalItemCount => _totalItemCount;

  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  String? _currentSearchQuery = "";
  String? get currentSearchQuery => _currentSearchQuery;
  Timer? _searchDebounceTimer;

  // --- pagination cache ---
  static const int _pageSize = 200;
  static const int _maxPagesInMemory = 4;
  final Map<int, List<MediaItem>> _pageCache = {};
  Map<int, List<MediaItem>> _stalePageCache = {};
  final List<int> _pageUsageHistory = [];
  final Set<int> _pagesBeingFetched = {};

  GalleryController(this._database, this._session);

  // --- data access (called by UI) ---
  MediaItem? getItem(int index) {
    final pageIndex = index ~/ _pageSize;
    final indexInPage = index % _pageSize;

    // 1. check cache
    if (_pageCache.containsKey(pageIndex)) {
      _touchPage(pageIndex);
      final page = _pageCache[pageIndex]!;
      if (indexInPage < page.length) return page[indexInPage];
    }

    // 2. fetch if missing
    _fetchPage(pageIndex);

    // 3. show stale data if available
    if (_stalePageCache.containsKey(pageIndex)) {
      final page = _stalePageCache[pageIndex]!;
      if (indexInPage < page.length) return page [indexInPage];
    }

    return null;
  }

  // --- public action (called by SyncController or UI) ---
  /// light refresh to just update item count
  Future<void> refreshLibrary() async {
    if (_session.mediaFolderPath == null) return;

    _totalItemCount = await _database.getCountForFolder(
      _session.mediaFolderPath!,
      searchQuery: _currentSearchQuery
    );
    notifyListeners();
  }

  /// heavy refresh to clear cache and for filtering search
  Future<void> fullRefresh({bool resetScroll = true}) async {
    _invalidateCache();
    await refreshLibrary();

    // only jump to top if search query changed or manual refresh button
    if (resetScroll && scrollController.hasClients && _totalItemCount > 0) {
      scrollController.jumpTo(0); // scroll to top on full refresh
    }
  }

  // --- CRUD actions ---
  Future<bool> deleteItems(List<MediaItem> itemsToDelete) async {
    if (itemsToDelete.isEmpty) return true;

    final idsToDelete = itemsToDelete.map((e) => e.id).toList();

    // save scroll position
    double previousOffset = 0.0;
    if (scrollController.hasClients) previousOffset = scrollController.offset;

    try {
      final appDir = AppConstants.appSupportPath;
      const int batchSize = 100;

      // delete physical files in batches
      for (var i = 0; i < itemsToDelete.length; i += batchSize) {
        final end = (i + batchSize < itemsToDelete.length) ? i + batchSize : itemsToDelete.length;
        final batch = itemsToDelete.sublist(i, end);

        await Future.wait(batch.map((item) async {
          // delete main media file
          final sourcePath = item.hashedFileName.startsWith("/")
            ? item.hashedFileName
            : p.join(item.mediaFolderPath, item.hashedFileName);
          final mediaFile = File(sourcePath);
      
          try {
            if (await mediaFile.exists()) await mediaFile.delete();
          } catch (e) {
            LogService.e("Failed to delete media file: $sourcePath", e);
          }

          // delete thumbnail file
          if (item.thumbnailPath != null) {
            final thumbFile = File(p.join(appDir, "thumbnails", item.thumbnailPath!));
            try {
              if (await thumbFile.exists()) await thumbFile.delete();
            } catch (e) {
              LogService.e("Failed to delete thumbnail: ${item.thumbnailPath}", e);
            }
          }
        }));
      }

      // delete database records in batches
      for (var i = 0; i < idsToDelete.length; i += batchSize) {
        final end = (i + batchSize < idsToDelete.length) ? i + batchSize : idsToDelete.length;
        final batchIds = idsToDelete.sublist(i, end);
        await _database.deleteMediaItemsById(batchIds);
      }

      // cleanup UI state
      _invalidateCache();
      await refreshLibrary();

      // update disk space badge
      await _session.updateDiskSpace();

      // restore scroll position
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          final maxExtent = scrollController.position.maxScrollExtent;
          final targetOffset = (previousOffset > maxExtent) ? maxExtent : previousOffset;
          scrollController.jumpTo(targetOffset);
        }
      });

      LogService.i("Successfully deleted ${itemsToDelete.length} items.");

      return true;
    } catch (e) {
      LogService.e("Critical error during deletion pipeline", e);
      notifyListeners();

      return false;
    }
  }

  Future<bool> updateTags(MediaItem item, String rawTags) async {
    try {
      var cleaned = rawTags.trim().replaceAll(RegExp(r'\s+'), ' ');
      await _database.updateMediaTags(item.id, cleaned);

      // only invalidate cache so UI updates the tag text, no need for full count refresh
      _invalidateCache();
      notifyListeners();

      LogService.i("Media item's tags have been updated successfully.");

      return true;
    } catch (e) {
      LogService.e("Failed to update tags: $e");
      return false;
    }
  }

  void onSearchTextChanged(String text) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      _currentSearchQuery = text;
      await fullRefresh(resetScroll: true);
    });
  }

  // --- internal helpers ---
  void _touchPage(int pageIndex) {
    _pageUsageHistory.remove(pageIndex);
    _pageUsageHistory.add(pageIndex);
  }

  void _fetchPage(int pageIndex) {
    if (_pagesBeingFetched.contains(pageIndex)) return;
    if (_session.mediaFolderPath == null) return;

    _pagesBeingFetched.add(pageIndex);
    final offset = pageIndex * _pageSize;

    _database.getPagedMediaItems(
      _session.mediaFolderPath!, 
      _pageSize, 
      offset,
      searchQuery: _currentSearchQuery
    ).then((items) {
      if (items.isEmpty && _totalItemCount > 0) {
        _pagesBeingFetched.remove(pageIndex);
        return;
      }

      _pageCache[pageIndex] = items;
      _touchPage(pageIndex);
      _pagesBeingFetched.remove(pageIndex);

      if (_pageUsageHistory.length > _maxPagesInMemory) {
        final oldest = _pageUsageHistory.removeAt(0);
        _pageCache.remove(oldest);
      }

      notifyListeners();
    }).catchError((e) {
      LogService.e("Fetch failed for page $pageIndex", e);
      _pagesBeingFetched.remove(pageIndex);
    });
  }

  void _invalidateCache() {
    _stalePageCache = Map.from(_pageCache);
    _pageCache.clear();
    _pageUsageHistory.clear();
    _pagesBeingFetched.clear();
  }

  void clearSearch() {
    searchController.clear();
    _currentSearchQuery = "";
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }
}