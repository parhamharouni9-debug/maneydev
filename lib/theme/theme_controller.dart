import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's light/dark choice across launches and notifies the
/// app to rebuild when it changes (driven by the sun/moon toggle).
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _prefsKey = 'theme_mode';

  ThemeMode mode = ThemeMode.dark;
  bool _loaded = false;

  bool get isDark => mode == ThemeMode.dark;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    mode = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle() async {
    mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, isDark ? 'dark' : 'light');
  }
}
