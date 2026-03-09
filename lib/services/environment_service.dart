import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'logger_service.dart';

class EnvironmentService {
  static late final String appSupportPath;
  static late final String ffmpegPath;
  static late final String ffprobePath;

  static Future<void> initialize() async {
    try {
      final dir = await getApplicationSupportDirectory();
      appSupportPath = dir.path;

      // extract both required binaries eagerly
      ffmpegPath = await _extractBinary("ffmpeg.exe");
      ffprobePath = await _extractBinary("ffprobe.exe");

      LogService.i("Environment initialized successfully.");
    } catch (e) {
      LogService.e("Failed to initialize binaries: $e");
    }
  }

  static Future<String> _extractBinary(String filename) async {
    final targetPath = p.join(appSupportPath, filename);
    final targetFile = File(targetPath);

    // only extract if it doesn't already exist
    if (!await targetFile.exists()) {
      LogService.i("Extracting $filename to $targetPath...");

      final byteData = await rootBundle.load("assets/bin/$filename");
      await targetFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    }

    return targetPath;
  }
}