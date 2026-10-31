import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final isDark = await StorageService.isDarkMode();
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      await StorageService.setDarkMode(false);
    } else {
      _themeMode = ThemeMode.dark;
      await StorageService.setDarkMode(true);
    }
    notifyListeners();
  }
}
