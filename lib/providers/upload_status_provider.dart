import 'package:flutter/foundation.dart';

class UploadStatusProvider extends ChangeNotifier
{
  // UI state
  bool _isVisible = false;
  bool _isExpanded = false;

  bool get isVisible => _isVisible;
  bool get isExpanded => _isExpanded;

  // Data State
  String _statusTitle = "";
  String _currentFileName = "";
  double _currentFileProgress = 0.0;

  // Stats
  int _totalFilesToUpload = 0;
  int _filesProcessed = 0;
  int _duplicateCount = 0;
  int _failCount = 0;

  // Getters
  String get statusTitle => _statusTitle;
  String get currentFileName => _currentFileName;
  double get currentFileProgress => _currentFileProgress;

  String get summarySuccess => "$_filesProcessed successful";
  String get summaryDuplicates => "$_duplicateCount duplicates";
  String get summaryFailed => "$_failCount failed";

  void startUpload(int newFilesCount) {
    if (!_isVisible) { // new session logic
      _filesProcessed = 0;
      _duplicateCount = 0;
      _failCount = 0;
      _totalFilesToUpload = 0;
      _currentFileProgress = 0.0;
      _statusTitle = "Preparing upload...";
    }

    _isVisible = true;
    _isExpanded = false;
    _totalFilesToUpload += newFilesCount;

    if (currentFileName.isNotEmpty) {
      int totalProcessedSoFar = _filesProcessed + _duplicateCount + _failCount;
      int currentGlobalIndex = totalProcessedSoFar + 1;
      _statusTitle = "Processing $currentGlobalIndex of $_totalFilesToUpload";
    }
    
    notifyListeners();
  }

  void updateCurrentFile(String fileName, int index) {
    _currentFileName = fileName;
    _currentFileProgress = 0.0;

    int totalProcessedSoFar = _filesProcessed + _duplicateCount + _failCount;
    int currentGlobalIndex = totalProcessedSoFar + 1;

    _statusTitle = "Processing $currentGlobalIndex of $_totalFilesToUpload"; 
    notifyListeners();
  }

  void updateProgress(double percent) {
    _currentFileProgress = percent;
    notifyListeners();
  }

  void completeFile() {
    _filesProcessed++;
    _currentFileProgress = 1.0;
    notifyListeners();
  }

  void markDuplicate() {
    _duplicateCount++;
    _currentFileProgress = 1.0;
    notifyListeners();
  }

  void markFailed() {
    _failCount++;
    _currentFileProgress = 1.0;
    notifyListeners();
  }

  void finishUpload() {
    _statusTitle = "Upload complete";
    _currentFileName = "";
    _isExpanded = true;
    notifyListeners();
  }

  void toggleExpanded() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  void close() {
    _isVisible = false;
    notifyListeners();
  }
}