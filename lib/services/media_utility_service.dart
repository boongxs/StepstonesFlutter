import '../utils/metadata_helper.dart';

abstract class MediaUtilityService {
  /// Extracts dimensions and duration from a media file
  Future<MediaMetadata> extractVideoMetadata(String path);

  /// Extracts single frame from a video at 10% mark and saves it to [tempFramePath]
  Future<bool> extractVideoFrame(String sourcePath, String tempFramePath, int durationMs);
}