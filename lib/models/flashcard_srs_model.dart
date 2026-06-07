import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardSRS {
  final String id;
  final String pregunta;
  final String respuesta;
  final String cursoId;
  final String cursoNombre;
  final String userId;
  final int repeticiones;
  final double facilidad; // SM-2 ease factor, min 1.3, starts 2.5
  final int intervalo; // days until next review
  final DateTime proximaRevision;
  final DateTime creadoEn;

  const FlashcardSRS({
    required this.id,
    required this.pregunta,
    required this.respuesta,
    required this.cursoId,
    required this.cursoNombre,
    required this.userId,
    this.repeticiones = 0,
    this.facilidad = 2.5,
    this.intervalo = 1,
    required this.proximaRevision,
    required this.creadoEn,
  });

  bool get esParaHoy {
    final hoy = DateTime.now();
    final limite = DateTime(hoy.year, hoy.month, hoy.day + 1);
    return proximaRevision.isBefore(limite);
  }

  FlashcardSRS copyWith({
    String? id,
    String? pregunta,
    String? respuesta,
    String? cursoId,
    String? cursoNombre,
    String? userId,
    int? repeticiones,
    double? facilidad,
    int? intervalo,
    DateTime? proximaRevision,
    DateTime? creadoEn,
  }) {
    return FlashcardSRS(
      id: id ?? this.id,
      pregunta: pregunta ?? this.pregunta,
      respuesta: respuesta ?? this.respuesta,
      cursoId: cursoId ?? this.cursoId,
      cursoNombre: cursoNombre ?? this.cursoNombre,
      userId: userId ?? this.userId,
      repeticiones: repeticiones ?? this.repeticiones,
      facilidad: facilidad ?? this.facilidad,
      intervalo: intervalo ?? this.intervalo,
      proximaRevision: proximaRevision ?? this.proximaRevision,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  Map<String, dynamic> toMap() => {
        'pregunta': pregunta,
        'respuesta': respuesta,
        'cursoId': cursoId,
        'cursoNombre': cursoNombre,
        'userId': userId,
        'repeticiones': repeticiones,
        'facilidad': facilidad,
        'intervalo': intervalo,
        'proximaRevision': Timestamp.fromDate(proximaRevision),
        'creadoEn': Timestamp.fromDate(creadoEn),
      };

  factory FlashcardSRS.fromMap(String id, Map<String, dynamic> map) {
    return FlashcardSRS(
      id: id,
      pregunta: map['pregunta'] ?? '',
      respuesta: map['respuesta'] ?? '',
      cursoId: map['cursoId'] ?? '',
      cursoNombre: map['cursoNombre'] ?? '',
      userId: map['userId'] ?? '',
      repeticiones: map['repeticiones'] ?? 0,
      facilidad: (map['facilidad'] ?? 2.5).toDouble(),
      intervalo: map['intervalo'] ?? 1,
      proximaRevision: map['proximaRevision'] != null
          ? (map['proximaRevision'] as Timestamp).toDate()
          : DateTime.now(),
      creadoEn: map['creadoEn'] != null
          ? (map['creadoEn'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
