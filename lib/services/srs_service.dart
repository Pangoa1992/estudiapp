import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/flashcard_srs_model.dart';

class SRSService {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // SM-2 algorithm: calidad 0=Olvidé, 1=Difícil, 2=Regular, 3=Fácil
  static FlashcardSRS calcularSiguiente(FlashcardSRS card, int calidad) {
    const qMap = [0, 2, 3, 5];
    final q = qMap[calidad.clamp(0, 3)];

    double ef = card.facilidad + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (ef < 1.3) ef = 1.3;

    int intervalo;
    int reps;
    if (q < 3) {
      reps = 0;
      intervalo = 1;
    } else {
      reps = card.repeticiones + 1;
      if (reps == 1) {
        intervalo = 1;
      } else if (reps == 2) {
        intervalo = 6;
      } else {
        intervalo = (card.intervalo * ef).round();
      }
    }

    return card.copyWith(
      repeticiones: reps,
      facilidad: ef,
      intervalo: intervalo,
      proximaRevision: DateTime.now().add(Duration(days: intervalo)),
    );
  }

  static Future<void> guardar(FlashcardSRS card) async {
    if (card.id.isEmpty) {
      await _db.collection('flashcards_srs').add(card.toMap());
    } else {
      await _db.collection('flashcards_srs').doc(card.id).set(card.toMap());
    }
  }

  static Future<void> eliminar(String id) async {
    await _db.collection('flashcards_srs').doc(id).delete();
  }

  static Future<void> registrarRespuesta(FlashcardSRS card, int calidad) async {
    final actualizada = calcularSiguiente(card, calidad);
    await _db.collection('flashcards_srs').doc(card.id).update({
      'repeticiones': actualizada.repeticiones,
      'facilidad': actualizada.facilidad,
      'intervalo': actualizada.intervalo,
      'proximaRevision': Timestamp.fromDate(actualizada.proximaRevision),
    });
  }

  static Stream<List<FlashcardSRS>> streamTodas() {
    return _db
        .collection('flashcards_srs')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => FlashcardSRS.fromMap(d.id, d.data()))
            .toList());
  }

  static Stream<List<FlashcardSRS>> streamParaHoy() {
    final limite = DateTime.now();
    final manana = DateTime(limite.year, limite.month, limite.day + 1);
    return _db
        .collection('flashcards_srs')
        .where('userId', isEqualTo: _uid)
        .where('proximaRevision', isLessThan: Timestamp.fromDate(manana))
        .snapshots()
        .map((s) => s.docs
            .map((d) => FlashcardSRS.fromMap(d.id, d.data()))
            .toList());
  }

  static Future<List<FlashcardSRS>> obtenerParaHoyPorCurso(String cursoId) async {
    final manana = DateTime.now();
    final limite = DateTime(manana.year, manana.month, manana.day + 1);
    final snap = await _db
        .collection('flashcards_srs')
        .where('userId', isEqualTo: _uid)
        .where('cursoId', isEqualTo: cursoId)
        .where('proximaRevision', isLessThan: Timestamp.fromDate(limite))
        .get();
    return snap.docs.map((d) => FlashcardSRS.fromMap(d.id, d.data())).toList();
  }
}
