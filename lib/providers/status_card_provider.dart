import 'dart:async';
import 'package:flutter/foundation.dart';

class StatusCardProvider extends ChangeNotifier {
  String _title = "";
  String _subtitle = "";
  bool _isLoading = false;
  bool _isError = false;
  bool _isVisible = false;
  Timer? _hideTimer;

  String get title => _title;
  String get subtitle => _subtitle;
  bool get isLoading => _isLoading;
  bool get isError => _isError;
  bool get isVisible => _isVisible;

  void startJob(String title) {
    _hideTimer?.cancel();
    _title = title;
    _subtitle = "";
    _isLoading = true;
    _isError = false;
    _isVisible = true;
    notifyListeners();
  }

  void updateTitle(String title) {
    _title = title;
    notifyListeners();
  }

  void updateSubtitle(String subtitle) {
    _subtitle = subtitle;
    notifyListeners();
  }

  void finishJob(String completionMessage, {bool isError = false}) {
    _hideTimer?.cancel();
    _title = completionMessage;
    _subtitle = "";
    _isLoading = false;
    _isError = isError;
    notifyListeners();

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
