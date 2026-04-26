import 'dart:io';
import 'package:image_size_getter/image_size_getter.dart' as isg;
import 'package:image_size_getter/file_input.dart';
import '../services/logger_service.dart';
import '../locator.dart';
import '../services/desktop_media_utility_service.dart';

class MediaMetadata {
  final int width;
  final int height;
  final int durationMs;

  const MediaMetadata({
    this.width = 0,
    this.height = 0,
    this.durationMs = 0,
  });
}

class MetadataHelper {
  MetadataHelper._();

  // main entry point
  static Future<MediaMetadata> extractMetadata(String filePath, String fileType) async {
    try {
      if (fileType == 'image' || fileType == 'gif') {
        return _extractImageMetadata(filePath);
      } else if (fileType == 'video' || fileType == 'audio') {
        return await _extractFfprobeMetadata(filePath);
      }
    } catch (e) {
      LogService.e("Error extracting metadata for $filePath: $e");
    }

    // return empty defaults on failure or unknown type
    return const MediaMetadata();
  }

  // images or GIFs
  static Future<MediaMetadata> _extractImageMetadata(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return const MediaMetadata();

      // read only the header bytes for info
      final size = isg.ImageSizeGetter.getSizeResult(FileInput(file)).size;

      return MediaMetadata(
        width: size.width,
        height: size.height,
        durationMs: 0,
      );
    } catch (e) {
      LogService.i("Failed to get image metadata for $path. Attempting with FFProbe...");

      final fallbackData = await _extractFfprobeMetadata(path);

      // fallback for corrupt images
      return MediaMetadata(
        width: fallbackData.width,
        height: fallbackData.height,
        durationMs: 0,
      );
    }
  }

  // video or audio
  static Future<MediaMetadata> _extractFfprobeMetadata(String path) async {
    final utilityService = getIt<MediaUtilityService>();
    
    return await utilityService.extractVideoMetadata(path);
  }
}