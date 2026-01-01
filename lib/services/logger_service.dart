import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LogService {
  static File? _logFile;

  static Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    final logsDir = Directory(p.join(dir.path, 'logs'));

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

    await _logFile?.writeAsString('$logLine\n', mode: FileMode.append, flush: true);
  }
}