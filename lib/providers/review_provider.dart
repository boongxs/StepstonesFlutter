import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../constants.dart';
import '../data/app_database.dart';
import '../controllers/gallery_controller.dart';
import '../services/logger_service.dart';

class ReviewProvider extends ChangeNotifier {
  final AppDatabase _db;
  final GalleryController _gallery;
  StreamSubscription<List<PendingReview>>? _subscription;

  ReviewProvider(this._db, this._gallery) {
    // Watch the pending_reviews table reactively — any insert, delete, or
    // cascade delete automatically updates the review queue and notifies listeners.
    _subscription = _db.watchPendingReviews().listen((reviews) async {
      _reviews = reviews;
      await _loadCurrentItems();
      notifyListeners();
    });
  }

  List<PendingReview> _reviews = [];
  MediaItem? _uploadedItem;
  MediaItem? _matchedItem;

  int get pendingCount => _reviews.length;
  bool get hasPendingReviews => _reviews.isNotEmpty;

  PendingReview? get currentReview => _reviews.isNotEmpty ? _reviews.first : null;
  MediaItem? get uploadedItem => _uploadedItem;
  MediaItem? get matchedItem => _matchedItem;

  String? get uploadedThumbnailPath => _thumbnailPath(_uploadedItem);
  String? get matchedThumbnailPath => _thumbnailPath(_matchedItem);

  String? _thumbnailPath(MediaItem? item) {
    if (item == null || item.thumbnailPath == null) return null;
    return p.join(AppConstants.appSupportPath, AppConstants.thumbnailDirectory, item.thumbnailPath!);
  }

  Future<void> _loadCurrentItems() async {
    final review = currentReview;
    if (review == null) {
      _uploadedItem = null;
      _matchedItem = null;
      return;
    }

    final items = await _db.getMediaItemsByIds([review.uploadedItemId, review.matchedItemId]);
    _uploadedItem = items.where((i) => i.id == review.uploadedItemId).firstOrNull;
    _matchedItem  = items.where((i) => i.id == review.matchedItemId).firstOrNull;
  }

  // Keep: dismiss this single review pair, both files stay.
  // The stream fires automatically after the delete and advances to the next entry.
  Future<void> keep() async {
    final review = currentReview;
    if (review == null) return;

    await _db.deletePendingReview(review.id);
    LogService.i("Review kept: uploaded=${_uploadedItem?.hashedFileName}, matched=${_matchedItem?.hashedFileName}");
  }

  // Discard: delete the uploaded file from disk, thumbnail, and DB.
  // The cascade delete on pending_reviews triggers the stream automatically.
  Future<void> discard() async {
    final review = currentReview;
    final uploaded = _uploadedItem;
    if (review == null || uploaded == null) return;

    // delete file from disk
    final filePath = p.join(uploaded.mediaFolderPath, uploaded.hashedFileName);
    final file = File(filePath);
    if (await file.exists()) await file.delete();

    // delete thumbnail from disk
    final thumbPath = _thumbnailPath(uploaded);
    if (thumbPath != null) {
      final thumb = File(thumbPath);
      if (await thumb.exists()) await thumb.delete();
    }

    // delete from DB — cascade deletes mediaTags and all pendingReviews referencing this item,
    // which triggers the watch stream to update the review queue automatically
    await _db.deleteMediaItemsById([uploaded.id]);

    LogService.i("Review discarded: deleted uploaded file ${uploaded.hashedFileName}");

    // refresh gallery so the deleted item disappears from the grid
    await _gallery.fullRefresh(resetScroll: false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}