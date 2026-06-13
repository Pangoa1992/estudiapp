import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/compartir_service.dart';
import 'l10n_helper.dart';

class LogrosPage extends StatefulWidget {
  const LogrosPage({super.key});

  @override
  State<LogrosPage> createState() => _LogrosPageState();
}

class _LogrosPageState extends State<LogrosPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _buildLogros(AppLocalizations l10n) => [
    {'id': 'primer_habito',    'emoji': '✅',  'titulo': l10n.achPrimerHabitoT,    'descripcion': l10n.achPrimerHabitoD,    'color': const Color(0xFF7C6AF7)},
    {'id': 'racha_3',          'emoji': '🔥',  'titulo': l10n.achRacha3T,          'descripcion': l10n.achRacha3D,          'color': const Color(0xFFF7A26A)},
    {'id': 'racha_7',          'emoji': '⚡',  'titulo': l10n.achRacha7T,          'descripcion': l10n.achRacha7D,          'color': const Color(0xFFF7584A)},
    {'id': 'racha_14',         'emoji': '🌊',  'titulo': l10n.achRacha14T,         'descripcion': l10n.achRacha14D,         'color': const Color(0xFF4A90E2)},
    {'id': 'racha_30',         'emoji': '👑',  'titulo': l10n.achRacha30T,         'descripcion': l10n.achRacha30D,         'color': const Color(0xFFFFD700)},
    {'id': 'racha_100',        'emoji': '🚀',  'titulo': l10n.achRacha100T,        'descripcion': l10n.achRacha100D,        'color': const Color(0xFFF7584A)},
    {'id': 'primer_examen',    'emoji': '📚',  'titulo': l10n.achPrimerExamenT,    'descripcion': l10n.achPrimerExamenD,    'color': const Color(0xFF5DE0C5)},
    {'id': 'examen_completado','emoji': '🎓',  'titulo': l10n.achExamenCompletadoT,'descripcion': l10n.achExamenCompletadoD,'color': const Color(0xFF5DE0C5)},
    {'id': 'cinco_habitos',    'emoji': '💪',  'titulo': l10n.achCincoHabitosT,    'descripcion': l10n.achCincoHabitosD,    'color': const Color(0xFF7C6AF7)},
    {'id': 'pomodoro_1',       'emoji': '⏱️', 'titulo': l10n.achPomodoro1T,       'descripcion': l10n.achPomodoro1D,       'color': const Color(0xFF7C6AF7)},
    {'id': 'ia_1',             'emoji': '🤖',  'titulo': l10n.achIa1T,             'descripcion': l10n.achIa1D,             'color': const Color(0xFF7C6AF7)},
    {'id': 'ia_50',            'emoji': '🧠',  'titulo': l10n.achIa50T,            'descripcion': l10n.achIa50D,            'color': const Color(0xFF7C6AF7)},
    {'id': 'simulacros_10',    'emoji': '🎯',  'titulo': l10n.achSimulacros10T,    'descripcion': l10n.achSimulacros10D,    'color': const Color(0xFF5DE0C5)},
    {'id': 'primer_simulacro', 'emoji': '🎓',  'titulo': l10n.achPrimerSimulacroT, 'descripcion': l10n.achPrimerSimulacroD, 'color': const Color(0xFF5DE0C5)},
    {'id': 'nota_perfecta',    'emoji': '💯',  'titulo': l10n.achNotaPerfectaT,    'descripcion': l10n.achNotaPerfectaD,    'color': const Color(0xFFFFD700)},
    {'id': 'habitos_dia',      'emoji': '🌟',  'titulo': l10n.achHabitosDiaT,      'descripcion': l10n.achHabitosDiaD,      'color': const Color(0xFFFFD700)},
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final logros = _buildLogros(l10n);
    final uid = user?.uid;
    if (uid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F14),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        title: Text(l10n.achievementsTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('logros').doc(uid).snapshots(),
        builder: (context, logrosSnapshot) {
          final logrosGuardados = logrosSnapshot.data?.exists == true
              ? List<String>.from((logrosSnapshot.data!.data() as Map)['obtenidos'] ?? [])
              : <String>[];

          return StreamBuilder<DocumentSnapshot>(
            stream: _db.collection('perfiles').doc(uid).snapshots(),
            builder: (context, perfilSnapshot) {
              final perfilData = perfilSnapshot.data?.data() as Map<String, dynamic>?;
              final racha = perfilData?['racha'] ?? 0;
              final simulacrosCompletados = ((perfilData?['simulacrosCompletados'] ?? 0) as num).toInt();
              final iaUsosTotal = ((perfilData?['iaUsosTotal'] ?? 0) as num).toInt();

              return StreamBuilder<QuerySnapshot>(
                stream: _db.collection('habitos').where('userId', isEqualTo: uid).snapshots(),
                builder: (context, habitosSnapshot) {
                  final totalHabitos = habitosSnapshot.data?.docs.length ?? 0;
                  final habitosCompletados = habitosSnapshot.data?.docs
                      .where((d) => (d.data() as Map)['done'] == true)
                      .length ?? 0;
                  final todosCompletados = totalHabitos > 0 && habitosCompletados == totalHabitos;

                  return StreamBuilder<QuerySnapshot>(
                    stream: _db.collection('examenes').where('userId', isEqualTo: uid).snapshots(),
                    builder: (context, examenesSnapshot) {
                      final totalExamenes = examenesSnapshot.data?.docs.length ?? 0;
                      final examenesCompletados = examenesSnapshot.data?.docs
                          .where((d) => (d.data() as Map)['completado'] == true)
                          .length ?? 0;
                      final notaPerfecta = examenesSnapshot.data?.docs.any(
                            (d) => (d.data() as Map)['nota'] == 20,
                          ) ?? false;

                      final logrosCalculados = _calcularLogros(
                        logrosGuardados: logrosGuardados,
                        racha: racha,
                        totalHabitos: totalHabitos,
                        habitosCompletados: habitosCompletados,
                        todosCompletados: todosCompletados,
                        totalExamenes: totalExamenes,
                        examenesCompletados: examenesCompletados,
                        simulacrosCompletados: simulacrosCompletados,
                        iaUsosTotal: iaUsosTotal,
                        notaPerfecta: notaPerfecta,
                      );

                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _guardarLogrosNuevos(logrosGuardados, logrosCalculados),
                      );

                      final obtenidos = logros.where((l) => logrosCalculados.contains(l['id'])).toList();
                      final pendientes = logros.where((l) => !logrosCalculados.contains(l['id'])).toList();

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProgreso(obtenidos.length, logros.length, l10n),
                            const SizedBox(height: 24),
                            if (obtenidos.isNotEmpty) ...[
                              Text(l10n.obtainedLabel, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                              const SizedBox(height: 12),
                              ...obtenidos.map((l) => _buildLogro(l, true, l10n)),
                              const SizedBox(height: 24),
                            ],
                            Text(l10n.pendingLabel, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                            const SizedBox(height: 12),
                            ...pendientes.map((l) => _buildLogro(l, false, l10n)),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<String> _calcularLogros({
    required List<String> logrosGuardados,
    required int racha,
    required int totalHabitos,
    required int habitosCompletados,
    required bool todosCompletados,
    required int totalExamenes,
    required int examenesCompletados,
    required int simulacrosCompletados,
    required int iaUsosTotal,
    required bool notaPerfecta,
  }) {
    final logros = <String>[...logrosGuardados];

    if (habitosCompletados >= 1 && !logros.contains('primer_habito')) logros.add('primer_habito');

    if (racha >= 3   && !logros.contains('racha_3'))   logros.add('racha_3');
    if (racha >= 7   && !logros.contains('racha_7'))   logros.add('racha_7');
    if (racha >= 14  && !logros.contains('racha_14'))  logros.add('racha_14');
    if (racha >= 30  && !logros.contains('racha_30'))  logros.add('racha_30');
    if (racha >= 100 && !logros.contains('racha_100')) logros.add('racha_100');

    if (totalHabitos >= 5   && !logros.contains('cinco_habitos')) logros.add('cinco_habitos');
    if (todosCompletados    && !logros.contains('habitos_dia'))    logros.add('habitos_dia');

    if (totalExamenes >= 1      && !logros.contains('primer_examen'))      logros.add('primer_examen');
    if (examenesCompletados >= 1 && !logros.contains('examen_completado')) logros.add('examen_completado');

    if (simulacrosCompletados >= 1  && !logros.contains('primer_simulacro')) logros.add('primer_simulacro');
    if (simulacrosCompletados >= 10 && !logros.contains('simulacros_10'))    logros.add('simulacros_10');

    if (notaPerfecta && !logros.contains('nota_perfecta')) logros.add('nota_perfecta');
    if (iaUsosTotal >= 50 && !logros.contains('ia_50')) logros.add('ia_50');

    return logros;
  }

  void _guardarLogrosNuevos(List<String> anteriores, List<String> nuevos) {
    final uid = user?.uid;
    if (uid == null) return;
    final logrosNuevos = nuevos.where((l) => !anteriores.contains(l)).toList();
    if (logrosNuevos.isNotEmpty) {
      _db.collection('logros').doc(uid).set(
        {'obtenidos': FieldValue.arrayUnion(logrosNuevos)},
        SetOptions(merge: true),
      );
    }
  }

  Widget _buildProgreso(int obtenidos, int total, AppLocalizations l10n) {
    final porcentaje = total > 0 ? obtenidos / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2A1F5E), Color(0xFF1F3A35)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.progressLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('$obtenidos/$total', style: const TextStyle(color: Color(0xFF7C6AF7), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: porcentaje,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C6AF7)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.percentComplete((porcentaje * 100).round()),
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLogro(Map<String, dynamic> logro, bool obtenido, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: obtenido ? (logro['color'] as Color).withOpacity(0.1) : const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: obtenido ? (logro['color'] as Color).withOpacity(0.4) : const Color(0xFF2E2E3E),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: obtenido ? (logro['color'] as Color).withOpacity(0.2) : Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(logro['emoji'] as String, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(logro['titulo'] as String, style: TextStyle(color: obtenido ? Colors.white : Colors.white38, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(logro['descripcion'] as String, style: TextStyle(color: obtenido ? Colors.white54 : Colors.white24, fontSize: 12)),
              ],
            ),
          ),
          if (obtenido)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle,
                    color: logro['color'] as Color, size: 20),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => CompartirService.mostrar(
                    context: context,
                    tarjeta: CompartirService.tarjetaLogro(
                      emoji: logro['emoji'] as String,
                      titulo: logro['titulo'] as String,
                      descripcion: logro['descripcion'] as String,
                      color: logro['color'] as Color,
                      nombreUsuario: user?.displayName ?? 'Estudiante',
                    ),
                    texto: '${logro['emoji']} ${l10n.achievementUnlock(logro['titulo'] as String)}',
                  ),
                  child: const Icon(Icons.share,
                      color: Colors.white38, size: 18),
                ),
              ],
            )
          else
            const Icon(Icons.lock_outline,
                color: Colors.white24, size: 20),
        ],
      ),
    );
  }
}
