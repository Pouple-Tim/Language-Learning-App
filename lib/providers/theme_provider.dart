import 'package:flutter/material.dart';
import 'package:language_learning_app/data/repositories/settings_repository.dart';

class ThemeProvider extends ChangeNotifier {
  final SettingsRepository _repository = SettingsRepository();
  
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveTheme();
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    await _repository.updateTheme(_isDarkMode);
  }
}