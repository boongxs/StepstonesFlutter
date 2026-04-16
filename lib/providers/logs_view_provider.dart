import 'dart:async';
import 'package:flutter/material.dart';
import '../services/logger_service.dart';

class LogsViewProvider extends ChangeNotifier {
  bool _isShowingLogs = false;
  bool get isShowingLogs => _isShowingLogs;

  int _unseenWarningCount = 0;
  int _unseenErrorCount = 0;
  StreamSubscription? _logSubscription;

  int get unseenLogCount => _unseenWarningCount + _unseenErrorCount;
  bool get hasUnseenLogs => unseenLogCount > 0;
  Color get logBadgeColor => _unseenErrorCount > 0 ? Colors.red : Colors.orange;

  int _lastSeenLogCount = 0;
  int get lastSeenLogCount => _lastSeenLogCount;

  LogsViewProvider() {
    _logSubscription = LogService.alertStream.listen((severity) {
      if (isShowingLogs) return;

      if (severity == LogSeverity.error) {
        _unseenErrorCount++;
      } else if (severity == LogSeverity.warning) {
        _unseenWarningCount++;
      }

      notifyListeners();
    });
  }

  void setLogsVisible(bool visible) {
    _isShowingLogs = visible;
    if (visible) {
      _unseenWarningCount = 0;
      _unseenErrorCount = 0;
    } else {
      _lastSeenLogCount = LogService.liveLogs.value.length;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    super.dispose();
  }
}