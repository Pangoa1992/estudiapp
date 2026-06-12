import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NivelesService {
  static final _db = FirebaseFirestore.instance;
  static User? get _user => FirebaseAuth.instance.currentUser;

  /// XP necesario para avanzar del nivel N al N+1.
  static int xpParaSiguienteNivel(int nivel) => 100 + (nivel - 1) * 50;

  /// Calcula el nivel a partir del XP total acumulado.
  static int nivelDesdeXpTotal(int xpTotal) {
    int nivel = 1;
    int acumulado = 0;
    while (true) {
      final necesario = xpParaSiguienteNivel(nivel);
      if (acumulado + necesario > xpTotal) return nivel;
      acumulado += necesario;
      nivel++;
    }
  }

  /// XP ganado dentro del nivel actual.
  static int xpEnNivelActual(int xpTotal) {
    int nivel = 1;
    int acumulado = 0;
    while (true) {
      final necesario = xpParaSiguienteNivel(nivel);
      if (acumulado + necesario > xpTotal) return xpTotal - acumulado;
      acumulado += necesario;
      nivel++;
    }
  }

  static String nombreDeNivel(int nivel) {
    if (nivel <= 2) return 'Iniciado';
    if (nivel <= 4) return 'Explorador';
    if (nivel <= 7) return 'Estudiante';
    if (nivel <= 10) return 'Aplicado';
    if (nivel <= 15) return 'Brillante';
    if (nivel <= 20) return 'Experto';
    if (nivel <= 30) return 'Maestro';
    return 'Leyenda';
  }

  static String emojiDeNivel(int nivel) {
    if (nivel <= 2) return '🌱';
    if (nivel <= 4) return '🗺️';
    if (nivel <= 7) return '📚';
    if (nivel <= 10) return '⚡';
    if (nivel <= 15) return '✨';
    if (nivel <= 20) return '🧠';
    if (nivel <= 30) return '🎓';
    return '🏆';
  }

  /// Otorga XP y detecta subida de nivel.
  /// Retorna el nuevo nivel si subió, null si no.
  static Future<int?> ganarXP(int cantidad, String motivo) async {
    if (_user == null || cantidad <= 0) return null;
    try {
      int? nuevoNivel;
      await _db.runTransaction((tx) async {
        final ref = _db.collection('perfiles').doc(_user!.uid);
        final doc = await tx.get(ref);
        final xpAnterior = (doc.data()?['xp_total'] as num? ?? 0).toInt();
        final nivelAnterior = nivelDesdeXpTotal(xpAnterior);
        final xpNuevo = xpAnterior + cantidad;
        final nivelNuevo = nivelDesdeXpTotal(xpNuevo);
        tx.set(
          ref,
          {'xp_total': xpNuevo, 'nivel': nivelNuevo},
          SetOptions(merge: true),
        );
        if (nivelNuevo > nivelAnterior) nuevoNivel = nivelNuevo;
      });
      return nuevoNivel;
    } catch (e) {
      debugPrint('[NivelesService] Error ganarXP ($motivo): $e');
      return null;
    }
  }
}
