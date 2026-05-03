import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../services/logger_service.dart';
import '../constants.dart';
import '../locator.dart';
import '../services/media_utility_service.dart';

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

    // resize and crop
    final resized = img.copyResizeCropSquare(decoded, size: request.size);

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
      final appDir = AppConstants.appSupportPath;
      final thumbDir = Directory(p.join(appDir, AppConstants.thumbnailDirectory));
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
      if (fileType == "image") {
        final request = _ThumbnailRequest(
          sourcePath: sourcePath,
          destinationPath: thumbFile.path,
          isTransparent: isTransparent,
          size: 250,
        );

        final success = await compute(_generateImageInIsolate, request);
        return success ? thumbFileName : null;
      }
      else if (fileType == "video" || fileType == "gif") {
        final success = await _processVideo(sourcePath, thumbFile, durationMs);
        return success ? thumbFileName : null;
      }

      return null; // audio, unknown
    } catch (e) {
      LogService.e("Error generating thumbnail: $e");
      return null;
    }
  }

  // video/gif logic (single-pass ffmpeg extract, scale, and crop)
  static Future<bool> _processVideo(String sourcePath, File target, int durationMs) async {
    try {
      final utilityService = getIt<MediaUtilityService>();
      return await utilityService.generateVideoThumbnail(sourcePath, target.path, durationMs);
    } catch (e) {
      LogService.e("Video thumbnail generation failed: $e");
      return false;
    }
  }
}