import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../locator.dart';

class SettingsController extends ChangeNotifier {
  final SettingsService _settingsService = getIt<SettingsService>();

  // set initial fallback defaults
  double _defaultVolume = 50.0;
  double get defaultVolume => _defaultVolume;

  Color _themeColor = Colors.tealAccent;
  Color get themeColor => _themeColor;

  double _similarityThreshold = 95.0;
  double get similarityThreshold => _similarityThreshold;

  SettingsController() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // load saves values or fallback to defaults
    _defaultVolume = await _settingsService.loadDefaultVolume() ?? 50.0;
    _similarityThreshold = await _settingsService.loadSimilarityThreshold() ?? 95.0;

    final savedColorValue = await _settingsService.loadThemeColor();
    if (savedColorValue != null) {
      _themeColor = Color(savedColorValue);
    }

    notifyListeners();
  }

  Future<bool> saveSettings(double volume, Color color, double similarityThreshold) async {
    // update local state and notify UI to rebuild
    _defaultVolume = volume;
    _themeColor = color;
    _similarityThreshold = similarityThreshold;
    notifyListeners();

    // save to disk
    final volumeSuccess = await _settingsService.saveDefaultVolume(volume);
    final colorSuccess = await _settingsService.saveThemeColor(color.toARGB32());
    final thresholdSuccess = await _settingsService.saveSimilarityThreshold(similarityThreshold);

    return volumeSuccess && colorSuccess && thresholdSuccess;
  }
}