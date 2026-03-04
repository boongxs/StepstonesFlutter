import 'package:flutter/material.dart';
import '../locator.dart';
import '../data/app_database.dart';
import '../controllers/session_controller.dart';
import '../controllers/gallery_controller.dart';
import '../controllers/sync_controller.dart';
import '../controllers/selection_controller.dart';
import 'status_card_provider.dart';

class MainProvider extends ChangeNotifier {
  late final SessionController session;
  late final GalleryController gallery;
  late final SyncController sync;
  late final SelectionController selection;
  late final StatusCardProvider status;

  String? _previousPath;

  bool _isShowingLogs = false;
  bool get isShowingLogs => _isShowingLogs;

  void toggleLogsView() {
    _isShowingLogs = !_isShowingLogs;
    notifyListeners();
  }

  MainProvider() {
    final db = getIt<AppDatabase>();

    session = SessionController();
    gallery = GalleryController(db, session);
    status = StatusCardProvider();
    sync = SyncController(db, session, gallery, status);
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
    status.addListener(notifyListeners);
    sync.addListener(notifyListeners);
    selection.addListener(notifyListeners);
  }

  // load previously saved media folder path
  Future<void> initialize() async {
    await session.initialize();
    session.updateDiskSpace();
  }

  @override
  void dispose() {
    session.removeListener(notifyListeners);
    gallery.removeListener(notifyListeners);
    status.removeListener(notifyListeners);
    sync.removeListener(notifyListeners);
    selection.removeListener(notifyListeners);

    session.dispose();
    gallery.dispose();
    status.dispose();
    sync.dispose();
    selection.dispose();

    super.dispose();
  }
}