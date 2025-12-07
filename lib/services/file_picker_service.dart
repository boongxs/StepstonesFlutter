import 'package:file_picker/file_picker.dart';
import 'logger_service.dart';

class FilePickerService {
  // opens dialog to select multiple files
  // returns a list of paths
  Future<List<String>?> pickMediaFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Files to Upload',
        allowMultiple: true,
        type: FileType.any,
        lockParentWindow: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final paths = result.files
          .map((f) => f.path)
          .where((path) => path != null)
          .cast<String>()
          .toList();
        
        LogService.i("User picked ${paths.length} files.");
        return paths;
      } else {
        LogService.i('File selection cancelled.');
        return null;
      }
    } catch (e) {
      LogService.e('Error picking files', e);
      return null;
    }
  }
}