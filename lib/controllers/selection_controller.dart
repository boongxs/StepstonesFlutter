import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../data/app_database.dart';
import 'session_controller.dart';
import 'gallery_controller.dart';
import '../services/logger_service.dart';

class SelectionController extends ChangeNotifier {
  final AppDatabase _db;
  final SessionController _session;
  final GalleryController _gallery;

  SelectionController(
    this._db,
    this._session,
    this._gallery,
  );

  bool _isSelectionMode = false;
  bool get isSelectionMode => _isSelectionMode;

  bool _areAllSelected = false;
  bool get areAllSelected => _areAllSelected;

  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  final Set<int> _selectedItemIds = {};
  int get selectedCount => _selectedItemIds.length;
  bool isItemSelected(int id) => _selectedItemIds.contains(id);

  // actions
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    // reset state when closing
    if (!_isSelectionMode) {
      _areAllSelected = false;
      _selectedItemIds.clear();
    }

    notifyListeners();
  }

  void toggleItem(int id) {
    if (_selectedItemIds.contains(id)) {
      // unselecting an item
      _selectedItemIds.remove(id);
      _areAllSelected = false; // if even one item is unchecked, "All selected" must be false
    } else {
      // selecting item
      _selectedItemIds.add(id);
      // check if all items are selected
      if (_selectedItemIds.length == _gallery.totalItemCount) {
        _areAllSelected = true;
      }
    }

    notifyListeners();
  }

  Future<void> toggleSelectAll() async {
    _areAllSelected = !_areAllSelected;

    if (_areAllSelected) {
      if (_session.mediaFolderPath != null) {
        final allIds = await _db.getAllIdsInFolder(_session.mediaFolderPath!);
        _selectedItemIds.addAll(allIds);
      }
    } else {
      _selectedItemIds.clear();
    }

    notifyListeners();
  }

  Future<List<MediaItem>> getSelectedItems() async {
    if (_selectedItemIds.isEmpty) return [];
    return await _db.getMediaItemsByIds(_selectedItemIds.toList());
  }

  Future<void> deleteSelected() async {
    if (_selectedItemIds.isEmpty) return;

    _isDeleting = true;
    notifyListeners();

    final idsToDelete = _selectedItemIds.toList();
    await _gallery.performBatchOptimisticDelete(idsToDelete);

    try {
      final itemsToDelete = await _db.getMediaItemsByIds(_selectedItemIds.toList());
      const int batchSize = 100;

      // on disk deletion batch (100) loop
      for (var i = 0; i < itemsToDelete.length; i += batchSize) {
        final end = (i + batchSize < itemsToDelete.length) ? i + batchSize : itemsToDelete.length;
        final batch = itemsToDelete.sublist(i, end);

        await Future.wait(batch.map((item) async {
          // delete media file
          final sourcePath = item.hashedFileName.startsWith('/')
            ? item.hashedFileName
            : p.join(item.mediaFolderPath, item.hashedFileName);
          
          final file = File(sourcePath);
          // try-catch so that one failed delete doesn't stop the whole batch d
          try {
            if (await file.exists()) {
            await file.delete();
            }
          } catch (e) {
            LogService.e("Failed to delete file: $sourcePath", e);
          }

          // delete thumbnail file
          if (item.thumbnailPath != null && _session.appSupportPath != null) {
            final thumbPath = p.join(_session.appSupportPath!, 'thumbnails', item.thumbnailPath);
            final thumbFile = File(thumbPath);

            try {
              if (await thumbFile.exists()) {
              await thumbFile.delete();
              }
            } catch (e) {
              LogService.e("Failed to delete thumbnail file: $thumbPath", e);
            }
          }
        }));
      }

      final allIds = _selectedItemIds.toList();

      for (var i = 0; i < allIds.length; i += batchSize) {
        final end = (i + batchSize < allIds.length) ? i + batchSize : allIds.length;
        final batchIds = allIds.sublist(i, end);
        await _db.deleteMediaItemsById(batchIds);
      }

      LogService.i('Batch Delete: Successfully deleted ${_selectedItemIds.length} items.');
      await _gallery.fullRefresh(resetScroll: false); // refresh grid
      _gallery.clearAnimatingItems(idsToDelete);

      _selectedItemIds.clear();
      _areAllSelected = false;

      // only close the selection mode card if the media folder is empty
      if (_gallery.totalItemCount == 0) {
        if (_isSelectionMode) toggleSelectionMode();
      } else {
        notifyListeners(); // if items remain, keep the selection mode card open but update UI
      }
    } catch (e) {
      LogService.e("Error executing batch delete");
      _gallery.clearAnimatingItems(idsToDelete);
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
}