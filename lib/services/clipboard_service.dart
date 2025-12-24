import 'dart:io';
import 'package:super_clipboard/super_clipboard.dart';
import 'logger_service.dart';

class ClipboardService {
  ClipboardService._();

  /// Copies a single file to the system clipboard
  /// returns true if successful, false otherwise
  static Future<bool> copyFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        LogService.e("Attempted to copy non-existent file: $filePath");
        return false;
      }
      
      final item = DataWriterItem();
      item.add(Formats.fileUri(file.uri));
      await SystemClipboard.instance?.write([item]);

      LogService.i("Copied file to clipboard: $filePath");
      return true;
    } catch (e) {
      LogService.e("Clipboard copy failed: $e");
      return false;
    }
  }
}