import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Cache local con Hive para datos críticos de la app.
/// Complementa la caché offline de Firestore con lecturas instantáneas.
class CacheService {
  static const String _boxName = 'estudiapp_cache';
  static late Box _box;

  // Claves internas
  static const _kRacha = 'racha';
  static const _kRachaMax = 'rachaMaxima';
  static const _kHabitos = 'habitos';
  static const _kExamenes = 'examenes';
  static const _kPerfil = 'perfil';
  static const _kTimestamp = 'ts_';

  static Future<void> inicializar() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // ── Racha ────────────────────────────────────────────────────────────────

  static void guardarRacha(int racha, int rachaMaxima) {
    _box.put(_kRacha, racha);
    _box.put(_kRachaMax, rachaMaxima);
  }

  static int? getRacha() => _box.get(_kRacha) as int?;
  static int? getRachaMaxima() => _box.get(_kRachaMax) as int?;

  // ── Hábitos ──────────────────────────────────────────────────────────────

  static void guardarHabitos(List<Map<String, dynamic>> habitos) {
    _box.put(_kHabitos, jsonEncode(habitos));
    _box.put('$_kTimestamp$_kHabitos', DateTime.now().millisecondsSinceEpoch);
  }

  static List<Map<String, dynamic>>? getHabitos() {
    final raw = _box.get(_kHabitos);
    if (raw == null) return null;
    try {
      return List<Map<String, dynamic>>.from(
        (jsonDecode(raw as String) as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Exámenes próximos ────────────────────────────────────────────────────

  static void guardarExamenes(List<Map<String, dynamic>> examenes) {
    _box.put(_kExamenes, jsonEncode(examenes));
    _box.put('$_kTimestamp$_kExamenes', DateTime.now().millisecondsSinceEpoch);
  }

  static List<Map<String, dynamic>>? getExamenes() {
    final raw = _box.get(_kExamenes);
    if (raw == null) return null;
    try {
      return List<Map<String, dynamic>>.from(
        (jsonDecode(raw as String) as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Perfil académico ─────────────────────────────────────────────────────

  static void guardarPerfil(Map<String, dynamic> data) {
    _box.put(_kPerfil, jsonEncode(data));
  }

  static Map<String, dynamic>? getPerfil() {
    final raw = _box.get(_kPerfil);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw as String) as Map);
    } catch (_) {
      return null;
    }
  }

  // ── Utilidades ────────────────────────────────────────────────────────────

  /// Devuelve cuántos minutos han pasado desde que se guardó [colección].
  static int minutosDesdeActualizacion(String coleccion) {
    final ts = _box.get('$_kTimestamp$coleccion') as int?;
    if (ts == null) return 9999;
    return DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(ts))
        .inMinutes;
  }

  static Future<void> limpiar() => _box.clear();
}
