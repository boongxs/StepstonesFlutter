import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../services/logger_service.dart';
import '../services/environment_service.dart';

class _ThumbnailRequest {
  final String sourcePath;
  final String destinationPath;
  final bool isTransparent;
  final int size;

  _ThumbnailRequest({
    required this.sourcePath,
    required this.destinationPath,
    required this.isTransparent,
    required this.size,
  });
}

Future<bool> _generateImageInIsolate(_ThumbnailRequest request) async {
  try {
    final sourceFile = File(request.sourcePath);
    final bytes = await sourceFile.readAsBytes();

    // decode image
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return false;

    // handle GIF files
    img.Image singleFrame = decoded;
    if (decoded.numFrames > 1) {
      singleFrame = decoded.frames[0];
    }

    // resize and crop
    final resized = img.copyResizeCropSquare(singleFrame, size: request.size);

    // encode
    List<int> encodedBytes;
    if (request.isTransparent) {
      encodedBytes = img.encodePng(resized, singleFrame: true);
    } else {
      encodedBytes = img.encodeJpg(resized, quality: 75);
    }

    // write to disk
    await File(request.destinationPath).writeAsBytes(encodedBytes);
    return true;
  } catch (e) {
    debugPrint("Isolate Image processing failed: $e");
    return false;
  }
}

class ThumbnailHelper {
  ThumbnailHelper._();

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
      final appDir = EnvironmentService.appSupportPath;
      final thumbDir = Directory(p.join(appDir, "thumbnails"));
      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }

      // determine output format
      final ext = p.extension(sourcePath).toLowerCase();
      final isTransparent = [".png", ".gif", ".webp"].contains(ext);
      final targetExt = isTransparent ? ".png" : ".jpg"; // use .png extension if we need transparency, otherwise .jpg
      final thumbFileName = '$fileHash$targetExt';
      final thumbFile = File(p.join(thumbDir.path, thumbFileName));

      // skip if thumbnail for file already exists
      if (await thumbFile.exists()) {
        return thumbFileName;
      }

      // generate thumbnail
      if (fileType == "image" || fileType == "gif") {
        final request = _ThumbnailRequest(
          sourcePath: sourcePath, 
          destinationPath: thumbFile.path, 
          isTransparent: isTransparent, 
          size: 250,
        );

        final success = await compute(_generateImageInIsolate, request);
        return success ? thumbFileName : null;
      }
      else if (fileType == "video") {
        final success = await _processVideo(sourcePath, thumbFile, durationMs);
        return success ? thumbFileName : null;
      }

      return null; // audio, unknown
    } catch (e) {
      LogService.e("Error generating thumbnail: $e");
      return null;
    }
  }

  // video logic (extract frame -> image logic)
  static Future<bool> _processVideo(String sourcePath, File target, int durationMs) async {
    try {
      final ffmpegPath = EnvironmentService.ffmpegPath;

      // calculate 10% timestamp
      int targetMs = (durationMs * 0.10).toInt();

      final timeString = _formatDuration(targetMs); // format as HH:MM:SS.mmm for FFmpeg
      final tempFrame = File("${target.path}.tmp.jpg"); // extract frame to a temp file

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

      final request = _ThumbnailRequest(
        sourcePath: tempFrame.path, 
        destinationPath: target.path, 
        isTransparent: false, 
        size: 250,
      );

      // process the temp frame (crop to 250x250)
      final success = await compute(_generateImageInIsolate, request);

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
}