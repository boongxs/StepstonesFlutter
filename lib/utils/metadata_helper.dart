import 'dart:convert';
import 'dart:io';
import 'package:image_size_getter/image_size_getter.dart' as isg;
import 'package:image_size_getter/file_input.dart';
import '../services/logger_service.dart';

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

  // images or GIFs (fast)
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
      // fallback for corrupt images
      return const MediaMetadata();
    }
  }

  // video or audio (slow)
  static Future<MediaMetadata> _extractFfprobeMetadata(String path) async {
    try {
      final result = await Process.run(
        "ffprobe", 
        [
          '-v', 'error',
          '-print_format', 'json',
          '-show_format',
          '-show_streams',
          path
        ]
      );

      if (result.exitCode != 0) {
        LogService.e("FFprobe failed on $path (Code ${result.exitCode}): ${result.stderr}");
        return const MediaMetadata();
      }

      final jsonMap = jsonDecode(result.stdout.toString());

      int width = 0;
      int height = 0;
      double durationSec = 0.0;

      // get duration from 'format'
      if (jsonMap.containsKey('format')) {
        final fmt = jsonMap['format'];
        if (fmt.containsKey('duration')) {
          durationSec = double.tryParse(fmt['duration'].toString()) ?? 0.0;
        }
      }

      // get dimensions from video stream
      if (jsonMap.containsKey('streams')) {
        final List streams = jsonMap['streams'];
        // find the first video stream
        final videoStream = streams.firstWhere(
          (s) => s['codec_type'] == 'video',
          orElse: () => null
        );

        if (videoStream != null) {
          width = int.tryParse(videoStream['width'].toString()) ?? 0;
          height = int.tryParse(videoStream['height'].toString()) ?? 0;
        }
      }

      return MediaMetadata(
        width: width,
        height: height,
        durationMs: (durationSec * 1000).toInt(),
      );
    } catch (e) {
      LogService.e("Exception in _extractFfprobeMetadata: $e");
      return const MediaMetadata();
    }
  }
}