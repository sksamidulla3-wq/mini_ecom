import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themePreferenceKEY = "app_theme_mode_preference_v1"; // Added a version

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTheme = prefs.getString(_themePreferenceKEY);
    if (savedTheme == "light") {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == "dark") {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      await prefs.setString(_themePreferenceKEY, "light");
    } else if (mode == ThemeMode.dark) {
      await prefs.setString(_themePreferenceKEY, "dark");
    } else {
      await prefs.remove(_themePreferenceKEY);
    }
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      // Also switch from system to dark, or dark to light.
      setThemeMode(ThemeMode.light);
    }
  }
}
