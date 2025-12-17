import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../services/logger_service.dart';

class ThumbnailHelper {
  ThumbnailHelper._();

  static String? _cachedFfmpegPath;

  /// generates a thumbnail (250x250 crop) and returns the filename
  /// returns null if generation fails or audio
  static Future<String?> generateThumbnail({
    required String sourcePath,
    required String fileType,
    required String fileHash,
    required int durationMs,
  }) async {
    try {
      // prepare storage (AppData/thumbnails)
      final appDir = await getApplicationSupportDirectory();
      final thumbDir = Directory(p.join(appDir.path, 'thumbnails'));
      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }

      final thumbFileName = '$fileHash.jpg';
      final thumbFile = File(p.join(thumbDir.path, thumbFileName));

      // skip if thumbnail for file already exists
      if (await thumbFile.exists()) {
        return thumbFileName;
      }

      // generate thumbnail
      if (fileType == 'image' || fileType == 'gif') {
        final success = await _processImage(File(sourcePath), thumbFile);
        return success ? thumbFileName : null;
      }
      else if (fileType == 'video') {
        final success = await _processVideo(sourcePath, thumbFile, durationMs);
        return success ? thumbFileName : null;
      }

      return null; // audio, unknown
    } catch (e) {
      LogService.e("Error generating thumbnail: $e");
      return null;
    }
  }

  // image logic (resize + crop)
  static Future<bool> _processImage(File source, File target) async {
    try {
      final bytes = await source.readAsBytes();

      // load image
      final cmd = img.Command()
        ..decodeImage(bytes)
        ..copyResizeCropSquare(size: 250)
        ..encodeJpg(quality: 75)
        ..writeToFile(target.path);

      await cmd.executeThread(); // run in isolate
      return true;
    } catch (e) {
      LogService.e("Image processing failed: $e");
      return false;
    }
  }

  // video logic (extract frame -> image logic)
  static Future<bool> _processVideo(String sourcePath, File target, int durationMs) async {
    try {
      final ffmpegPath = await _getFfmpegPath();
      if (ffmpegPath == null) return false;

      // calculate 10% timestamp
      int targetMs = (durationMs * 0.10).toInt();

      final timeString = _formatDuration(targetMs); // format as HH:MM:SS.mmm for FFmpeg
      final tempFrame = File('${target.path}.tmp.jpg'); // extract frame to a temp file

      final result = await Process.run(
        ffmpegPath,
        [
          '-y',
          '-ss', timeString,
          '-i', sourcePath,
          '-vframes', '1',
          tempFrame.path
        ]
      );

      if (result.exitCode != 0) {
        LogService.e("FFmpeg Failed (Exit Code ${result.exitCode}): ${result.stderr}");
        return false;
      }

      if (!await tempFrame.exists()) {
        LogService.e("FFmpeg finished but output file is missing.");
        return false;
      }

      // process the temp frame (crop to 250x250)
      final success = await _processImage(tempFrame, target);

      // cleanup temp
      if (await tempFrame.exists()) await tempFrame.delete();

      return success;
    } catch (e) {
      LogService.e("Video processing failed: $e");
      return false;
    }
  }

  static String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String threeDigits(int n) => n.toString().padLeft(3, "0");
    return "${twoDigits(duration.inHours)}:"
      "${twoDigits(duration.inMinutes.remainder(60))}:"
      "${twoDigits(duration.inSeconds.remainder(60))}."
      "${threeDigits(duration.inMilliseconds.remainder(1000))}";
  }

  static Future<String?> _getFfmpegPath() async {
    if (_cachedFfmpegPath != null && await File(_cachedFfmpegPath!).exists()) {
      return _cachedFfmpegPath;
    }
    try {
      final dir = await getApplicationSupportDirectory();
      final targetPath = p.join(dir.path, 'ffmpeg.exe');
      final targetFile = File(targetPath);

      if (!await targetFile.exists()) {
        LogService.i("Extracting ffmpeg...");
        final byteData = await rootBundle.load('assets/bin/ffmpeg.exe');
        final buffer = byteData.buffer.asUint8List();
        await targetFile.writeAsBytes(buffer, flush: true);
        if (!Platform.isWindows) await Process.run('chmod', ['+x', targetPath]);
      }
      _cachedFfmpegPath = targetPath;
      return targetPath;
    } catch (e) {
      LogService.e("Failed to extract ffmpeg: $e");
      return null;
    }
  }
}