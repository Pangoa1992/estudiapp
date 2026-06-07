import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calificacion_model.dart';

class GpaService {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  static const _escalaKey = 'escala_notas_idx';

  static Future<EscalaNotas> getEscala() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_escalaKey) ?? 0;
    return EscalaNotas.values[idx.clamp(0, EscalaNotas.values.length - 1)];
  }

  static Future<void> setEscala(EscalaNotas escala) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_escalaKey, escala.index);
  }

  static double calcularPonderado(List<Calificacion> calificaciones) {
    if (calificaciones.isEmpty) return 0;
    double sumaPesada = 0;
    double sumaPesos = 0;
    for (final c in calificaciones) {
      sumaPesada += c.nota * c.peso;
      sumaPesos += c.peso;
    }
    return sumaPesos == 0 ? 0 : sumaPesada / sumaPesos;
  }

  static double calcularNecesaria({
    required List<Calificacion> actuales,
    required double meta,
    required double pesoRestante,
    required EscalaNotas escala,
  }) {
    if (pesoRestante <= 0) return 0;
    double sumaPesada = 0;
    double sumaPesos = 0;
    for (final c in actuales) {
      sumaPesada += c.nota * c.peso;
      sumaPesos += c.peso;
    }
    final totalPeso = sumaPesos + pesoRestante;
    final necesaria = (meta * totalPeso - sumaPesada) / pesoRestante;
    return necesaria.clamp(0, escala.maximo);
  }

  static Stream<List<Calificacion>> streamPorCurso(String cursoId) {
    return _db
        .collection('calificaciones')
        .where('userId', isEqualTo: _uid)
        .where('cursoId', isEqualTo: cursoId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => Calificacion.fromMap(d.id, d.data())).toList());
  }

  static Stream<List<Calificacion>> streamTodas() {
    return _db
        .collection('calificaciones')
        .where('userId', isEqualTo: _uid)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => Calificacion.fromMap(d.id, d.data())).toList());
  }

  static Future<void> agregar(Calificacion c) async {
    await _db.collection('calificaciones').add(c.toMap());
  }

  static Future<void> eliminar(String id) async {
    await _db.collection('calificaciones').doc(id).delete();
  }
}
