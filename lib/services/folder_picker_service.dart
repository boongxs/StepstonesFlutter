import 'package:file_picker/file_picker.dart';
import 'logger_service.dart';

class FolderPickerService {
  Future<String?> pickFolder() async {
    try {
      // open folder picker dialog
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Media Folder',
        lockParentWindow: true, // modal
      );

      // user doesn't select any folder
      if (selectedDirectory == null)
      {
        LogService.i('Folder selection cancelled by user.');
        return null;
      }

      // user selected a folder
      LogService.i('Folder selected: $selectedDirectory');
      return selectedDirectory;
    }
    catch (e) {
      LogService.e('Error picking folder', e);
      return null;
    }
  }
}