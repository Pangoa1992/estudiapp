import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});
  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  final _db = FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  bool _cargando = true;

  // Minutos Pomodoro por día (7 días) → "yyyy-MM-dd": minutos
  Map<String, int> _minutosPorDia = {};
  int _totalMinutosSemanales = 0;

  // Notas por materia (de exámenes con nota registrada)
  Map<String, double> _notasPorMateria = {};
  String _materiaFuerte = '';
  String _materiaDebil = '';
  double _notaFuerte = 0;
  double _notaDebil = 20;

  // Historial de racha (últimos 30 días con datos)
  List<int> _historialRacha = [];

  // Resumen semanal
  int _simulacrosSemanales = 0;
  double _notaPromedioSemanal = 0;
  int _logrosTotal = 0;

  static const _diasCortos = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  String _fechaStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _diaCorto(String fechaStr) {
    try {
      final p = fechaStr.split('-');
      final d =
          DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      return _diasCortos[d.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  Future<void> _cargarTodo() async {
    if (_user == null) {
      if (mounted) setState(() => _cargando = false);
      return;
    }
    try {
      await Future.wait([
        _cargarMinutos(),
        _cargarNotasPorMateria(),
        _cargarHistorialRacha(),
        _cargarResumenSemanal(),
      ]);
    } catch (e) {
      // Sin internet los .get() lanzan; se muestran los datos que sí cargaron
      // y se evita dejar el spinner girando para siempre (o un crash fatal).
      debugPrint('[Estadisticas] error al cargar: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cargarMinutos() async {
    final hoy = DateTime.now();
    final hace6 = DateTime(hoy.year, hoy.month, hoy.day)
        .subtract(const Duration(days: 6));

    final snap = await _db
        .collection('sesiones_pomodoro')
        .where('userId', isEqualTo: _user!.uid)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(hace6))
        .get();

    final mapa = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      mapa[_fechaStr(hoy.subtract(Duration(days: i)))] = 0;
    }
    for (final doc in snap.docs) {
      final d = doc.data();
      final fs = d['fechaStr'] as String? ?? '';
      final m = (d['minutos'] as num? ?? 0).toInt();
      if (mapa.containsKey(fs)) mapa[fs] = mapa[fs]! + m;
    }
    _minutosPorDia = mapa;
    _totalMinutosSemanales = mapa.values.fold(0, (a, b) => a + b);
  }

  Future<void> _cargarNotasPorMateria() async {
    final snap = await _db
        .collection('examenes')
        .where('userId', isEqualTo: _user!.uid)
        .where('completado', isEqualTo: true)
        .get();

    final porCurso = <String, List<double>>{};
    for (final doc in snap.docs) {
      final d = doc.data();
      final nota = d['nota'];
      if (nota == null) continue;
      final curso = (d['curso'] as String? ?? '').trim();
      if (curso.isEmpty) continue;
      porCurso.putIfAbsent(curso, () => []).add((nota as num).toDouble());
    }

    final promedios = <String, double>{
      for (final e in porCurso.entries)
        e.key: e.value.reduce((a, b) => a + b) / e.value.length,
    };

    _notasPorMateria = promedios;

    if (promedios.isNotEmpty) {
      final sorted = promedios.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      _materiaDebil = sorted.first.key;
      _notaDebil = sorted.first.value;
      _materiaFuerte = sorted.last.key;
      _notaFuerte = sorted.last.value;
    }
  }

  Future<void> _cargarHistorialRacha() async {
    final hoy = DateTime.now();
    final hace29 = DateTime(hoy.year, hoy.month, hoy.day)
        .subtract(const Duration(days: 29));

    final snap = await _db
        .collection('historial_racha')
        .where('userId', isEqualTo: _user!.uid)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(hace29))
        .get();

    final porFecha = <String, int>{};
    for (final doc in snap.docs) {
      final d = doc.data();
      final fs = d['fechaStr'] as String? ?? '';
      final r = (d['racha'] as num? ?? 0).toInt();
      porFecha[fs] = r;
    }

    final valores = <int>[];
    for (int i = 29; i >= 0; i--) {
      final fs = _fechaStr(hoy.subtract(Duration(days: i)));
      if (porFecha.containsKey(fs)) valores.add(porFecha[fs]!);
    }
    _historialRacha = valores;
  }

  Future<void> _cargarResumenSemanal() async {
    final hoy = DateTime.now();
    final lunes = DateTime(hoy.year, hoy.month, hoy.day)
        .subtract(Duration(days: hoy.weekday - 1));

    final snapSim = await _db
        .collection('pdf_resultados')
        .where('userId', isEqualTo: _user!.uid)
        .where('fechaFin',
            isGreaterThanOrEqualTo: Timestamp.fromDate(lunes))
        .get();

    _simulacrosSemanales = snapSim.docs.length;
    if (snapSim.docs.isNotEmpty) {
      final pcts = snapSim.docs
          .map((d) => (d.data()['porcentaje'] as num? ?? 0).toDouble())
          .toList();
      _notaPromedioSemanal = pcts.reduce((a, b) => a + b) / pcts.length;
    }

    try {
      final logrosDoc =
          await _db.collection('logros').doc(_user!.uid).get();
      if (logrosDoc.exists) {
        _logrosTotal =
            (logrosDoc.data()?['obtenidos'] as List? ?? []).length;
      }
    } catch (_) {}
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        title: const Text('Estadísticas 📊',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _cargando
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF7C6AF7)))
          : RefreshIndicator(
              onRefresh: () async {
                setState(() => _cargando = true);
                await _cargarTodo();
              },
              color: const Color(0xFF7C6AF7),
              backgroundColor: const Color(0xFF1E1E2A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMinutosSemanales(),
                    const SizedBox(height: 24),
                    _buildProgresoPorMateria(),
                    const SizedBox(height: 24),
                    _buildEvolucionRacha(),
                    const SizedBox(height: 24),
                    _buildResumenSemanal(),
                    const SizedBox(height: 24),
                    _buildMateriaDestacada(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── SECCIÓN 1: Minutos Pomodoro ───────────────────────────────────────────

  Widget _buildMinutosSemanales() {
    final claves = _minutosPorDia.keys.toList();
    final valores = _minutosPorDia.values.toList();
    final maxVal =
        valores.isEmpty ? 1 : valores.reduce(max).clamp(1, 99999);
    final horasStr =
        (_totalMinutosSemanales / 60).toStringAsFixed(1);

    return _seccion(
      titulo: 'Minutos estudiados',
      subtitulo: 'Últimos 7 días  •  ${horasStr}h esta semana',
      child: SizedBox(
        height: 155,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(claves.length, (i) {
            final key = claves[i];
            final val = _minutosPorDia[key] ?? 0;
            final frac = val / maxVal;
            final isHoy = key == _fechaStr(DateTime.now());
            final barColor = isHoy
                ? const Color(0xFF7C6AF7)
                : const Color(0xFF3A3A5A);
            final topColor = isHoy
                ? const Color(0xFF9D8FFF)
                : const Color(0xFF4A4A7A);

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (val > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${val}m',
                        style: TextStyle(
                            color: isHoy
                                ? const Color(0xFF7C6AF7)
                                : Colors.white38,
                            fontSize: 9,
                            fontWeight: FontWeight.w600)),
                  ),
                Container(
                  width: 30,
                  height: max(6.0, frac * 100),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [barColor, topColor],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _diaCorto(key),
                  style: TextStyle(
                    color: isHoy
                        ? const Color(0xFF7C6AF7)
                        : Colors.white38,
                    fontSize: 11,
                    fontWeight: isHoy
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ─── SECCIÓN 2: Progreso por materia ──────────────────────────────────────

  Widget _buildProgresoPorMateria() {
    if (_notasPorMateria.isEmpty) {
      return _seccion(
        titulo: 'Rendimiento por materia',
        subtitulo: 'Promedio de notas (escala 0–20)',
        child: _emptyState(
            'Registra las notas de tus exámenes\npara ver el rendimiento por materia'),
      );
    }

    final sorted = _notasPorMateria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _seccion(
      titulo: 'Rendimiento por materia',
      subtitulo: 'Promedio de notas (escala 0–20)',
      child: Column(
        children: sorted.map((e) {
          final pct = (e.value / 20).clamp(0.0, 1.0);
          final color = e.value >= 14
              ? const Color(0xFF5DE0C5)
              : e.value >= 11
                  ? const Color(0xFFF7A26A)
                  : const Color(0xFFF7584A);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(e.key,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    Text(e.value.toStringAsFixed(1),
                        style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF2E2E3E),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── SECCIÓN 3: Evolución de la racha ─────────────────────────────────────

  Widget _buildEvolucionRacha() {
    return _seccion(
      titulo: 'Evolución de la racha',
      subtitulo: 'Últimos 30 días',
      child: _historialRacha.length < 2
          ? _emptyState(
              'Abre la app cada día para ver\nla evolución de tu racha aquí')
          : SizedBox(
              height: 130,
              child: CustomPaint(
                size: const Size(double.infinity, 130),
                painter: _LineaPainter(
                  valores: _historialRacha
                      .map((v) => v.toDouble())
                      .toList(),
                  color: const Color(0xFFF7584A),
                ),
              ),
            ),
    );
  }

  // ─── SECCIÓN 4: Resumen semanal ────────────────────────────────────────────

  Widget _buildResumenSemanal() {
    final horasStr =
        (_totalMinutosSemanales / 60).toStringAsFixed(1);
    final notaStr = _simulacrosSemanales > 0
        ? '${_notaPromedioSemanal.toStringAsFixed(0)}%'
        : '–';

    return _seccion(
      titulo: 'Resumen semanal',
      subtitulo: 'Desde el lunes hasta hoy',
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: [
          _statCard('⏱️', 'Horas estudiadas', '${horasStr}h',
              const Color(0xFF7C6AF7)),
          _statCard('📝', 'Simulacros', '$_simulacrosSemanales',
              const Color(0xFF5DE0C5)),
          _statCard(
              '🎯', 'Nota promedio', notaStr, const Color(0xFFF7A26A)),
          _statCard(
              '🏆', 'Logros totales', '$_logrosTotal', const Color(0xFFFFD700)),
        ],
      ),
    );
  }

  // ─── SECCIÓN 5: Materia más fuerte y más débil ────────────────────────────

  Widget _buildMateriaDestacada() {
    if (_notasPorMateria.length < 2) {
      return _seccion(
        titulo: 'Materia más fuerte y débil',
        subtitulo: 'Detectado automáticamente por notas',
        child: _emptyState(
            'Necesitas al menos 2 materias\ncon notas registradas'),
      );
    }

    return _seccion(
      titulo: 'Materia más fuerte y débil',
      subtitulo: 'Detectado automáticamente por notas',
      child: Row(
        children: [
          Expanded(
            child: _materiaCard(
              '💪 Más fuerte',
              _materiaFuerte,
              _notaFuerte,
              const Color(0xFF5DE0C5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _materiaCard(
              '⚠️ Más débil',
              _materiaDebil,
              _notaDebil,
              const Color(0xFFF7584A),
            ),
          ),
        ],
      ),
    );
  }

  // ─── WIDGETS AUXILIARES ────────────────────────────────────────────────────

  Widget _seccion({
    required String titulo,
    required String subtitulo,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitulo,
            style:
                const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2E2E3E)),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _statCard(
      String emoji, String label, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(valor,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _materiaCard(
      String titulo, String materia, double nota, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(materia,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${nota.toStringAsFixed(1)} / 20',
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _emptyState(String mensaje) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white38, fontSize: 13, height: 1.6)),
      ),
    );
  }
}

// ─── CustomPainter: Gráfico de línea para la racha ────────────────────────────

class _LineaPainter extends CustomPainter {
  final List<double> valores;
  final Color color;

  const _LineaPainter({required this.valores, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.length < 2) return;

    final maxVal = valores.reduce(max);
    if (maxVal == 0) return;

    const padTop = 20.0;
    const padBottom = 20.0;
    const padH = 4.0;
    final drawW = size.width - padH * 2;
    final drawH = size.height - padTop - padBottom;

    Offset pt(int i) {
      final x = padH + (i / (valores.length - 1)) * drawW;
      final y = padTop + drawH - (valores[i] / maxVal) * drawH * 0.9;
      return Offset(x, y);
    }

    // Área de relleno
    final fillPath = Path()..moveTo(pt(0).dx, size.height - padBottom);
    for (int i = 0; i < valores.length; i++) {
      fillPath.lineTo(pt(i).dx, pt(i).dy);
    }
    fillPath
      ..lineTo(pt(valores.length - 1).dx, size.height - padBottom)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha:0.28),
            color.withValues(alpha:0.0),
          ],
        ).createShader(
            Rect.fromLTWH(0, padTop, size.width, drawH))
        ..style = PaintingStyle.fill,
    );

    // Línea principal
    final linePath = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (int i = 1; i < valores.length; i++) {
      linePath.lineTo(pt(i).dx, pt(i).dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Puntos
    final bgPaint = Paint()
      ..color = const Color(0xFF1E1E2A)
      ..style = PaintingStyle.fill;
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < valores.length; i++) {
      canvas.drawCircle(pt(i), 4, bgPaint);
      canvas.drawCircle(pt(i), 3, dotPaint);
    }

    // Etiquetas de valor en primer, último y punto máximo
    final maxIdx =
        valores.indexOf(valores.reduce(max));
    final labelSet = {0, maxIdx, valores.length - 1};

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final i in labelSet) {
      final label = '${valores[i].toInt()}d';
      tp.text = TextSpan(
        text: label,
        style: TextStyle(
            color: color.withValues(alpha:0.85),
            fontSize: 9,
            fontWeight: FontWeight.w600),
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(pt(i).dx - tp.width / 2, pt(i).dy - 16),
      );
    }
  }

  @override
  bool shouldRepaint(_LineaPainter old) => old.valores != valores;
}
