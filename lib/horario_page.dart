import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HorarioWidget extends StatelessWidget {
  const HorarioWidget({super.key});

  static const _dias = ['L', 'M', 'X', 'J', 'V', 'S'];
  static const _nombDias = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB'];

  int _parseMinutos(String hora) {
    if (hora.trim().isEmpty) return -1;
    String h = hora.toUpperCase().trim();
    final pm = h.contains('PM');
    final am = h.contains('AM');
    h = h.replaceAll('AM', '').replaceAll('PM', '').trim();
    final parts = h.split(':');
    if (parts.isEmpty) return -1;
    int horas = int.tryParse(parts[0].trim()) ?? 0;
    final min = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
    if (pm && horas != 12) horas += 12;
    if (am && horas == 12) horas = 0;
    return horas * 60 + min;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cursos')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C6AF7)));
        }

        final cursos = snapshot.data?.docs ?? [];

        if (cursos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_view_week, color: Colors.white24, size: 60),
                SizedBox(height: 12),
                Text('Sin cursos en el horario',
                    style: TextStyle(color: Colors.white38)),
                Text('Agrega cursos y asígnales días y hora',
                    style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ),
          );
        }

        final Map<String, List<Map<String, dynamic>>> porDia = {
          for (final d in _dias) d: [],
        };
        for (final doc in cursos) {
          final data = doc.data() as Map<String, dynamic>;
          final dias = List<String>.from(data['dias'] ?? []);
          for (final dia in dias) {
            if (porDia.containsKey(dia)) {
              porDia[dia]!.add({...data, '_id': doc.id});
            }
          }
        }
        for (final d in _dias) {
          porDia[d]!.sort((a, b) =>
              _parseMinutos(a['hora'] ?? '')
                  .compareTo(_parseMinutos(b['hora'] ?? '')));
        }

        final hoy = DateTime.now().weekday - 1; // 0=Lun…5=Sáb

        return SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // Cabecera días
              Row(
                children: List.generate(6, (i) {
                  final isToday = i == hoy;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 5 ? 4 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFF7C6AF7).withOpacity(0.22)
                            : const Color(0xFF1E1E2A),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(color: const Color(0xFF7C6AF7))
                            : Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        _nombDias[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isToday
                              ? const Color(0xFF7C6AF7)
                              : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              // Columnas por día
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(6, (i) {
                  final dia = _dias[i];
                  final lista = porDia[dia]!;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 5 ? 4 : 0),
                      child: lista.isEmpty
                          ? Container(
                              height: 72,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF1E1E2A).withOpacity(0.35),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: const Center(
                                child: Icon(Icons.remove,
                                    color: Colors.white12, size: 14),
                              ),
                            )
                          : Column(
                              children: lista.map((c) {
                                final color =
                                    Color(c['color'] ?? 0xFF7C6AF7);
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 5),
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: color.withOpacity(0.5)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['nombre'] ?? '',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if ((c['hora'] ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          c['hora'] ?? '',
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 8),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Leyenda
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: cursos.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final color = Color(data['color'] ?? 0xFF7C6AF7);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      CircleAvatar(radius: 4, backgroundColor: color),
                      const SizedBox(width: 6),
                      Text(data['nombre'] ?? '',
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ]),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
