import 'package:flutter/material.dart';
import '../services/folder_picker_service.dart';
import '../services/settings_service.dart';
import '../locator.dart';
import 'package:disk_space_2/disk_space_2.dart';
import '../services/logger_service.dart';
import '../constants.dart';

class SessionController extends ChangeNotifier {
  final SettingsService _settingsService = getIt<SettingsService>();
  final FolderPickerService _folderPickerService = getIt<FolderPickerService>();

  String? _mediaFolderPath;
  String? get mediaFolderPath => _mediaFolderPath;

  String? _appSupportPath;
  String? get appSupportPath => _appSupportPath;

  double _freeSpaceMB = 0.0;

  double get freeSpaceMB => _freeSpaceMB;

  SessionController() {
    _startup();
  }

  Future<void> _startup() async {
    await initialize();
    updateDiskSpace();

    notifyListeners();
  }

  // load previously saved media folder path
  Future<void> initialize() async {
    _appSupportPath = AppConstants.appSupportPath;

    // store media folder path
    _mediaFolderPath = await _settingsService.loadMediaFolderPath();

    notifyListeners();
  }

  Future<void> selectFolder() async {
    final selectedPath = await _folderPickerService.pickFolder();

    if (selectedPath != null) {
      _mediaFolderPath = selectedPath;
      await _settingsService.saveMediaFolderPath(selectedPath);

      updateDiskSpace();
      notifyListeners();
    }
  }

    // update storage status bar
  Future<void> updateDiskSpace() async {
    final folderPath = mediaFolderPath;
    if (folderPath == null) return;

    try {
      final free = await DiskSpace.getFreeDiskSpaceForPath(folderPath);

      if (free != null) {
        _freeSpaceMB = free;
        notifyListeners();
      }
    } catch (e) {
      LogService.w("Could not read disk space for UI: $e");
    }
  }
}