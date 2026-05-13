import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;
  DateTime _mesSeleccionado = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        title: const Text('Historial de hábitos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectorMes(),
            const SizedBox(height: 20),
            _buildCalendario(),
            const SizedBox(height: 20),
            _buildEstadisticas(),
            const SizedBox(height: 20),
            _buildListaHabitos(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorMes() {
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                   'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () => setState(() {
            _mesSeleccionado = DateTime(_mesSeleccionado.year, _mesSeleccionado.month - 1);
          }),
        ),
        Text(
          '${meses[_mesSeleccionado.month - 1]} ${_mesSeleccionado.year}',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white),
          onPressed: () => setState(() {
            _mesSeleccionado = DateTime(_mesSeleccionado.year, _mesSeleccionado.month + 1);
          }),
        ),
      ],
    );
  }

  Widget _buildCalendario() {
    final primerDia = DateTime(_mesSeleccionado.year, _mesSeleccionado.month, 1);
    final ultimoDia = DateTime(_mesSeleccionado.year, _mesSeleccionado.month + 1, 0);
    final diasEnMes = ultimoDia.day;
    final primerDiaSemana = primerDia.weekday % 7;

    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('historial_habitos')
          .where('userId', isEqualTo: user!.uid)
          .where('mes', isEqualTo: '${_mesSeleccionado.year}-${_mesSeleccionado.month.toString().padLeft(2, '0')}')
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['D', 'L', 'M', 'X', 'J', 'V', 'S']
                    .map((d) => Text(d, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)))
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                itemCount: diasEnMes + primerDiaSemana,
                itemBuilder: (context, index) {
                  if (index < primerDiaSemana) return const SizedBox();
                  final dia = index - primerDiaSemana + 1;
                  final completado = diasCompletados.contains(dia);
                  final esHoy = DateTime.now().day == dia &&
                      DateTime.now().month == _mesSeleccionado.month &&
                      DateTime.now().year == _mesSeleccionado.year;

                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: completado
                          ? const Color(0xFF7C6AF7)
                          : esHoy
                              ? const Color(0xFF2E2E3E)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: esHoy && !completado
                          ? Border.all(color: const Color(0xFF7C6AF7))
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$dia',
                        style: TextStyle(
                          color: completado ? Colors.white : Colors.white54,
                          fontSize: 12,
                          fontWeight: completado ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstadisticas() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('historial_habitos')
          .where('userId', isEqualTo: user!.uid)
          .where('mes', isEqualTo: '${_mesSeleccionado.year}-${_mesSeleccionado.month.toString().padLeft(2, '0')}')
          .snapshots(),
      builder: (context, snapshot) {
        final diasCompletados = snapshot.data?.docs.map((d) => (d.data() as Map)['dia']).toSet().length ?? 0;
        final diasEnMes = DateTime(_mesSeleccionado.year, _mesSeleccionado.month + 1, 0).day;
        final porcentaje = diasEnMes > 0 ? (diasCompletados / diasEnMes * 100).round() : 0;

        return Row(
          children: [
            _statCard('Días cumplidos', '$diasCompletados', const Color(0xFF7C6AF7), Icons.check_circle),
            const SizedBox(width: 12),
            _statCard('Días del mes', '$diasEnMes', const Color(0xFF5DE0C5), Icons.calendar_today),
            const SizedBox(width: 12),
            _statCard('Cumplimiento', '$porcentaje%', const Color(0xFFF7A26A), Icons.trending_up),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String valor, Color color, IconData icono) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icono, color: color, size: 22),
            const SizedBox(height: 4),
            Text(valor, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildListaHabitos() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('habitos')
          .where('userId', isEqualTo: user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No tienes hábitos aún', style: TextStyle(color: Colors.white38)),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mis hábitos',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 12),
            ...snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return StreamBuilder<QuerySnapshot>(
                stream: _db.collection('historial_habitos')
                    .where('userId', isEqualTo: user!.uid)
                    .where('habitoId', isEqualTo: doc.id)
                    .where('mes', isEqualTo: '${_mesSeleccionado.year}-${_mesSeleccionado.month.toString().padLeft(2, '0')}')
                    .snapshots(),
                builder: (context, histSnapshot) {
                  final veces = histSnapshot.data?.docs.length ?? 0;
                  final diasEnMes = DateTime(_mesSeleccionado.year, _mesSeleccionado.month + 1, 0).day;
                  final porcentaje = diasEnMes > 0 ? (veces / diasEnMes * 100).round() : 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['nombre'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              Text('$veces veces este mes',
                                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C6AF7).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$porcentaje%',
                              style: const TextStyle(color: Color(0xFF7C6AF7), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }
}