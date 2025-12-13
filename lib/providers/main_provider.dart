import 'package:flutter/foundation.dart';
import '../services/folder_picker_service.dart';
import '../services/settings_service.dart';
import '../services/logger_service.dart';
import '../services/file_picker_service.dart';
import '../services/file_service.dart';
import 'upload_status_provider.dart';
import '../locator.dart';
import 'package:path/path.dart' as p;

class MainProvider extends ChangeNotifier {
  final FolderPickerService _folderPickerService;
  final SettingsService _settingsService;
  final FilePickerService _filePickerService;
  final FileService _fileService;

  String? _mediaFolderPath;
  String? get mediaFolderPath => _mediaFolderPath;

  int _totalItemCount = 0;
  int get totalItemCount => _totalItemCount;

  final List<String> _uploadQueue = [];
  bool _isUploading = false;

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
      await refreshFileCount();
      notifyListeners();
    }
  }

  Future<void> selectFolder() async {
    final selectedPath = await _folderPickerService.pickFolder();

    if (selectedPath != null) {
      _mediaFolderPath = selectedPath;
      await _settingsService.saveMediaFolderPath(selectedPath);
      await refreshFileCount();
      notifyListeners();
    }
  }

  Future<void> uploadFiles() async {
    // check if folder is selected
    if (_mediaFolderPath == null) {
      LogService.w('No media folder selected. Cannot upload files.');
      return;
    }

    // 1. pick files to upload
    final files = await _filePickerService.pickMediaFiles();
    if (files == null || files.isEmpty) return;

    // 2. add to queue
    _uploadQueue.addAll(files);
    LogService.i('Added ${files.length} files to queue. Total pending: ${_uploadQueue.length}');

    // 3. update total count in UI immediately
    final statusProvider = getIt<UploadStatusProvider>();
    statusProvider.startUpload(files.length);

    if (!_isUploading) {
      _processUploadQueue();
    }
  }

  Future<void> refreshFileCount() async 
  {
    if (_mediaFolderPath != null) 
    {
      _totalItemCount = await _fileService.getFileCount(_mediaFolderPath!);
    } 
    else 
    {
      _totalItemCount = 0;
    }

    notifyListeners();
  }

  /// serialized loop to process files one by one until the queue is empty
  Future<void> _processUploadQueue() async {
    _isUploading = true;
    final statusProvider = getIt<UploadStatusProvider>();

    // keep looping as long as there are files in the queue
    while (_uploadQueue.isNotEmpty) {
      final sourcePath = _uploadQueue.removeAt(0);
      final fileName = p.basename(sourcePath);

      statusProvider.updateCurrentFile(fileName, 0);

      // copy logic
      final result = await _fileService.copyFileWithProgress(
        sourcePath,
        _mediaFolderPath!,
        (percent) {
          statusProvider.updateProgress(percent);
        }
      );

      switch (result) {
        case CopyResult.success:
          statusProvider.completeFile();
          break;
        case CopyResult.duplicate:
          statusProvider.markDuplicate();
          break;
        case CopyResult.failure:
          statusProvider.markFailed();
          break;
      }
    }

    // only when queue is empty we finish
    await refreshFileCount();
    statusProvider.finishUpload();
    _isUploading = false;

    LogService.i('Queue empty. Upload batch complete.');
    notifyListeners();
  }
}