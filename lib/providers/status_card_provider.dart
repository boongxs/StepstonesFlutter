import 'dart:async';
import 'package:flutter/material.dart';

class StatusCardProvider extends ChangeNotifier {
  // UI state
  bool _isVisible = false;
  bool get isVisible => _isVisible;

  String _title = "";
  String get title => _title;

  String _subtitle = "";
  String get subtitle => _subtitle;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Timer? _hideTimer;

  /// starts a new job. show card and spinner
  void startJob(String title) {
    _hideTimer?.cancel();
    _isVisible = true;
    _isLoading = true;
    _title = title;
    _subtitle = "Initializing...";
    notifyListeners();
  }

  /// updates the subtitle text (e.g. current filename)
  void updateProgress(String subtitle) {
    _subtitle = subtitle;
    notifyListeners();
  }

  /// finishes the job. stop spinner, update title text, and auto-hide after 2 seconds
  void finishJob(String completionMessage, {bool isError = false}) {
    _isLoading = false;
    _title = completionMessage;
    _subtitle = ""; // clear subtitle on finish
    notifyListeners();

    // auto-hide after 2 seconds
    _hideTimer = Timer(const Duration(seconds: 2), () {
      _isVisible = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}