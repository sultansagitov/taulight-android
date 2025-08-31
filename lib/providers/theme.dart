import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode =
        ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index];
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', option.index);
    _themeMode = option;
    notifyListeners();
  }
}
