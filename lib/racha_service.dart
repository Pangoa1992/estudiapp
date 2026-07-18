import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'services/monedas_service.dart';

class RachaService {
  final _db = FirebaseFirestore.instance;

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> verificarRacha() async {
    if (_user == null) return;
    try {
      await _verificarRacha();
    } catch (e) {
      // Sin internet, docRef.get() lanza; se llama fire-and-forget en cada
      // apertura de la app, así que nunca debe propagar (evita crash fatal).
      debugPrint('[RachaService] verificarRacha falló: $e');
    }
  }

  Future<void> _verificarRacha() async {
    final docRef = _db.collection('perfiles').doc(_user!.uid);
    final doc = await docRef.get();

    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final semanaActual = _semanaISO(hoy);

    if (!doc.exists) {
      await docRef.set({
        'racha': 1,
        'ultimaVisita': Timestamp.fromDate(hoy),
        'rachaMaxima': 1,
        'ultimoReset': Timestamp.fromDate(hoy),
        'primeraVisita': Timestamp.fromDate(hoy),
        'escudos': 1,
        'escudo_semana': semanaActual,
      }, SetOptions(merge: true));
      await _guardarHistorialRacha(1, hoy);
      return;
    }

    final data = doc.data()!;

    // Retrocompatibilidad: primeraVisita
    if (data['primeraVisita'] == null) {
      await docRef.update({'primeraVisita': data['ultimaVisita'] ?? Timestamp.fromDate(hoy)});
    }
    // Retrocompatibilidad: escudos (perfiles sin el campo)
    if (data['escudos'] == null) {
      await docRef.update({'escudos': 1, 'escudo_semana': semanaActual});
    }

    final ultimaVisita = (data['ultimaVisita'] as Timestamp?)?.toDate();
    final rachaActual = (data['racha'] as num? ?? 0).toInt();
    final rachaMaxima = (data['rachaMaxima'] as num? ?? 0).toInt();
    final ultimoReset = (data['ultimoReset'] as Timestamp?)?.toDate();
    final escudoSemana = data['escudo_semana'] as String? ?? '';
    final escudos = (data['escudos'] as num? ?? 0).toInt();

    // Escudo efectivo: si cambia la semana, el escudo se recarga a 1
    final esSemanaNueva = escudoSemana != semanaActual;
    final escudosEfectivos = esSemanaNueva ? 1 : escudos;

    // Reset hábitos si es nuevo día
    final ultimoDiaReset = ultimoReset != null
        ? DateTime(ultimoReset.year, ultimoReset.month, ultimoReset.day)
        : null;
    final necesitaReset = ultimoDiaReset == null || hoy.difference(ultimoDiaReset).inDays >= 1;
    if (necesitaReset) await _resetearHabitos();

    if (ultimaVisita == null) {
      await docRef.update({
        'racha': 1,
        'ultimaVisita': Timestamp.fromDate(hoy),
        'rachaMaxima': 1,
        if (necesitaReset) 'ultimoReset': Timestamp.fromDate(hoy),
        if (esSemanaNueva) 'escudo_semana': semanaActual,
        if (esSemanaNueva) 'escudos': 1,
      });
      await _guardarHistorialRacha(1, hoy);
      return;
    }

    final ultimoDia = DateTime(ultimaVisita.year, ultimaVisita.month, ultimaVisita.day);
    final diferencia = hoy.difference(ultimoDia).inDays;

    if (diferencia == 0) {
      // Ya visitó hoy: solo actualizar escudo/reset si cambió algo
      final extras = <String, dynamic>{
        if (necesitaReset) 'ultimoReset': Timestamp.fromDate(hoy),
        if (esSemanaNueva) 'escudo_semana': semanaActual,
        if (esSemanaNueva) 'escudos': 1,
      };
      if (extras.isNotEmpty) await docRef.update(extras);
    } else if (diferencia == 1) {
      final nuevaRacha = rachaActual + 1;
      await docRef.update({
        'racha': nuevaRacha,
        'ultimaVisita': Timestamp.fromDate(hoy),
        'rachaMaxima': nuevaRacha > rachaMaxima ? nuevaRacha : rachaMaxima,
        if (necesitaReset) 'ultimoReset': Timestamp.fromDate(hoy),
        if (esSemanaNueva) 'escudo_semana': semanaActual,
        if (esSemanaNueva) 'escudos': 1,
      });
      await _guardarHistorialRacha(nuevaRacha, hoy);
      // Monedas por racha diaria (x2 si boost activo)
      final boostHasta = data['boost_racha_hasta'] as Timestamp?;
      final tieneBoost = boostHasta != null && boostHasta.toDate().isAfter(DateTime.now());
      await MonedasService.agregar(
        MonedasService.porRachaDiaria * (tieneBoost ? 2 : 1),
        'racha',
      );
    } else {
      // Racha rota: aplicar escudo automáticamente si hay uno
      if (escudosEfectivos > 0) {
        await docRef.update({
          'racha': rachaActual,
          'ultimaVisita': Timestamp.fromDate(hoy),
          'escudos': 0,
          'escudo_semana': semanaActual,
          'escudo_usado_en': Timestamp.fromDate(hoy),
          if (necesitaReset) 'ultimoReset': Timestamp.fromDate(hoy),
        });
        await _guardarHistorialRacha(rachaActual, hoy);
      } else {
        await docRef.update({
          'racha': 1,
          'ultimaVisita': Timestamp.fromDate(hoy),
          if (necesitaReset) 'ultimoReset': Timestamp.fromDate(hoy),
          if (esSemanaNueva) 'escudo_semana': semanaActual,
          if (esSemanaNueva) 'escudos': 1,
        });
        await _guardarHistorialRacha(1, hoy);
      }
    }
  }

  Future<void> _guardarHistorialRacha(int racha, DateTime fecha) async {
    if (_user == null) return;
    final fechaStr =
        '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    try {
      await _db.collection('historial_racha').add({
        'userId': _user!.uid,
        'racha': racha,
        'fechaStr': fechaStr,
        'fecha': Timestamp.fromDate(fecha),
      });
    } catch (e) {
      debugPrint('[RachaService] Error al guardar historial_racha: $e');
    }
  }

  // Identificador único por semana (lunes como inicio)
  String _semanaISO(DateTime date) {
    final lunes = date.subtract(Duration(days: date.weekday - 1));
    return '${lunes.year}-${lunes.month.toString().padLeft(2, '0')}-${lunes.day.toString().padLeft(2, '0')}';
  }

  Future<void> _resetearHabitos() async {
    if (_user == null) return;
    try {
      final habitos = await _db
          .collection('habitos')
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
