class Mision {
  final String id;
  final String tipo;
  final String descripcion;
  final int objetivo;
  final int recompensaMonedas;
  final int recompensaXp;
  int progreso;
  bool completada;
  bool reclamada;

  Mision({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.objetivo,
    required this.recompensaMonedas,
    required this.recompensaXp,
    this.progreso = 0,
    this.completada = false,
    this.reclamada = false,
  });

  double get porcentaje =>
      objetivo > 0 ? (progreso / objetivo).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'tipo': tipo,
        'descripcion': descripcion,
        'objetivo': objetivo,
        'recompensaMonedas': recompensaMonedas,
        'recompensaXp': recompensaXp,
        'progreso': progreso,
        'completada': completada,
        'reclamada': reclamada,
      };

  factory Mision.fromMap(Map<String, dynamic> m) => Mision(
        id: m['id'] as String,
        tipo: m['tipo'] as String,
        descripcion: m['descripcion'] as String,
        objetivo: (m['objetivo'] as num).toInt(),
        recompensaMonedas: (m['recompensaMonedas'] as num).toInt(),
        recompensaXp: (m['recompensaXp'] as num).toInt(),
        progreso: (m['progreso'] as num? ?? 0).toInt(),
        completada: m['completada'] as bool? ?? false,
        reclamada: m['reclamada'] as bool? ?? false,
      );
}
