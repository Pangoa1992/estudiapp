import 'dart:async' show unawaited;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'niveles_service.dart';

class MonedasService {
  static const int porPomodoro = 10;
  static const int porSimulacro = 20;
  static const int porPerfecto = 50;
  static const int porRachaDiaria = 15;
  static const int porIA = 5;

  static const int precioEscudo = 100;
  static const int precioBoostRacha = 150;
  static const int precioTemaOscuro = 500;

  static final _db = FirebaseFirestore.instance;
  static User? get _user => FirebaseAuth.instance.currentUser;

  static Future<void> agregar(int cantidad, String motivo) async {
    if (_user == null || cantidad <= 0) return;
    try {
      await _db.collection('perfiles').doc(_user!.uid).set(
        {'monedas': FieldValue.increment(cantidad)},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[MonedasService] Error al agregar monedas ($motivo): $e');
    }
  }

  /// Returns true if purchase succeeded, false if insufficient coins.
  static Future<bool> gastar(int cantidad) async {
    if (_user == null) return false;
    try {
      bool exito = false;
      await _db.runTransaction((tx) async {
        final ref = _db.collection('perfiles').doc(_user!.uid);
        final doc = await tx.get(ref);
        final saldo = (doc.data()?['monedas'] as num? ?? 0).toInt();
        if (saldo < cantidad) return;
        tx.update(ref, {'monedas': FieldValue.increment(-cantidad)});
        exito = true;
      });
      return exito;
    } catch (e) {
      debugPrint('[MonedasService] Error al gastar monedas: $e');
      return false;
    }
  }

  static String _hoyStr() {
    // Lima = UTC-5 (sin horario de verano)
    final d = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Called once on app open. Awards daily bonus coins based on current streak.
  /// Returns the number of coins awarded (0 if already claimed today).
  static Future<int> recompensaDiaria() async {
    if (_user == null) return 0;
    try {
      final ref = _db.collection('perfiles').doc(_user!.uid);
      final doc = await ref.get();
      if (!doc.exists) return 0;
      final data = doc.data()!;
      final hoy = _hoyStr();
      if ((data['monedas_fecha_recompensa'] as String? ?? '') == hoy) return 0;

      final racha = (data['racha'] as num? ?? 1).toInt();
      final int monedas;
      if (racha > 0 && racha % 30 == 0) {
        monedas = 200;
      } else if (racha > 0 && racha % 7 == 0) {
        monedas = 50;
      } else {
        monedas = 10;
      }

      await ref.update({
        'monedas': FieldValue.increment(monedas),
        'monedas_fecha_recompensa': hoy,
      });
      unawaited(NivelesService.ganarXP(25, 'recompensa_diaria'));
      return monedas;
    } catch (e) {
      debugPrint('[MonedasService] Error en recompensa diaria: $e');
      return 0;
    }
  }
}
