import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemaService {
  static final ValueNotifier<ThemeMode> modoNotifier = ValueNotifier(ThemeMode.dark);

  static Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    modoNotifier.value = _parse(prefs.getString('tema_modo') ?? 'dark');
  }

  static Future<void> setModo(ThemeMode modo) async {
    modoNotifier.value = modo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tema_modo', _nombre(modo));
  }

  static ThemeMode _parse(String s) {
    if (s == 'light') return ThemeMode.light;
    if (s == 'system') return ThemeMode.system;
    return ThemeMode.dark;
  }

  static String _nombre(ThemeMode m) {
    if (m == ThemeMode.light) return 'light';
    if (m == ThemeMode.system) return 'system';
    return 'dark';
  }
}
