import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'premium_service.dart';

/// Controla el cupo diario de búsquedas IA gratuitas.
///
/// Campos guardados en `perfiles/{uid}`:
///   ia_fecha_hoy         — "yyyy-MM-dd" en hora Lima (UTC-5, sin horario de verano)
///   ia_usos_hoy          — int: llamadas consumidas hoy
///   ia_bonus_hoy         — int: búsquedas extra ganadas viendo anuncios hoy
///   ia_racha_sin_cupo    — int: días consecutivos en que el cupo fue agotado
///   ia_ult_dia_sin_cupo  — "yyyy-MM-dd": última fecha en que se agotó el cupo
class IaLimiteService {
  static const int limiteGratuito  = 5;
  static const int bonusPorAnuncio = 3;

  static final _db = FirebaseFirestore.instance;

  // ── Fecha en zona horaria Lima (UTC-5, Perú no usa horario de verano) ──────
  static String _fechaHoy() {
    final lima = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    return '${lima.year}-'
        '${lima.month.toString().padLeft(2, '0')}-'
        '${lima.day.toString().padLeft(2, '0')}';
  }

  static String _fechaAyer() {
    final lima = DateTime.now()
        .toUtc()
        .subtract(const Duration(hours: 5))
        .subtract(const Duration(days: 1));
    return '${lima.year}-'
        '${lima.month.toString().padLeft(2, '0')}-'
        '${lima.day.toString().padLeft(2, '0')}';
  }

  static Future<_UsoData> _datos(String uid) async {
    try {
      final doc = await _db.collection('perfiles').doc(uid).get();
      final d = doc.data() ?? {};
      final hoy = _fechaHoy();
      if ((d['ia_fecha_hoy'] as String?) != hoy) {
        // Nuevo día → reiniciar contadores de uso (racha y ult_dia se mantienen)
        return _UsoData(
          usos: 0,
          bonus: 0,
          fecha: hoy,
          rachaSinCupo: (d['ia_racha_sin_cupo']  as num?)?.toInt() ?? 0,
          ultDiaSinCupo: d['ia_ult_dia_sin_cupo'] as String? ?? '',
        );
      }
      return _UsoData(
        usos:          (d['ia_usos_hoy']         as num?)?.toInt() ?? 0,
        bonus:         (d['ia_bonus_hoy']         as num?)?.toInt() ?? 0,
        fecha:         hoy,
        rachaSinCupo:  (d['ia_racha_sin_cupo']   as num?)?.toInt() ?? 0,
        ultDiaSinCupo: d['ia_ult_dia_sin_cupo']  as String? ?? '',
      );
    } catch (_) {
      return _UsoData(usos: 0, bonus: 0, fecha: _fechaHoy());
    }
  }

  /// Búsquedas disponibles hoy. Devuelve 999 si es Premium.
  static Future<int> restantes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;
    if (await PremiumService.isPremium()) return 999;
    final d = await _datos(uid);
    final total = limiteGratuito + d.bonus;
    return (total - d.usos).clamp(0, total);
  }

  /// ¿El usuario puede hacer una llamada IA ahora?
  static Future<bool> puedeUsar() async => (await restantes()) > 0;

  /// Descuenta 1 búsqueda. Devuelve `false` si ya se agotó el cupo.
  /// Cuando el cupo está agotado, actualiza el contador de días consecutivos
  /// sin cupo para que la Cloud Function pueda enviar la notificación Premium.
  static Future<bool> consumir() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    if (await PremiumService.isPremium()) return true;
    final d = await _datos(uid);
    if (d.usos >= limiteGratuito + d.bonus) {
      // Cupo agotado: registrar como refuerzo al seguimiento del servidor
      await _actualizarRachaSinCupo(uid, d);
      return false;
    }
    try {
      await _db.collection('perfiles').doc(uid).set(
        {'ia_usos_hoy': d.usos + 1, 'ia_fecha_hoy': d.fecha},
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Añade búsquedas extra. [cantidad] por defecto es [bonusPorAnuncio] (3).
  /// Usar `cantidad: 2` para el bono del simulacro bonificado.
  static Future<void> agregarBonus({int cantidad = bonusPorAnuncio}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final d = await _datos(uid);
    await _db.collection('perfiles').doc(uid).set(
      {'ia_bonus_hoy': d.bonus + cantidad, 'ia_fecha_hoy': d.fecha},
      SetOptions(merge: true),
    );
  }

  // ── Racha de días sin cupo ─────────────────────────────────────────────────
  // Complementa el seguimiento server-side en la Cloud Function `llamarIA`.
  // Se registra en el cliente cuando consumir() detecta que el cupo ya está agotado.

  static Future<void> _actualizarRachaSinCupo(String uid, _UsoData d) async {
    // Si ya registramos el día de hoy, no volver a escribir
    if (d.ultDiaSinCupo == d.fecha) return;

    final ayer = _fechaAyer();
    // Día consecutivo si ayer también se agotó; si no, reiniciar a 1
    final nuevaRacha = (d.ultDiaSinCupo == ayer) ? d.rachaSinCupo + 1 : 1;

    try {
      await _db.collection('perfiles').doc(uid).set(
        {
          'ia_racha_sin_cupo':   nuevaRacha,
          'ia_ult_dia_sin_cupo': d.fecha,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[IaLimiteService] Error actualizando racha sin cupo: $e');
    }
  }
}

class _UsoData {
  final int usos, bonus, rachaSinCupo;
  final String fecha, ultDiaSinCupo;
  const _UsoData({
    required this.usos,
    required this.bonus,
    required this.fecha,
    this.rachaSinCupo  = 0,
    this.ultDiaSinCupo = '',
  });
}
