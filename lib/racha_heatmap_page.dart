import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RachaHeatmapPage extends StatefulWidget {
  const RachaHeatmapPage({super.key});

  @override
  State<RachaHeatmapPage> createState() => _RachaHeatmapPageState();
}

class _RachaHeatmapPageState extends State<RachaHeatmapPage> {
  final _user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;

  // 'YYYY-MM-DD' -> cantidad de hábitos completados ese día
  final Map<String, int> _actividad = {};
  bool _cargando = true;
  int _rachaActual = 0;
  int _rachaMaxima = 0;
  int _diasActivos = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (_user == null) return;

    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    // Filtramos el historial a los últimos ~3 meses en Firestore para evitar
    // cargar miles de documentos. El campo 'mes' tiene formato 'YYYY-MM'.
    final cutoff = hoy.subtract(const Duration(days: 92));
    final cutoffMes =
        '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}';

    final snap = await _db
        .collection('historial_habitos')
        .where('userId', isEqualTo: _user.uid)
        .where('mes', isGreaterThanOrEqualTo: cutoffMes)
        .get();

    final Map<String, int> actividadLocal = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      final mes = data['mes'] as String;
      final dia = (data['dia'] as int).toString().padLeft(2, '0');
      final key = '$mes-$dia';
      actividadLocal[key] = (actividadLocal[key] ?? 0) + 1;
    }

    // Solo los últimos 90 días para el mapa visual
    final Map<String, int> actividadVisual = {};
    for (final entry in actividadLocal.entries) {
      final d = DateTime.tryParse(entry.key);
      if (d != null && !d.isAfter(hoy) && hoy.difference(d).inDays <= 89) {
        actividadVisual[entry.key] = entry.value;
      }
    }

    // La racha máxima histórica ya está almacenada en Firestore y se
    // actualiza en tiempo real por RachaService. Confiamos en ese valor.
    final perfil = await _db.collection('perfiles').doc(_user.uid).get();
    final int rachaMaximaFirestore = perfil.data()?['rachaMaxima'] ?? 0;

    setState(() {
      _actividad.addAll(actividadVisual);
      _diasActivos = actividadLocal.keys.where((k) {
        final d = DateTime.tryParse(k);
        return d != null && !d.isAfter(hoy);
      }).length;
      _rachaActual = perfil.data()?['racha'] ?? 0;
      _rachaMaxima = rachaMaximaFirestore;
      _cargando = false;
    });
  }

  Color _colorCelda(int count, bool esFuturo) {
    if (esFuturo) return Colors.transparent;
    if (count == 0) return const Color(0xFF1A1A26);
    if (count == 1) return const Color(0xFF3D2FA0).withOpacity(0.7);
    if (count == 2) return const Color(0xFF5A4ED4);
    if (count <= 4) return const Color(0xFF7C6AF7);
    return const Color(0xFFA89BFF);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        title: const Text('Historial de racha',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C6AF7)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEstadisticas(),
                  const SizedBox(height: 28),
                  _buildHeatmap(),
                  const SizedBox(height: 16),
                  _buildLeyenda(),
                  const SizedBox(height: 28),
                  _buildResumenMensual(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildEstadisticas() {
    return Row(
      children: [
        _statCard('🔥', 'Racha actual', '$_rachaActual días', const Color(0xFFF7584A)),
        const SizedBox(width: 10),
        _statCard('👑', 'Racha máxima', '$_rachaMaxima días', const Color(0xFFFFD700)),
        const SizedBox(width: 10),
        _statCard('📅', 'Días activos', '$_diasActivos', const Color(0xFF5DE0C5)),
      ],
    );
  }

  Widget _statCard(String emoji, String label, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(valor,
                style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 9),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap() {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicio90 = hoy.subtract(const Duration(days: 89));
    final inicioGrid = inicio90.subtract(Duration(days: inicio90.weekday - 1));

    final semanas = <List<DateTime>>[];
    var cursor = inicioGrid;
    while (!cursor.isAfter(hoy)) {
      semanas.add(List.generate(7, (i) => cursor.add(Duration(days: i))));
      cursor = cursor.add(const Duration(days: 7));
    }

    const diasLabel = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACTIVIDAD — ÚLTIMOS 90 DÍAS',
            style: TextStyle(
                color: Colors.white70, fontSize: 11,
                fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        _buildFilaMeses(semanas),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: List.generate(7, (i) => SizedBox(
                height: 14,
                width: 14,
                child: Center(
                  child: Text(diasLabel[i],
                      style: const TextStyle(color: Colors.white38, fontSize: 9)),
                ),
              )),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: semanas.map((semana) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Column(
                        children: semana.map((fecha) {
                          final key =
                              '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
                          final count = _actividad[key] ?? 0;
                          final esFuturo = fecha.isAfter(hoy);
                          final esHoy = fecha.year == hoy.year &&
                              fecha.month == hoy.month &&
                              fecha.day == hoy.day;

                          return Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: _colorCelda(count, esFuturo),
                              borderRadius: BorderRadius.circular(2),
                              border: esHoy
                                  ? Border.all(color: const Color(0xFF7C6AF7), width: 1.5)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilaMeses(List<List<DateTime>> semanas) {
    final labels = <Widget>[const SizedBox(width: 18)];
    String? ultimoMes;

    for (final semana in semanas) {
      final primera = semana.first;
      final mesKey = '${primera.year}-${primera.month}';
      if (mesKey != ultimoMes) {
        ultimoMes = mesKey;
        labels.add(SizedBox(
          width: 15,
          child: Text(_mesCorto(primera.month),
              style: const TextStyle(color: Colors.white54, fontSize: 9)),
        ));
      } else {
        labels.add(const SizedBox(width: 15));
      }
    }

    return Row(children: labels);
  }

  String _mesCorto(int m) {
    const n = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return n[m];
  }

  Widget _buildLeyenda() {
    final colores = [
      const Color(0xFF1A1A26),
      const Color(0xFF3D2FA0).withOpacity(0.7),
      const Color(0xFF5A4ED4),
      const Color(0xFF7C6AF7),
      const Color(0xFFA89BFF),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Menos', style: TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(width: 6),
        ...colores.map((c) => Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(left: 3),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
        const SizedBox(width: 6),
        const Text('Más', style: TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildResumenMensual() {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    final meses = <Map<String, dynamic>>[];
    for (int i = 0; i < 3; i++) {
      final f = DateTime(ahora.year, ahora.month - i, 1);
      final mesKey = '${f.year}-${f.month.toString().padLeft(2, '0')}';
      final diasEnMes = i == 0 ? ahora.day : DateTime(f.year, f.month + 1, 0).day;

      int diasActivos = 0;
      int total = 0;

      for (final entry in _actividad.entries) {
        if (!entry.key.startsWith(mesKey)) continue;
        final date = DateTime.tryParse(entry.key);
        if (date == null || date.isAfter(hoy)) continue;
        diasActivos++;
        total += entry.value;
      }

      meses.add({
        'nombre': _nombreMes(f.month),
        'diasActivos': diasActivos,
        'diasEnMes': diasEnMes,
        'total': total,
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RESUMEN POR MES',
            style: TextStyle(
                color: Colors.white70, fontSize: 11,
                fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...meses.map((m) {
          final pct = m['diasEnMes'] > 0
              ? (m['diasActivos'] as int) / (m['diasEnMes'] as int)
              : 0.0;
          final color = pct >= 0.7
              ? const Color(0xFF5DE0C5)
              : pct >= 0.4
                  ? const Color(0xFFF7A26A)
                  : const Color(0xFFF7584A);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(m['nombre'] as String,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${m['diasActivos']}/${m['diasEnMes']} días activos',
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${m['total']} completaciones totales',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _nombreMes(int m) {
    const n = ['', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return n[m];
  }
}
