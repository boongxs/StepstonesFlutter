import 'package:flutter/material.dart';
import '../services/folder_picker_service.dart';
import '../services/settings_service.dart';
import '../locator.dart';
import '../constants.dart';

class SessionController extends ChangeNotifier {
  final SettingsService _settingsService = getIt<SettingsService>();
  final FolderPickerService _folderPickerService = getIt<FolderPickerService>();

  String? _mediaFolderPath;
  String? get mediaFolderPath => _mediaFolderPath;

  late String _appSupportPath;
  String get appSupportPath => _appSupportPath;

  SessionController() {
    initialize();
  }

  // load previously saved media folder path
  Future<void> initialize() async {
    _appSupportPath = AppConstants.appSupportPath;

    _mediaFolderPath = await _settingsService.loadMediaFolderPath();

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