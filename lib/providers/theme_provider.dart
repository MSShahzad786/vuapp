import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final DatabaseService _databaseService = DatabaseService();

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadTheme() async {
    try {
      final themeValue = await _databaseService.getSetting('theme');
      if (themeValue != null) {
        switch (themeValue) {
          case '0':
            _themeMode = ThemeMode.dark;
            break;
          case '1':
            _themeMode = ThemeMode.light;
            break;
          case '2':
            _themeMode = ThemeMode.system;
            break;
          default:
            _themeMode = ThemeMode.system;
        }
      }
    } catch (e) {
      // Default to system if error
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    String value;
    switch (_themeMode) {
      case ThemeMode.dark:
        value = '0';
        break;
      case ThemeMode.light:
        value = '1';
        break;
      case ThemeMode.system:
        value = '2';
        break;
    }
    await _databaseService.setSetting('theme', value);
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      // If system, toggle to dark
      _themeMode = ThemeMode.dark;
    }
    _saveTheme();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveTheme();
    notifyListeners();
  }
}
