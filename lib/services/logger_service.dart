import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class LogService {
  static File? _logFile;
  static final ValueNotifier<List<String>> liveLogs = ValueNotifier([]);
  static const int _maxLogLines = 200;

  static Future<void> initialize() async {
    final dir = await getApplicationSupportDirectory();
    final logsDir = Directory(p.join(dir.path, 'logs'));

    // does logs directory exist check
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }

    _logFile = File(p.join(logsDir.path, 'stepstones_log.txt'));
    await _writeLine("\n\n=== SESSION START: ${DateTime.now()} ===\n");
  }

  static void d(String message) => _writeLine('[DEBUG] $message');
  static void i(String message) => _writeLine('[INFO] $message');
  static void w(String message) => _writeLine('[WARN] $message');
  static void e(String message, [Object? error]) => _writeLine('[ERROR] $message ${error ?? ""}');

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