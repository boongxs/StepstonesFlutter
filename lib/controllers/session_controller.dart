import 'dart:async';
import 'package:flutter/material.dart';
import '../services/folder_picker_service.dart';
import '../services/settings_service.dart';
import '../locator.dart';
import '../constants.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SessionController extends ChangeNotifier {
  final SettingsService _settingsService = getIt<SettingsService>();
  final FolderPickerService _folderPickerService = getIt<FolderPickerService>();

  final Completer<void> _readyCompleter = Completer();

  /// Completes once [_startup] finishes and [mediaFolderPath] is guaranteed to be set.
  Future<void> get ready => _readyCompleter.future;

  String? _mediaFolderPath;
  String? get mediaFolderPath => _mediaFolderPath;

  String? _appSupportPath;
  String? get appSupportPath => _appSupportPath;

  SessionController() {
    _startup();
  }

  Future<void> _startup() async {
    await initialize();
    notifyListeners();
    _readyCompleter.complete();
  }

  // load previously saved media folder path
  Future<void> initialize() async {
    _appSupportPath = AppConstants.appSupportPath;

    if (Platform.isAndroid || Platform.isIOS) {
      // on mobile: sandbox library into internal app storage, in a subdirectory
      // to avoid the sync controller picking up the SQLite database file
      // (getApplicationDocumentsDirectory and getApplicationSupportDirectory
      // resolve to the same path on Android)
      final dir = await getApplicationDocumentsDirectory();
      _mediaFolderPath = p.join(dir.path, "media");
      await Directory(_mediaFolderPath!).create(recursive: true);
    } else {
      // on desktop: load user-selected folder from settings
      _mediaFolderPath = await _settingsService.loadMediaFolderPath();
    }

    notifyListeners();
  }

  Future<void> selectFolder() async {
    final selectedPath = await _folderPickerService.pickFolder();

    if (selectedPath != null) {
      _mediaFolderPath = selectedPath;
      await _settingsService.saveMediaFolderPath(selectedPath);

      notifyListeners();
    }
  }
}