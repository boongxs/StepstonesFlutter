import 'dart:io';
import 'package:path/path.dart' as p;
import 'logger_service.dart';

class FileService {
  // copies a list of files to destination folder
  Future<void> copyFiles(List<String> sourcePaths, String destFolder) async {
    for (var sourcePath in sourcePaths) {
      try {
        final fileName = p.basename(sourcePath);
        final destPath = p.join(destFolder, fileName);

        // check to prevent crash if file exists in destination folder
        if (await File(destPath).exists()) {
          LogService.w('Skipping $fileName: File already exists in destination.');
          continue;
        }

        await File(sourcePath).copy(destPath);
        LogService.i('Copied $fileName');
      } catch (e) {
        LogService.e('Error copying file: $sourcePath', e);
      }
    }
  }
}