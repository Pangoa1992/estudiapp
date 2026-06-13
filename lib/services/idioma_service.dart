import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IdiomaService {
  static const _key = 'idioma_codigo';
  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier(const Locale('es'));

  static Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_key);
    if (guardado != null) {
      localeNotifier.value = Locale(guardado);
    } else {
      final sistema = PlatformDispatcher.instance.locale.languageCode;
      localeNotifier.value = Locale(_soportado(sistema) ? sistema : 'es');
    }
  }

  static bool _soportado(String codigo) => ['es', 'en'].contains(codigo);

  static Future<void> setIdioma(String codigo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, codigo);
    localeNotifier.value = Locale(codigo);
  }

  static String get codigoActual => localeNotifier.value.languageCode;

  static String t(String es, String en) =>
      codigoActual == 'en' ? en : es;
}
