import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._();
  static final AppThemeController instance = AppThemeController._();

  static const String _themeColorKey = "theme_color_v1";
  static const Color _defaultSeed = Color(0xFF7A5CFF);

  Color _seedColor = _defaultSeed;
  bool _loaded = false;

  Color get seedColor => _seedColor;
  Color get defaultSeedColor => _defaultSeed;
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_themeColorKey);
    if (raw != null) {
      _seedColor = Color(raw);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeColorKey, color.value);
  }

  Future<void> reset() async {
    await setSeedColor(_defaultSeed);
  }
}
