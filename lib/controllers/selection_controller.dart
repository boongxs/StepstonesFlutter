import 'package:flutter/material.dart';
import '../data/app_database.dart';
import 'session_controller.dart';
import 'gallery_controller.dart';
import '../services/logger_service.dart';
import '../services/media_action_service.dart';
import '../utils/snackbar_helper.dart';

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
        final allIds = await _db.getAllIdsInFolder(
          _session.mediaFolderPath!,
          searchQuery: _gallery.currentSearchQuery,
        );
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

    try {
      // get media item data from database
      final itemsToDelete = await _db.getMediaItemsByIds(_selectedItemIds.toList());

      // perform delete
      final success = await _gallery.deleteItems(itemsToDelete);

      // show feedback
      MediaActionService.rootMessengerKey.currentState?.showStepstonesSnackBar(
        success
          ? "Successfully deleted ${itemsToDelete.length} item${itemsToDelete.length == 1 ? '' : 's'}"
          : "Failed to delete selected items",
        isError: !success,
      );

      // cleanup selection state
      _selectedItemIds.clear();
      _areAllSelected = false;

      // only close the selection mode card if the media folder is empty
      if (_gallery.totalItemCount == 0) {
        if (_isSelectionMode) toggleSelectionMode();
      }
    } catch (e) {
      LogService.e("Error executing batch delete");
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
}