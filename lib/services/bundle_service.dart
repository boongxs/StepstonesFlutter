import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../data/app_database.dart';
import 'logger_service.dart';

// to pass data into the isolate
class _BundleInput {
  final SendPort sendPort;
  final String tempPath;
  final String appSupportPath;
  final List<Map<String, dynamic>> items;

  _BundleInput({
    required this.sendPort,
    required this.tempPath,
    required this.appSupportPath,
    required this.items,
  });
}

class BundleService {
  BundleService._();

  // packs selected items into a .stepstone bundle file
  static Future<String?> createBundle(
    List<MediaItem> items, {
      Function(String currentFile)? onProgress,
    }) async {
    if (items.isEmpty) return null;

    // prepare data for isolate
    final rawItems = items.map((item) => {
      "hashedFileName": item.hashedFileName,
      "mediaFolderPath": item.mediaFolderPath,
      "tags": item.tags,
      "thumbnailPath": item.thumbnailPath,
      "fileType": item.fileType,
      "width": item.width,
      "height": item.height,
      "duration": item.duration,
    }).toList();

    final tempDir = await getTemporaryDirectory();
    final appSupportDir = await getApplicationSupportDirectory();

    final receivePort = ReceivePort();

    // spawn the isolate
    await Isolate.spawn(
      _bundleTask,
      _BundleInput(
        sendPort: receivePort.sendPort,
        tempPath: tempDir.path,
        appSupportPath: appSupportDir.path,
        items: rawItems,
      ),
    );

    // listen to messages from the isolate
    String? resultPath;
    final completer = Completer<String?>();

    final subscription = receivePort.listen((message) {
      if (message is Map) {
        final type = message["type"];

        if (type == "progress") {
          // progress update
          if (onProgress != null) onProgress(message["file"]);
        } else if (type == "success") {
          // success: path received
          resultPath = message["path"];
          completer.complete(resultPath);
        } else if (type == "error") {
          // error occurred
          LogService.e("Bundle isolate error: ${message["message"]}");
          completer.complete(null);
        }
      }
    });

    final finalResult = await completer.future;
    subscription.cancel();
    receivePort.close();

    return finalResult;
  }

  // background task
  static Future<void> _bundleTask(_BundleInput input) async {
    final bundleDir = Directory(p.join(input.tempPath, "bundle_${DateTime.now().millisecondsSinceEpoch}"));
    final mediaDir = Directory(p.join(bundleDir.path, "media"));
    final thumbsDir = Directory(p.join(bundleDir.path, "thumbs"));

    try {
      await mediaDir.create(recursive: true);
      await thumbsDir.create(recursive: true);

      final Map<String, dynamic> metadata = {};
      int successCount = 0;

      for (final item in input.items) {
        final fileName = item["hashedFileName"] as String;

        // report progress back to UI
        input.sendPort.send({'type': 'progress', 'file': fileName});

        // copy media file
        final sourcePath = p.join(item["mediaFolderPath"], fileName);
        final sourceFile = File(sourcePath);

        if (!sourceFile.existsSync()) {
          continue;
        }

        sourceFile.copySync(p.join(mediaDir.path, fileName));

        // copy thumbnail
        final thumbPath = item["thumbnailPath"] as String?;
        if (thumbPath != null) {
          final sourceThumb = File(p.join(input.appSupportPath, "thumbnails", thumbPath));
          if (sourceThumb.existsSync()) {
            sourceThumb.copySync(p.join(thumbsDir.path, thumbPath));
          }
        }

        // write metadata
        metadata[fileName] = {
          "tags": item["tags"],
          "thumbnailPath": thumbPath,
          "fileType": item["fileType"],
          "width": item["width"],
          "height": item["height"],
          "duration": item["duration"],
        };

        successCount++;
      }

      if (successCount == 0) {
        input.sendPort.send("ERROR:No valid media items found to bundle.");
        input.sendPort.send(false);
        return;
      }

      // save metadata.json
      final jsonFile = File(p.join(bundleDir.path, "metadata.json"));
      jsonFile.writeAsStringSync(jsonEncode(metadata));

      // zip the bundle
      final zipFilePath = p.join(input.tempPath, "Stepstones_Export_${DateTime.now().millisecondsSinceEpoch}.stepstone");
      var encoder = ZipFileEncoder();
      encoder.create(zipFilePath, level: 0); // no compression

      await encoder.addDirectory(mediaDir);
      await encoder.addDirectory(thumbsDir);
      await encoder.addFile(jsonFile);

      encoder.close();

      // clean up temp folder
      if (bundleDir.existsSync()) {
        bundleDir.deleteSync(recursive: true);
      }

      // verify file exists before sending success
      if (File(zipFilePath).existsSync()) {
        input.sendPort.send({'type': 'success', 'path': zipFilePath});
      } else {
        input.sendPort.send({'type': 'error', 'message': "Zip file creation failed silently."});
      }
    } catch (e) {
      input.sendPort.send({'type': 'error', 'message': e.toString()});
      try {
        if (bundleDir.existsSync()) {
          bundleDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    }
  }
}