import 'dart:convert';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../utils/metadata_helper.dart';
import 'logger_service.dart';
import 'media_utility_service.dart';

class AndroidMediaUtilityService implements MediaUtilityService {
  @override
  Future<MediaMetadata> extractVideoMetadata(String path) async {
    try {
      final session = await FFprobeKit.executeWithArguments([
        '-v', 'error',
        '-print_format', 'json',
        '-show_format',
        '-show_streams',
        path
      ]);

      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final output = await session.getOutput();
        return _parseFfprobeJson(output ?? "{}");
      } else {
        final failStackTrace = await session.getFailStackTrace();
        LogService.e("Android FFprobe failed on $path: $failStackTrace");
        return const MediaMetadata();
      }
    } catch (e) {
      LogService.e("Exception in Android extractVideoMetadata: $e");
      return const MediaMetadata();
    }
  }

  @override
  Future<bool> extractVideoFrame(String sourcePath, String tempFramePath, int durationMs) async {
    try {
      int targetMs = (durationMs * 0.10).toInt();
      final timeString = _formatDuration(targetMs);

      final session = await FFmpegKit.executeWithArguments([
        '-y',
        '-ss', timeString,
        '-i', sourcePath,
        '-vframes', '1',
        tempFramePath
      ]);

      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return await File(tempFramePath).exists();
      } else {
        final failStackTrace = await session.getFailStackTrace();
        LogService.e("Android FFmpeg Failed: $failStackTrace");
        return false;
      }
    } catch (e) {
      LogService.e("Android Video frame extraction failed: $e");
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
        durationMs: (durationSec * 1000).toInt()
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