import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

class SettingsService {
  // file that holds the last saved media folder path
  static const String _mediaFolderKey = "media_folder_path";

  // saves selected media folder path to persistent storage
  Future<void> saveMediaFolderPath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mediaFolderKey, path);
      LogService.i("Media folder path saved: $path");
    } 
    catch (e) {
      LogService.e("Error saving media folder path", e);
    }
  }

  // load save media folder path
  Future<String?> loadMediaFolderPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(_mediaFolderKey); // get path from _mediaFolderKey file 

      if (path != null) {
        LogService.i("Loaded saved media folder: $path");
      } else {
        LogService.w("No saved media folder path found in settings.");
      }

      return path;
    } catch (e) {
      LogService.e("Error loading media folder path", e);
      return null;
    }
  }
}