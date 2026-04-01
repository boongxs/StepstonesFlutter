import 'dart:convert';
import 'dart:io';
import '../utils/metadata_helper.dart';
import 'logger_service.dart';
import 'media_utility_service.dart';

class DesktopMediaUtilityService implements MediaUtilityService {
  @override
  Future<MediaMetadata> extractVideoMetadata(String path) async {
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

      return _parseFfprobeJson(result.stdout.toString());
    } catch (e) {
      LogService.e("Exception in Desktop extractVideoMetadata: $e");
      return const MediaMetadata();
    }
  }

  @override
  Future<bool> extractVideoFrame(String sourcePath, String tempFramePath, int durationMs) async {
    try {
      int targetMs = (durationMs * 0.10).toInt();
      final timeString = _formatDuration(targetMs);

      final result = await Process.run(
        "ffmpeg",
        [
          '-y',
          '-ss', timeString,
          '-i', sourcePath,
          '-vframes', '1',
          tempFramePath
        ]
      );

      if (result.exitCode != 0) {
        LogService.e("FFmpeg Failed (Exit Code ${result.exitCode}): ${result.stderr}");
        return false;
      }

      return await File(tempFramePath).exists();
    } catch (e) {
      LogService.e("Desktop Video frame extraction failed: $e");
      return false;
    }
  }

  // helper to parse JSON output
  MediaMetadata _parseFfprobeJson(String jsonString) {
    try {
      final jsonMap = jsonDecode(jsonString);
      int width = 0;
      int height = 0;
      double durationSec = 0.0;

      if (jsonMap.containsKey('format')) {
        final fmt = jsonMap['format'];
        if (fmt.containsKey('duration')) {
          durationSec = double.tryParse(fmt['duration'].toString()) ?? 0.0;
        }
      }

      if (jsonMap.containsKey('streams')) {
        final List streams = jsonMap['streams'];
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
      return const MediaMetadata();
    }
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String threeDigits(int n) => n.toString().padLeft(3, "0");

    return "${twoDigits(duration.inHours)}:"
      "${twoDigits(duration.inMinutes.remainder(60))}:"
      "${twoDigits(duration.inSeconds.remainder(60))}."
      "${threeDigits(duration.inMilliseconds.remainder(1000))}";
  }
}