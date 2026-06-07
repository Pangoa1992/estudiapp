import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bienestar_model.dart';

class BienestarService {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  static Stream<List<RegistroBienestar>> stream7Dias() {
    final hace7 = DateTime.now().subtract(const Duration(days: 7));
    return _db
        .collection('bienestar')
        .where('userId', isEqualTo: _uid)
        .where('fecha', isGreaterThan: Timestamp.fromDate(hace7))
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => RegistroBienestar.fromMap(d.id, d.data()))
            .toList());
  }

  static Future<RegistroBienestar?> registroDeHoy() async {
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final snap = await _db
        .collection('bienestar')
        .where('userId', isEqualTo: _uid)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoy))
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return RegistroBienestar.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  static Future<void> guardar(RegistroBienestar registro) async {
    // Reemplaza el registro del día si ya existe
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final snap = await _db
        .collection('bienestar')
        .where('userId', isEqualTo: _uid)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoy))
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      await _db.collection('bienestar').doc(snap.docs.first.id).set(registro.toMap());
    } else {
      await _db.collection('bienestar').add(registro.toMap());
    }
  }

  // 0-100: riesgo de burnout promedio de 7 días
  static int calcularRiesgoBurnout(List<RegistroBienestar> registros) {
    if (registros.isEmpty) return 0;
    final sum = registros.fold<int>(0, (acc, r) => acc + r.puntajeBurnout);
    return (sum / registros.length).round();
  }

  static String nivelRiesgo(int riesgo) {
    if (riesgo < 25) return 'Bajo';
    if (riesgo < 50) return 'Moderado';
    if (riesgo < 75) return 'Alto';
    return 'Crítico';
  }

  static List<String> recomendaciones(int riesgo, List<RegistroBienestar> registros) {
    final recos = <String>[];
    if (registros.isEmpty) return ['Registra tu estado diario para obtener recomendaciones.'];

    final ultimo = registros.first;
    if (ultimo.nivelEstres >= 4) {
      recos.add('Tu estrés está alto. Prueba 5 minutos de respiración profunda antes de estudiar.');
    }
    if (!ultimo.descansoBien) {
      recos.add('El sueño afecta la memoria. Intenta dormir al menos 7 horas esta noche.');
    }
    if (ultimo.horasEstudio > 8) {
      recos.add('Más de 8 horas de estudio disminuyen la retención. Toma descansos cada 90 min.');
    }
    if (ultimo.estadoAnimo <= 2) {
      recos.add('Tu ánimo está bajo. Habla con alguien de confianza o tómate un descanso hoy.');
    }
    if (riesgo >= 75) {
      recos.add('🚨 Riesgo crítico: considera hablar con un consejero académico o de salud mental.');
    }
    if (recos.isEmpty) {
      recos.add('¡Vas muy bien! Mantén tus hábitos de sueño, estudio y descanso.');
    }
    return recos;
  }
}
