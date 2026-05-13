import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class RachaService {
  final _db = FirebaseFirestore.instance;

  // Obtener el usuario en el momento de la llamada, no al construir el servicio,
  // para evitar capturar un usuario nulo durante la inicialización del login.
  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> verificarRacha() async {
    if (_user == null) return;

    final docRef = _db.collection('perfiles').doc(_user!.uid);
    final doc = await docRef.get();

    // Usamos la hora local del dispositivo. Firestore's toDate() también
    // retorna hora local, por lo que las comparaciones son consistentes.
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    if (!doc.exists) {
      await docRef.set({
        'racha': 1,
        'ultimaVisita': Timestamp.fromDate(hoy),
        'rachaMaxima': 1,
        'ultimoReset': Timestamp.fromDate(hoy),
        'primeraVisita': Timestamp.fromDate(hoy),
      }, SetOptions(merge: true));
      return;
    }

    // Retrocompatibilidad: agregar primeraVisita a perfiles existentes que no lo tienen
    final data0 = doc.data()!;
    if (data0['primeraVisita'] == null) {
      await docRef.update({'primeraVisita': data0['ultimaVisita'] ?? Timestamp.fromDate(hoy)});
    }

    final data = doc.data()!;
    final ultimaVisita = (data['ultimaVisita'] as Timestamp?)?.toDate();
    final rachaActual = data['racha'] ?? 0;
    final rachaMaxima = data['rachaMaxima'] ?? 0;
    final ultimoReset = (data['ultimoReset'] as Timestamp?)?.toDate();

    // Reset habitos si es un nuevo dia
    final ultimoDiaReset = ultimoReset != null
        ? DateTime(ultimoReset.year, ultimoReset.month, ultimoReset.day)
        : null;

    if (ultimoDiaReset == null || hoy.difference(ultimoDiaReset).inDays >= 1) {
      await _resetearHabitos();
      await docRef.update({'ultimoReset': Timestamp.fromDate(hoy)});
    }

    if (ultimaVisita == null) {
      await docRef.update({
        'racha': 1,
        'ultimaVisita': Timestamp.fromDate(hoy),
        'rachaMaxima': 1,
      });
      return;
    }

    final ultimoDia = DateTime(ultimaVisita.year, ultimaVisita.month, ultimaVisita.day);
    final diferencia = hoy.difference(ultimoDia).inDays;

    if (diferencia == 0) {
      return;
    } else if (diferencia == 1) {
      final nuevaRacha = rachaActual + 1;
      await docRef.update({
        'racha': nuevaRacha,
        'ultimaVisita': Timestamp.fromDate(hoy),
        'rachaMaxima': nuevaRacha > rachaMaxima ? nuevaRacha : rachaMaxima,
      });
    } else {
      await docRef.update({
        'racha': 1,
        'ultimaVisita': Timestamp.fromDate(hoy),
      });
    }
  }

  Future<void> _resetearHabitos() async {
    if (_user == null) return;
    try {
      final habitos = await _db.collection('habitos')
          .where('userId', isEqualTo: _user!.uid)
          .where('done', isEqualTo: true)
          .get();

      final batch = _db.batch();
      for (final doc in habitos.docs) {
        batch.update(doc.reference, {'done': false});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[RachaService] Error al resetear hábitos: $e');
    }
  }
}