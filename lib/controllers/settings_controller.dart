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

  SettingsController() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // load saves values or fallback to defaults
    _defaultVolume = await _settingsService.loadDefaultVolume() ?? 50.0;

    final savedColorValue = await _settingsService.loadThemeColor();
    if (savedColorValue != null) {
      _themeColor = Color(savedColorValue);
    }

    notifyListeners();
  }

  Future<bool> saveSettings(double volume, Color color) async {
    // update local state and notify UI to rebuild
    _defaultVolume = volume;
    _themeColor = color;
    notifyListeners();

    // save to disk
    final volumeSuccess = await _settingsService.saveDefaultVolume(volume);
    final colorSuccess = await _settingsService.saveThemeColor(color.toARGB32());

    return volumeSuccess && colorSuccess;
  }
}