import 'package:flutter/material.dart';
import '../locator.dart';
import '../data/app_database.dart';
import '../controllers/session_controller.dart';
import '../controllers/gallery_controller.dart';
import '../controllers/sync_controller.dart';
import '../controllers/selection_controller.dart';

class MainProvider extends ChangeNotifier {
  late final SessionController session;
  late final GalleryController gallery;
  late final SyncController sync;
  late final SelectionController selection;

  String? _previousPath;

  MainProvider() {
    final db = getIt<AppDatabase>();

    session = SessionController();
    gallery = GalleryController(db, session);
    sync = SyncController(db, session, gallery);
    selection = SelectionController(db, session, gallery);

    session.addListener(() {
      // is current media folder path different from previously saved?
      if (session.mediaFolderPath != _previousPath) {
        // if yes, re-sync current media folder
        _previousPath = session.mediaFolderPath;

        if (session.mediaFolderPath != null) {
          sync.performFullSync();
        }
      }
      
      notifyListeners();
    });
    gallery.addListener(notifyListeners);
    sync.addListener(notifyListeners);
    selection.addListener(notifyListeners);
  }

  // load previously saved media folder path
  Future<void> initialize() async {
    await session.initialize();
  }

  @override
  void dispose() {
    session.removeListener(notifyListeners);
    gallery.removeListener(notifyListeners);
    sync.removeListener(notifyListeners);
    selection.removeListener(notifyListeners);

    session.dispose();
    gallery.dispose();
    sync.dispose();
    selection.dispose();

    super.dispose();
  }
}