import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:xxh3/xxh3.dart';
import 'logger_service.dart';
import 'dart:async';

class CopyResponse {
  final CopyResult status;
  final String? hash;
  final String? finalFileName;

  CopyResponse(this.status, {this.hash, this.finalFileName});
}

enum CopyResult { success, duplicate, failure }

class CopyRequest {
  final String sourcePath;
  final String destFolder;

  CopyRequest(this.sourcePath, this.destFolder);
}

Future<CopyResponse> _copyAndHashInBackground(CopyRequest request) async {
  final sourceFile = File(request.sourcePath);
  final tempFileName = "${DateTime.now().millisecondsSinceEpoch}_${p.basename(request.sourcePath)}.tmp";
  final tempFilePath = p.join(request.destFolder, tempFileName);

  try {
    final hasher = XXH3State.create();
    final inputStream = sourceFile.openRead();
    final outputSink = File(tempFilePath).openWrite();

    await inputStream.listen(
      (List<int> chunk) {
        hasher.update(Uint8List.fromList(chunk));
        outputSink.add(chunk);
      },
      cancelOnError: true,
    ).asFuture();

    await outputSink.flush();
    await outputSink.close();

    final hashInt = hasher.digest();
    final hashString = hashInt.toRadixString(16).toUpperCase();

    final extension = p.extension(request.sourcePath);
    final finalFileName = "$hashString$extension";
    final finalDestPath = p.join(request.destFolder, finalFileName);

    final finalFile = File(finalDestPath);
    if (await finalFile.exists()) {
      await File(tempFilePath).delete(); // clean up temp
      return CopyResponse(
        CopyResult.duplicate,
        hash: hashString,
        finalFileName: finalFileName,
      );
    }

    // rename temp file to final name
    await File(tempFilePath).rename(finalDestPath);

    return CopyResponse(
      CopyResult.success,
      hash: hashString,
      finalFileName: finalFileName
    );
  } catch (e) {
    try {
      final tempFile = File(tempFilePath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (_) {}

    return CopyResponse(CopyResult.failure);
  }
}

class FileService {
  Future<CopyResponse> copyFile(String sourcePath, String destFolder) async {
    try {
      final result = await compute(
        _copyAndHashInBackground,
        CopyRequest(sourcePath, destFolder)
      );

      if (result.status == CopyResult.success) {
        LogService.i("Uploaded: ${result.finalFileName}");
      } else if (result.status == CopyResult.duplicate) {
        LogService.w("Duplicate detected: ${result.finalFileName}");
      }

      return result;
    } catch (e) {
      LogService.e("Error copying file from $sourcePath", e);
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
      LogService.e("Error counting files in folder: $folderPath", e);
      return 0;
    }
  }

  // hashes an existing file in the library and renames it to {hash}.ext
  Future<CopyResponse> importFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return CopyResponse(CopyResult.failure);
      
      // 1. hash the file
      final hasher = XXH3State.create();
      final inputStream = file.openRead();
          
      await inputStream.listen(
        (List<int> chunk) {
          hasher.update(Uint8List.fromList(chunk));
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