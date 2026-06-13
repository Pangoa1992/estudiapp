import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResenaService {
  static const _keyPrimeraApertura = 'resena_primera_apertura';
  static const _keySimulacros = 'resena_simulacros';
  static const _keySolicitada = 'resena_solicitada';
  static const _keySesiones = 'resena_sesiones';

  /// Registra la fecha del primer uso. Llamar una vez al abrir HomePage.
  static Future<void> registrarPrimeraApertura() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_keyPrimeraApertura) == null) {
      await prefs.setString(
          _keyPrimeraApertura, DateTime.now().toIso8601String());
    }
  }

  /// Incrementa el contador de sesiones y pide reseña si llegó a 5.
  /// Cubre a usuarios con la app instalada hace tiempo (contador rápido).
  static Future<void> checkPorSesiones() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keySolicitada) == true) return;
    final sesiones = (prefs.getInt(_keySesiones) ?? 0) + 1;
    await prefs.setInt(_keySesiones, sesiones);
    if (sesiones >= 5) await _intentarSolicitar(prefs);
  }

  /// Incrementa el contador de simulacros y pide reseña si llegó a 3.
  static Future<void> onSimulacroCompletado() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keySolicitada) == true) return;
    final count = (prefs.getInt(_keySimulacros) ?? 0) + 1;
    await prefs.setInt(_keySimulacros, count);
    if (count >= 3) await _intentarSolicitar(prefs);
  }

  /// Verifica si han pasado 3+ días desde la primera apertura.
  static Future<void> checkPorDiasDeUso() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keySolicitada) == true) return;
    final fechaStr = prefs.getString(_keyPrimeraApertura);
    if (fechaStr == null) return;
    final primera = DateTime.tryParse(fechaStr);
    if (primera == null) return;
    if (DateTime.now().difference(primera).inDays >= 3) {
      await _intentarSolicitar(prefs);
    }
  }

  static Future<void> _intentarSolicitar(SharedPreferences prefs) async {
    final review = InAppReview.instance;
    if (!await review.isAvailable()) return;
    await review.requestReview();
    await prefs.setBool(_keySolicitada, true);
  }
}
