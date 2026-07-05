import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const _seedColorKey = 'settings.seed_color';
  static const _dynamicColorKey = 'settings.dynamic_color';
  static const _darkModeKey = 'settings.dark_mode';

  Color _seedColor = Colors.teal;
  bool _useDynamicColor = true;
  bool _useDarkMode = false;

  Color get seedColor => _seedColor;
  bool get useDynamicColor => _useDynamicColor;
  bool get useDarkMode => _useDarkMode;
  ThemeMode get themeMode => _useDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final colorValue = preferences.getInt(_seedColorKey);
    if (colorValue != null) {
      _seedColor = Color(colorValue);
    }
    _useDynamicColor = preferences.getBool(_dynamicColorKey) ?? true;
    _useDarkMode = preferences.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_seedColorKey, color.toARGB32());
  }

  Future<void> setUseDynamicColor(bool value) async {
    _useDynamicColor = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_dynamicColorKey, value);
  }

  Future<void> setUseDarkMode(bool value) async {
    _useDarkMode = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_darkModeKey, value);
  }
}

final appSettingsController = SettingsController();
