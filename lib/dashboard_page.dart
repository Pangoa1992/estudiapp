import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        title: const Text('Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Color(0xFF5DE0C5)),
            tooltip: 'Exportar datos',
            onPressed: _exportarDatos,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResumenSemana(),
            const SizedBox(height: 24),
            _buildEstadisticasTester(), // ← NUEVO para el jurado
            const SizedBox(height: 24),
            _buildGraficoSemana(),
            const SizedBox(height: 24),
            _buildExamenesProximos(),
            const SizedBox(height: 24),
            _buildHabitosMasCompletados(),
          ],
        ),
      ),
    );
  }

  // ── NUEVO: Estadísticas para el jurado ──
  Widget _buildEstadisticasTester() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ESTADÍSTICAS DE USO',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        StreamBuilder<DocumentSnapshot>(
          stream: _db.collection('perfiles').doc(user!.uid).snapshots(),
          builder: (context, perfilSnapshot) {
            final perfilData = perfilSnapshot.data?.data() as Map<String, dynamic>?;
            final racha = perfilData?['racha'] ?? 0;
            final rachaMaxima = perfilData?['rachaMaxima'] ?? 0;
            final ultimaVisita = perfilData?['ultimaVisita'];

            return StreamBuilder<QuerySnapshot>(
              stream: _db.collection('habitos').where('userId', isEqualTo: user!.uid).snapshots(),
              builder: (context, habitosSnapshot) {
                final totalHabitos = habitosSnapshot.data?.docs.length ?? 0;
                final habitosHoy = habitosSnapshot.data?.docs
                    .where((d) => (d.data() as Map)['done'] == true)
                    .length ?? 0;

                return StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('examenes').where('userId', isEqualTo: user!.uid).snapshots(),
                  builder: (context, examenesSnapshot) {
                    final totalExamenes = examenesSnapshot.data?.docs.length ?? 0;

                    return StreamBuilder<DocumentSnapshot>(
                      stream: _db.collection('logros').doc(user!.uid).snapshots(),
                      builder: (context, logrosSnapshot) {
                        final logrosObtenidos = logrosSnapshot.data?.exists == true
                            ? List.from(
                                (logrosSnapshot.data!.data() as Map)['obtenidos'] ?? [],
                              ).length
                            : 0;

                        // Usar primeraVisita para días de uso; ultimaVisita como fallback
                        final primeraVisitaRaw = perfilData?['primeraVisita'];
                        String diasUsando = '-';
                        if (primeraVisitaRaw != null) {
                          final primera = (primeraVisitaRaw as Timestamp).toDate();
                          final diff = DateTime.now().difference(primera).inDays + 1;
                          diasUsando = '$diff días';
                        }

                        return Column(
                          children: [
                            // Fila 1
                            Row(children: [
                              _statCard('Racha actual', '$racha días', Icons.local_fire_department, const Color(0xFFF7584A)),
                              const SizedBox(width: 12),
                              _statCard('Racha máxima', '$rachaMaxima días', Icons.emoji_events, const Color(0xFFFFD700)),
                            ]),
                            const SizedBox(height: 12),
                            // Fila 2
                            Row(children: [
                              _statCard('Hábitos creados', '$totalHabitos', Icons.check_circle, const Color(0xFF7C6AF7)),
                              const SizedBox(width: 12),
                              _statCard('Completados hoy', '$habitosHoy/$totalHabitos', Icons.today, const Color(0xFF5DE0C5)),
                            ]),
                            const SizedBox(height: 12),
                            // Fila 3
                            Row(children: [
                              _statCard('Exámenes', '$totalExamenes', Icons.school, const Color(0xFFF7A26A)),
                              const SizedBox(width: 12),
                              _statCard('Logros', '$logrosObtenidos/10', Icons.emoji_events, const Color(0xFFFFD700)),
                            ]),
                            const SizedBox(height: 12),
                            // Fila 4
                            Row(children: [
                              _statCard('Usando la app', diasUsando, Icons.calendar_month, const Color(0xFF5DE0C5)),
                              const SizedBox(width: 12),
                              _statCard('Hábitos mes', '$habitosHoy completados', Icons.bar_chart, const Color(0xFF7C6AF7)),
                            ]),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _statCard(String label, String valor, IconData icono, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icono, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(valor, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportarDatos() async {
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: Color(0xFF1E1E2A),
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFF5DE0C5)),
            SizedBox(width: 16),
            Text('Preparando exportación…', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      final ahora = DateTime.now();
      final sb = StringBuffer();

      sb.writeln('EstudiApp — Exportación de datos');
      sb.writeln('Fecha: ${ahora.day}/${ahora.month}/${ahora.year}');
      sb.writeln('');

      // ── Hábitos activos ──
      final habitosSnap = await _db.collection('habitos').where('userId', isEqualTo: user!.uid).get();
      sb.writeln('═══════════════════════════════');
      sb.writeln('HÁBITOS (${habitosSnap.docs.length} registrados)');
      sb.writeln('Nombre,Hora,Estado hoy');
      for (final doc in habitosSnap.docs) {
        final d = doc.data();
        final nombre = (d['nombre'] ?? '').toString().replaceAll(',', ';');
        final hora = (d['hora'] ?? '').toString();
        final done = d['done'] == true ? 'Completado' : 'Pendiente';
        sb.writeln('$nombre,$hora,$done');
      }
      sb.writeln('');

      // ── Historial hábitos (este mes) ──
      final mes = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}';
      final histSnap = await _db.collection('historial_habitos')
          .where('userId', isEqualTo: user!.uid)
          .where('mes', isEqualTo: mes)
          .get();

      final diasActivosMes = histSnap.docs
          .map((d) => (d.data())['dia'] as int)
          .toSet()
          .length;

      sb.writeln('═══════════════════════════════');
      sb.writeln('ACTIVIDAD ESTE MES ($mes)');
      sb.writeln('Días activos: $diasActivosMes/${ahora.day}');
      sb.writeln('Completaciones totales: ${histSnap.docs.length}');
      sb.writeln('');

      // ── Exámenes con calificación ──
      final examenesSnap = await _db.collection('examenes')
          .where('userId', isEqualTo: user!.uid)
          .where('completado', isEqualTo: true)
          .get();

      final conNota = examenesSnap.docs.where((d) => (d.data())['nota'] != null).toList();

      sb.writeln('═══════════════════════════════');
      sb.writeln('CALIFICACIONES (${conNota.length} exámenes)');
      sb.writeln('Curso,Fecha,Nota,Resultado');
      for (final doc in conNota) {
        final d = doc.data();
        final curso = (d['curso'] ?? '').toString().replaceAll(',', ';');
        final fechaRaw = d['fecha'];
        String fechaStr = '';
        if (fechaRaw != null) {
          final f = (fechaRaw as Timestamp).toDate();
          fechaStr = '${f.day}/${f.month}/${f.year}';
        }
        final nota = d['nota'] as int? ?? 0;
        final resultado = nota >= 11 ? 'Aprobado' : 'Desaprobado';
        sb.writeln('$curso,$fechaStr,$nota/20,$resultado');
      }
      sb.writeln('');

      // ── Racha ──
      final perfilSnap = await _db.collection('perfiles').doc(user!.uid).get();
      final racha = perfilSnap.data()?['racha'] ?? 0;
      final rachaMax = perfilSnap.data()?['rachaMaxima'] ?? 0;

      sb.writeln('═══════════════════════════════');
      sb.writeln('RACHA');
      sb.writeln('Racha actual: $racha días');
      sb.writeln('Racha máxima: $rachaMax días');

      if (mounted) Navigator.pop(context);
      await Share.share(sb.toString(), subject: 'EstudiApp — Mis datos de estudio');
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al exportar datos')),
        );
      }
    }
  }

  Widget _buildResumenSemana() {
    final ahora = DateTime.now();
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    final finSemana = inicioSemana.add(const Duration(days: 6));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2A1F5E), Color(0xFF1F3A35)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Esta semana', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(
            '${inicioSemana.day}/${inicioSemana.month} - ${finSemana.day}/${finSemana.month}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat('Hoy', '${ahora.day}/${ahora.month}', Icons.today, const Color(0xFF7C6AF7)),
              _miniStat('Dia', _getDiaSemana(ahora.weekday), Icons.calendar_today, const Color(0xFF5DE0C5)),
              StreamBuilder<DocumentSnapshot>(
                stream: _db.collection('perfiles').doc(user!.uid).snapshots(),
                builder: (context, snapshot) {
                  final racha = (snapshot.data?.data() as Map<String, dynamic>?)?['racha'] ?? 0;
                  return _miniStat('Racha', '$racha dias', Icons.local_fire_department, const Color(0xFFF7A26A));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String valor, IconData icono, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(height: 4),
          Text(valor, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildGraficoSemana() {
    final dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final ahora = DateTime.now();
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Habitos esta semana',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _db.collection('historial_habitos')
              .where('userId', isEqualTo: user!.uid)
              .where('mes', isEqualTo: '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}')
              .snapshots(),
          builder: (context, snapshot) {
            final diasCompletados = <int>{};
            if (snapshot.hasData) {
              for (final doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                diasCompletados.add(data['dia'] as int);
              }
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (i) {
                  final fecha = inicioSemana.add(Duration(days: i));
                  final completado = diasCompletados.contains(fecha.day);
                  final esHoy = fecha.day == ahora.day && fecha.month == ahora.month;
                  final esFuturo = fecha.isAfter(ahora);

                  return Column(
                    children: [
                      Text(dias[i], style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 8),
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: completado
                              ? const Color(0xFF7C6AF7)
                              : esFuturo
                                  ? Colors.white10
                                  : const Color(0xFF2E2E3E),
                          borderRadius: BorderRadius.circular(8),
                          border: esHoy ? Border.all(color: const Color(0xFF7C6AF7), width: 2) : null,
                        ),
                        child: Center(
                          child: completado
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : esFuturo
                                  ? const SizedBox()
                                  : const Icon(Icons.close, color: Colors.white24, size: 14),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${fecha.day}', style: TextStyle(
                        color: esHoy ? const Color(0xFF7C6AF7) : Colors.white38,
                        fontSize: 10,
                        fontWeight: esHoy ? FontWeight.bold : FontWeight.normal,
                      )),
                    ],
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExamenesProximos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Proximos examenes',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _db.collection('examenes')
              .where('userId', isEqualTo: user!.uid)
              .where('completado', isEqualTo: false)
              .orderBy('fecha')
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12)),
                child: const Text('No hay examenes proximos', style: TextStyle(color: Colors.white38)),
              );
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final fecha = (data['fecha'] as Timestamp).toDate();
                final hoy = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
                final dias = soloFecha.difference(hoy).inDays;
                final color = dias <= 1
                    ? const Color(0xFFF7584A)
                    : dias <= 4
                        ? const Color(0xFFF7A26A)
                        : const Color(0xFF5DE0C5);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(data['curso'] ?? '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        dias <= 0 ? 'Hoy' : '$dias dias',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHabitosMasCompletados() {
    final ahora = DateTime.now();
    final mes = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Habitos este mes',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _db.collection('habitos').where('userId', isEqualTo: user!.uid).snapshots(),
          builder: (context, habitosSnapshot) {
            if (!habitosSnapshot.hasData || habitosSnapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12)),
                child: const Text('No hay habitos', style: TextStyle(color: Colors.white38)),
              );
            }
            return Column(
              children: habitosSnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('historial_habitos')
                      .where('userId', isEqualTo: user!.uid)
                      .where('habitoId', isEqualTo: doc.id)
                      .where('mes', isEqualTo: mes)
                      .snapshots(),
                  builder: (context, histSnapshot) {
                    final veces = histSnapshot.data?.docs.length ?? 0;
                    final diasEnMes = DateTime(ahora.year, ahora.month + 1, 0).day;
                    final porcentaje = diasEnMes > 0 ? veces / diasEnMes : 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(data['nombre'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ),
                              Text('$veces/$diasEnMes dias',
                                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: porcentaje,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                porcentaje >= 0.7
                                    ? const Color(0xFF5DE0C5)
                                    : porcentaje >= 0.4
                                        ? const Color(0xFFF7A26A)
                                        : const Color(0xFFF7584A),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _getDiaSemana(int weekday) {
    const dias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    return dias[weekday - 1];
  }
}