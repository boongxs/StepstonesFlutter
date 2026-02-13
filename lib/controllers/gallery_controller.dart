import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../data/app_database.dart';
import '../services/logger_service.dart';
import 'session_controller.dart';
import 'package:path_provider/path_provider.dart';

class GalleryController extends ChangeNotifier {
  final AppDatabase _database;
  final SessionController _session;

  // --- view state ---
  int _totalItemCount = 0;
  int get totalItemCount => _totalItemCount;

  final ScrollController scrollController = ScrollController();

  String? _currentSearchQuery = "";
  Timer? _searchDebounceTimer;

  // --- delete animation state ---
  final Set<int> _itemsAnimatingOut = {};
  bool isItemAnimating(int id) => _itemsAnimatingOut.contains(id); 

  // --- pagination cache ---
  static const int _pageSize = 50;
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

  // --- animation helpers ---
  // single item delete 
  Future<void> performOptimisticDelete(int id) async {
    _itemsAnimatingOut.add(id);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
  }

  // batch delete
  Future<void> performBatchOptimisticDelete(List<int> ids) async {
    _itemsAnimatingOut.addAll(ids);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
  }

  // cleanup helper
  void clearAnimatingItems(List<int> ids) {
    _itemsAnimatingOut.removeAll(ids);
    notifyListeners();
  }

  // --- CRUD actions ---
  Future<bool> deleteItem(MediaItem item) async {
    try {
      // save current scroll position
      double previousOffset = 0.0;
      if (scrollController.hasClients) {
        previousOffset = scrollController.offset;
      }

      // delete the media file from disk (using safe session paths)
      final sourceFile = File(p.join(item.mediaFolderPath, item.hashedFileName));
      if (await sourceFile.exists()) {
        await sourceFile.delete();
      } else {
        LogService.w("File not found during deletion: ${sourceFile.path}");
      }

      // delete the thumbnail file
      if (item.thumbnailPath != null) {
        final appDir = await getApplicationSupportDirectory();
        final thumbFile = File(p.join(appDir.path, 'thumbnails', item.thumbnailPath!));
        if (await thumbFile.exists()) {
          await thumbFile.delete();
        }
      }

      // remove record for deleted media file from database
      await _database.deleteMediaItem(item.id);

      _itemsAnimatingOut.remove(item.id);
      _invalidateCache();
      await refreshLibrary();

      // restore scroll position
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          // ensure we don't jump past the new bottom of the list
          final maxExtent = scrollController.position.maxScrollExtent;
          final targetOffset = (previousOffset > maxExtent) ? maxExtent : previousOffset;

          scrollController.jumpTo(targetOffset);
        }
      });

      return true;
    } catch (e) {
      LogService.e("Failed to delete item: $e");

      _itemsAnimatingOut.remove(item.id);
      notifyListeners();

      return false;
    }
  }

  // helper method to clear deleted items from caches
  void _removeItemFromCaches(int id) {
    for (var page in _stalePageCache.values) {
      page.removeWhere((item) => item.id == id);
    }
    for (var page in _pageCache.values) {
      page.removeWhere((item) => item.id == id);
    }
  }

  Future<bool> updateTags(MediaItem item, String rawTags) async {
    try {
      var cleaned = rawTags.trim().replaceAll(RegExp(r'\s+'), ' ');
      await _database.updateMediaTags(item.id, cleaned);

      // only invalidate cache so UI updates the tag text, no need for full count refresh
      _invalidateCache();
      notifyListeners();
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
      LogService.e("Fetched failed for page $pageIndex", e);
      _pagesBeingFetched.remove(pageIndex);
    });
  }

  void _invalidateCache() {
    _stalePageCache = Map.from(_pageCache);
    _pageCache.clear();
    _pageUsageHistory.clear();
    _pagesBeingFetched.clear();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}