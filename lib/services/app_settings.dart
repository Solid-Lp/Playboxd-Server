import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  bool _highContrast = false;
  double _fontScale = 1.0;

  bool get highContrast => _highContrast;
  double get fontScale => _fontScale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _highContrast = prefs.getBool('high_contrast') ?? false;
    _fontScale = prefs.getDouble('font_scale') ?? 1.0;
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast', value);
    notifyListeners();
  }

  Future<void> setFontScale(double value) async {
    _fontScale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_scale', value);
    notifyListeners();
  }

  // Cores dinâmicas baseadas no modo
  Color get bgColor => _highContrast ? Colors.white : const Color(0xFF050816);
  Color get cardColor => _highContrast ? const Color(0xFFF0F0F0) : const Color(0xFF111827);
  Color get textColor => _highContrast ? Colors.black : Colors.white;
  Color get mutedColor => _highContrast ? Colors.black54 : Colors.white54;
  Color get borderColor => _highContrast ? Colors.black26 : Colors.white10;
  Color get accentColor => _highContrast ? const Color(0xFF006400) : const Color(0xFF39FF14);
  Color get accentTextColor => _highContrast ? Colors.white : Colors.black;
}