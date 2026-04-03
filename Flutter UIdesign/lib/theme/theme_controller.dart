import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) {
    _dark = _prefs.getBool(_key) ?? false;
  }

  static const _key = 'darkMode';

  final SharedPreferences _prefs;
  bool _dark = false;

  bool get isDark => _dark;

  ThemeMode get themeMode => _dark ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggle() async {
    _dark = !_dark;
    await _prefs.setBool(_key, _dark);
    notifyListeners();
  }
}
