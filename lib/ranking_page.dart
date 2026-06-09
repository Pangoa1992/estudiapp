import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  static String semanaActual() {
    final hoy = DateTime.now();
    final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
    return '${lunes.year}-${lunes.month.toString().padLeft(2, '0')}-${lunes.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final semana = semanaActual();
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        title: const Text('Ranking semanal 🏆',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ranking_semanal')
            .where('semana', isEqualTo: semana)
            .orderBy('simulacros', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: Color(0xFF7C6AF7)));
          }

          final docs = snap.data?.docs ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(semana),
                const SizedBox(height: 20),
                if (docs.isEmpty)
                  _buildVacio()
                else
                  ...docs.asMap().entries.map((e) {
                    final d = e.value.data() as Map<String, dynamic>;
                    return _buildFila(
                      pos: e.key + 1,
                      nombre: d['userName'] as String? ?? 'Estudiante',
                      count: (d['simulacros'] as num? ?? 0).toInt(),
                      isMe: d['userId'] == myUid,
                    );
                  }),
                const SizedBox(height: 16),
                _buildNota(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String semana) {
    final partes = semana.split('-');
    final label = partes.length == 3
        ? 'Semana del ${partes[2]}/${partes[1]}/${partes[0]}'
        : semana;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF2A1F5E), Color(0xFF1F2A3E)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Text('🏆', style: TextStyle(fontSize: 32)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ranking de la semana',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
              const Text('Top 10 por simulacros completados',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildVacio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Text('📋', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text('Sin actividad esta semana',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('¡Completa simulacros para aparecer aquí!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFila({
    required int pos,
    required String nombre,
    required int count,
    required bool isMe,
  }) {
    final medalEmoji =
        pos == 1 ? '🥇' : pos == 2 ? '🥈' : pos == 3 ? '🥉' : null;
    final medalColor = pos == 1
        ? const Color(0xFFFFD700)
        : pos == 2
            ? const Color(0xFFB0B0C0)
            : pos == 3
                ? const Color(0xFFCD7F32)
                : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFF7C6AF7).withValues(alpha: 0.1)
            : const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? const Color(0xFF7C6AF7).withValues(alpha: 0.4)
              : medalColor != null
                  ? medalColor.withValues(alpha: 0.2)
                  : Colors.white12,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: medalEmoji != null
                ? Text(medalEmoji,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22))
                : Text('#$pos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isMe
                            ? const Color(0xFF7C6AF7)
                            : Colors.white38,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                      color: isMe
                          ? const Color(0xFF7C6AF7)
                          : Colors.white,
                      fontWeight: isMe
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 14),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C6AF7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Tú',
                        style: TextStyle(
                            color: Color(0xFF7C6AF7),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
          Row(children: [
            Text('$count',
                style: TextStyle(
                    color: medalColor ??
                        (isMe
                            ? const Color(0xFF7C6AF7)
                            : Colors.white70),
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            const Text('📝', style: TextStyle(fontSize: 12)),
          ]),
        ],
      ),
    );
  }

  Widget _buildNota() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.white38, size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'El ranking se actualiza en tiempo real. Solo se muestran los nombres de usuario y es anónimo para el resto.',
              style: TextStyle(
                  color: Colors.white38, fontSize: 11, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
