import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:xxh3/xxh3.dart';
import 'logger_service.dart';

class CopyResponse {
  final CopyResult status;
  final String? hash;
  final String? finalFileName;

  CopyResponse(this.status, {this.hash, this.finalFileName});
}

enum CopyResult { success, duplicate, failure }

class FileService {
  // copies file with a callback for file's progress
  Future<CopyResponse> copyFileWithProgress(
    String sourcePath,
    String destFolder,
    Function(double) onProgress,
  ) async {
    final tempFileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(sourcePath)}.tmp';
    final tempFilePath = p.join(destFolder, tempFileName);

    try {
      final sourceFile = File(sourcePath);
      final totalBytes = await sourceFile.length();

      final hasher = XXH3State.create();

      final inputStream = sourceFile.openRead();
      final outputSink = File(tempFilePath).openWrite();

      int bytesCopied = 0;

      // 3. pipe data manually to track progress
      await inputStream.listen(
        (List<int> chunk) {
          hasher.update(Uint8List.fromList(chunk)); // feed hasher

          outputSink.add(chunk); // write to disk

          // update progress
          bytesCopied += chunk.length;
          onProgress(bytesCopied / totalBytes);
        },
        cancelOnError: true,
      ).asFuture();

      // 4. close/flush the file
      await outputSink.flush();
      await outputSink.close();

      final hashInt = hasher.digest();
      final hashString = hashInt.toRadixString(16).toUpperCase();

      final extension = p.extension(sourcePath);
      final finalFileName = '$hashString$extension';
      final finalDestPath = p.join(destFolder, finalFileName);

      // check for duplicate
      final finalFile = File(finalDestPath);
      if (await finalFile.exists()) {
        LogService.w('Duplicate detected: $finalFileName. Deleting temp file.');
        await File(tempFilePath).delete();
        
        return CopyResponse(CopyResult.duplicate, hash: hashString, finalFileName: finalFileName);
      }

      // rename temp file to final name
      await File(tempFilePath).rename(finalDestPath);
      LogService.i("Uploaded: $finalFileName");

      return CopyResponse(CopyResult.success, hash: hashString, finalFileName: finalFileName);
    } catch (e) {
      LogService.e('Error copying file from $sourcePath to $destFolder', e);

      // cleanup temp file if exists
      try {
        final tempFile = File(tempFilePath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}

      return CopyResponse(CopyResult.failure);
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

  // hashes an existing file in the library and renames it to {hash}.ext
  Future<CopyResponse> importFileWithProgress(
    String filePath,
    Function(double) onProgress,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return CopyResponse(CopyResult.failure);
      
      final totalBytes = await file.length();
      
      // 1. hash the file
      final hasher = XXH3State.create();
      final inputStream = file.openRead();
      
      int bytesRead = 0;
      
      await inputStream.listen(
        (List<int> chunk) {
          hasher.update(Uint8List.fromList(chunk));
          bytesRead += chunk.length;
          onProgress(bytesRead / totalBytes);
        },
        cancelOnError: true,
      ).asFuture();
      
      final hashInt = hasher.digest();
      final hashString = hashInt.toRadixString(16).toUpperCase();
      
      // 2. determine target name
      final folder = p.dirname(filePath);
      final extension = p.extension(filePath);
      final finalFileName = "$hashString$extension";
      final finalPath = p.join(folder, finalFileName);
      
      // 3. check if it needs renaming
      // case A: file is already named correctly
      if (filePath == finalPath) {
        return CopyResponse(CopyResult.success, hash: hashString, finalFileName: finalFileName);
      }
      
      // case B: file is named "vacation.jpg" but file with its hash already exists (duplicate)
      if (await File(finalPath).exists()) {
        LogService.w("Duplicate import: $finalFileName already exists. Deleting source.");
        await file.delete();
        return CopyResponse(CopyResult.duplicate, hash: hashString, finalFileName: finalFileName);
      }
      
      // case C: rename "vacation.jpg" to its hash
      await file.rename(finalPath);
      LogService.i("Renamed and imported: $finalFileName");
      return CopyResponse(CopyResult.success, hash: hashString, finalFileName: finalFileName);
    } catch (e) {
      LogService.e("Failed to import $filePath", e);
      return CopyResponse(CopyResult.failure);
    }
  }
}