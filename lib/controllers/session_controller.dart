import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/folder_picker_service.dart';
import '../services/settings_service.dart';
import '../locator.dart';

class SessionController extends ChangeNotifier {
  final SettingsService _settingsService = getIt<SettingsService>();
  final FolderPickerService _folderPickerService = getIt<FolderPickerService>();

  String? _mediaFolderPath;
  String? get mediaFolderPath => _mediaFolderPath;

  String? _appSupportPath;
  String? get appSupportPath => _appSupportPath;

  // load previously saved media folder path
  Future<void> initialize() async {
    // store appdata path
    final dir = await getApplicationSupportDirectory();
    _appSupportPath = dir.path;

    // store media folder path
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