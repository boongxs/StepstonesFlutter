import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'logger_service.dart';

class BundleImportService {
  BundleImportService._();

  /// unpacks a .stepstone bundle to a temp directory
  /// returns the path to the directory containing the unpacked files.
  
  static Future<String?> unpackBundle(String bundlePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory(p.join(tempDir.path, "import_${DateTime.now().millisecondsSinceEpoch}"));

      await extractDir.create(recursive: true);

      await compute(_extractZipInBackground, [bundlePath, extractDir.path]);

      return extractDir.path;
    } catch (e) {
      LogService.e("Failed to unpack bundle", e);
      return null;
    }
  }

  /// reads and parses metadata.json file from unpacked bundle
  static Future<Map<String, dynamic>?> readMetadata(String unpackedPath) async {
    try {
      final jsonFile = File(p.join(unpackedPath, "metadata.json"));
      if (!await jsonFile.exists()) {
        LogService.e("Invalid bundle: metadata.json missing");
        return null;
      }

      final jsonString = await jsonFile.readAsString();
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      LogService.e("Failed to read bundle metadata", e);
      return null;
    }
  }

  /// cleans up the temporary extracted directory
  static Future<void> cleanup(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      LogService.w("Failed to cleanup import temp dir: $path");
    }
  }
}

Future<void> _extractZipInBackground(List<String> paths) async {
  final zipPath = paths[0];
  final destPath = paths[1];

  final inputStream = InputFileStream(zipPath);
  final archive = ZipDecoder().decodeStream(inputStream);

  await Future.sync(() => extractArchiveToDisk(archive, destPath));

  await inputStream.close();
}