import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void resetToLightMode() {
    if (_isDarkMode) {
      _isDarkMode = false;
      notifyListeners();
    }
  }

  // Initialize theme to light mode
  void initializeTheme() {
    _isDarkMode = false;
    notifyListeners();
  }
}
