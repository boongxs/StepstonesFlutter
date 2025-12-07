import 'package:flutter/foundation.dart';
import '../services/folder_picker_service.dart';
import '../services/settings_service.dart';
import '../services/logger_service.dart';

class MainProvider extends ChangeNotifier {
  final FolderPickerService _folderPickerService;
  final SettingsService _settingsService;

  String? _mediaFolderPath;
  String? get mediaFolderPath => _mediaFolderPath;

  MainProvider(this._folderPickerService, this._settingsService);

  // load saved settings when app starts
  Future<void> initialize() async {
    _mediaFolderPath = await _settingsService.loadMediaFolderPath();
    if (_mediaFolderPath != null) {
      notifyListeners();
    }
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