import 'dart:io';
import 'package:mime/mime.dart';

class MediaHelper {
  MediaHelper._();

  /// reads the file header to determine file type
  /// returns 'image', 'video', 'audio', 'gif', or 'unknown'
  static Future<String> inferFileType(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return 'unknown';

      // reads the first 12 bytes
      final List<int> headerBytes = await file.openRead(0, 12).first;

      // identify type based on header + extension
      final mimeType = lookupMimeType(path, headerBytes: headerBytes);

      if (mimeType == null) return 'unknown';
      if (mimeType == 'image/gif') {
        return 'gif';
      } else if (mimeType.startsWith('image/')) {
        return 'image';
      } else if (mimeType.startsWith('video/')) {
        return 'video';
      } else if (mimeType.startsWith('audio/')) {
        return 'audio';
      }

      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }
}