import 'package:cloud_firestore/cloud_firestore.dart';

enum EscalaNotas { escala20, escala10, escala5, escala4 }

extension EscalaNotasX on EscalaNotas {
  double get maximo {
    switch (this) {
      case EscalaNotas.escala20: return 20;
      case EscalaNotas.escala10: return 10;
      case EscalaNotas.escala5:  return 5;
      case EscalaNotas.escala4:  return 4;
    }
  }

  double get aprobacion {
    switch (this) {
      case EscalaNotas.escala20: return 11;
      case EscalaNotas.escala10: return 6;
      case EscalaNotas.escala5:  return 3;
      case EscalaNotas.escala4:  return 2;
    }
  }

  String get nombre {
    switch (this) {
      case EscalaNotas.escala20: return '0-20  (Perú, Venezuela)';
      case EscalaNotas.escala10: return '0-10  (México, España, Argentina)';
      case EscalaNotas.escala5:  return '0-5   (Colombia, Ecuador)';
      case EscalaNotas.escala4:  return 'GPA   (USA, Canadá)';
    }
  }

  String letra(double nota) {
    final p = nota / maximo;
    if (p >= 0.93) return 'A+';
    if (p >= 0.90) return 'A';
    if (p >= 0.87) return 'A-';
    if (p >= 0.83) return 'B+';
    if (p >= 0.80) return 'B';
    if (p >= 0.77) return 'B-';
    if (p >= 0.70) return 'C';
    if (p >= 0.60) return 'D';
    return 'F';
  }
}

class Calificacion {
  final String id;
  final String cursoId;
  final String cursoNombre;
  final String tipo; // 'Examen', 'Práctica', 'Proyecto', 'Tarea'
  final double nota;
  final double peso; // 0-100
  final DateTime fecha;
  final String userId;
  final String descripcion;

  const Calificacion({
    required this.id,
    required this.cursoId,
    required this.cursoNombre,
    required this.tipo,
    required this.nota,
    required this.peso,
    required this.fecha,
    required this.userId,
    this.descripcion = '',
  });

  Map<String, dynamic> toMap() => {
        'cursoId': cursoId,
        'cursoNombre': cursoNombre,
        'tipo': tipo,
        'nota': nota,
        'peso': peso,
        'fecha': Timestamp.fromDate(fecha),
        'userId': userId,
        'descripcion': descripcion,
      };

  factory Calificacion.fromMap(String id, Map<String, dynamic> map) {
    return Calificacion(
      id: id,
      cursoId: map['cursoId'] ?? '',
      cursoNombre: map['cursoNombre'] ?? '',
      tipo: map['tipo'] ?? 'Examen',
      nota: (map['nota'] ?? 0).toDouble(),
      peso: (map['peso'] ?? 100).toDouble(),
      fecha: map['fecha'] != null
          ? (map['fecha'] as Timestamp).toDate()
          : DateTime.now(),
      userId: map['userId'] ?? '',
      descripcion: map['descripcion'] ?? '',
    );
  }
}
