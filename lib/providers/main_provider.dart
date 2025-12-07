import 'package:flutter/foundation.dart';
import '../services/folder_picker_service.dart';
import '../services/settings_service.dart';
import '../services/logger_service.dart';
import '../services/file_picker_service.dart';
import '../services/file_service.dart';

class MainProvider extends ChangeNotifier {
  final FolderPickerService _folderPickerService;
  final SettingsService _settingsService;
  final FilePickerService _filePickerService;
  final FileService _fileService;

  String? _mediaFolderPath;
  String? get mediaFolderPath => _mediaFolderPath;

  MainProvider(
    this._folderPickerService, 
    this._settingsService,
    this._filePickerService,
    this._fileService,
  );

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

  Future<void> uploadFiles() async {
    // check if folder is selected
    if (_mediaFolderPath == null) {
      LogService.w('No media folder selected. Cannot upload files.');
      return;
    }

    // pick files to upload
    final files = await _filePickerService.pickMediaFiles();
    if (files == null || files.isEmpty) return;

    LogService.i('Starting upload of ${files.length} files...');
    await _fileService.copyFiles(files, _mediaFolderPath!);
    LogService.i('File upload completed.');
  }
}