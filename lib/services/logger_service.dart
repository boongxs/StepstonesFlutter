import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'environment_service.dart';

enum LogSeverity { 
  info, 
  warning, 
  error, 
}

class LogService {
  static File? _logFile;
  static final ValueNotifier<List<String>> liveLogs = ValueNotifier([]);

  static final StreamController<LogSeverity> _alertStreamController = StreamController<LogSeverity>.broadcast();
  static Stream<LogSeverity> get alertStream => _alertStreamController.stream; // expose stream so main provider can listen to it 

  static const int _maxLogLines = 200;

  static Future<void> initialize() async {
    final logsDir = Directory(p.join(EnvironmentService.appSupportPath, "logs"));

    // does logs directory exist check
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }

    _logFile = File(p.join(logsDir.path, 'stepstones_log.txt'));
    await _writeLine("\n\n=== SESSION START: ${DateTime.now()} ===\n");
  }

  static void d(String message) => _writeLine('[DEBUG] $message');
  static void i(String message) => _writeLine('[INFO] $message');
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _writeLine("[WARN] $message");
    _alertStreamController.add(LogSeverity.warning);
  }
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _writeLine("[ERROR] $message ${error ?? ""}");
    _alertStreamController.add(LogSeverity.error);
  }

  static Future<void> _writeLine(String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final logLine = '$timestamp $message';

    // update logs view list
    final currentLogs = List<String>.from(liveLogs.value);
    currentLogs.add(logLine);
    if (currentLogs.length > _maxLogLines) {
      currentLogs.removeAt(0);
    }
    liveLogs.value = currentLogs;

    // write to disk
    await _logFile?.writeAsString('$logLine\n', mode: FileMode.append, flush: true);
  }
}