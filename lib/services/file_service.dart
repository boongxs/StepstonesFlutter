import 'dart:io';
import 'package:path/path.dart' as p;
import 'logger_service.dart';

class FileService {
  // copies file with a callback for file's progress
  Future<void> copyFileWithProgress(
    String sourcePath,
    String destFolder,
    Function(double) onProgress,
  ) async {
    try {
      final sourceFile = File(sourcePath);
      final fileName = p.basename(sourcePath);
      final destPath = p.join(destFolder, fileName);

      // check if file doesn't already exist in destFolder
      if (await File(destPath).exists()) {
        LogService.w("Skipping $fileName as it already exists in destination.");
        onProgress(1.0);
        return;
      }

      // 1. get file size for calculation
      final totalBytes = await sourceFile.length();
      int bytesCopied = 0;

      // 2. open streams
      final inputStream = sourceFile.openRead();
      final outputSink = File(destPath).openWrite();

      // 3. pipe data manually to track progress
      await inputStream.listen(
        (List<int> chunk) {
          outputSink.add(chunk); // write chunk

          // update progress
          bytesCopied += chunk.length;
          final progress = bytesCopied / totalBytes;

          // update UI
          onProgress(progress);
        },
        cancelOnError: true,
      ).asFuture();

      // 4. close/flush the file
      await outputSink.flush();
      await outputSink.close();

      LogService.i("Copied $fileName");
    } catch (e) {
      LogService.e('Error copying file from $sourcePath to $destFolder', e);
      rethrow; // pass error up to count it as fail
    }
  }

  // counts total number of files in target directory
  Future<int> getFileCount(String folderPath) async {
    try {
      final dir = Directory(folderPath);
      if (!await dir.exists()) {
        return 0;
      }

      return dir.listSync().whereType<File>().length;
    } catch (e) {
      LogService.e('Error counting files in folder: $folderPath', e);
      return 0;
    }
  }
}