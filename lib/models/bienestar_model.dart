import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroBienestar {
  final String id;
  final String userId;
  final DateTime fecha;
  final int estadoAnimo; // 1-5
  final int nivelEstres; // 1-5
  final double horasEstudio;
  final bool descansoBien;
  final String nota;

  const RegistroBienestar({
    required this.id,
    required this.userId,
    required this.fecha,
    required this.estadoAnimo,
    required this.nivelEstres,
    required this.horasEstudio,
    required this.descansoBien,
    this.nota = '',
  });

  // 0-100: higher = more burnout risk
  int get puntajeBurnout {
    int score = 0;
    score += (5 - estadoAnimo) * 12; // bad mood → +burnout
    score += (nivelEstres - 1) * 12; // high stress → +burnout
    if (!descansoBien) score += 20;
    if (horasEstudio > 8) score += 20;
    if (horasEstudio > 10) score += 10;
    if (horasEstudio < 1) score += 10; // doing nothing also a signal
    return score.clamp(0, 100);
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'fecha': Timestamp.fromDate(fecha),
        'estadoAnimo': estadoAnimo,
        'nivelEstres': nivelEstres,
        'horasEstudio': horasEstudio,
        'descansoBien': descansoBien,
        'nota': nota,
      };

  factory RegistroBienestar.fromMap(String id, Map<String, dynamic> map) {
    return RegistroBienestar(
      id: id,
      userId: map['userId'] ?? '',
      fecha: map['fecha'] != null
          ? (map['fecha'] as Timestamp).toDate()
          : DateTime.now(),
      estadoAnimo: map['estadoAnimo'] ?? 3,
      nivelEstres: map['nivelEstres'] ?? 3,
      horasEstudio: (map['horasEstudio'] ?? 0).toDouble(),
      descansoBien: map['descansoBien'] ?? true,
      nota: map['nota'] ?? '',
    );
  }
}
