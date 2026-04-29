import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

class SettingsService {
  static const String _mediaFolderKey = "media_folder_path";
  static const String _defaultVolumeKey = "default_volume";
  static const String _themeColorKey = "theme_color";
  static const String _similarityThresholdKey = "similarity_threshold";

  // --- MEDIA FOLDER ---
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

  // --- DEFAULT VOLUME ---
  Future<bool> saveDefaultVolume(double volume) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_defaultVolumeKey, volume);
      return true;
    } catch (e) {
      LogService.e("Error saving default volume", e);
      return false;
    }
  }

  Future<double?> loadDefaultVolume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_defaultVolumeKey);
    } catch (e) {
      LogService.e("Error loading default volume", e);
      return null;
    }
  }

  // --- THEME COLOR ---
  Future<bool> saveThemeColor(int colorValue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeColorKey, colorValue);
      return true;
    } catch (e) {
      LogService.e("Error saving theme color", e);
      return false;
    }
  }

  Future<int?> loadThemeColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_themeColorKey);
    } catch (e) {
      LogService.e("Error loading theme color", e);
      return null;
    }
  }

  // --- SIMILARITY THRESHOLD ---
  Future<bool> saveSimilarityThreshold(double threshold) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_similarityThresholdKey, threshold);
      return true;
    } catch (e) {
      LogService.e("Error saving similarity threshold", e);
      return false;
    }
  }

  Future<double?> loadSimilarityThreshold() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_similarityThresholdKey);
    } catch (e) {
      LogService.e("Error loading similarity threshold", e);
      return null;
    }
  }
}