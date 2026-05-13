import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  // Email del administrador. Centralizado aquí para evitar duplicación.
  static const String adminEmail = 'pasminio456@gmail.com';

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _db = FirebaseFirestore.instance;

  bool _esAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email?.toLowerCase() == AdminPage.adminEmail.toLowerCase();
  }

  String _tiempoDesde(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} días';
  }

  bool _ingresoHoy(DateTime? ultimaVisita) {
    if (ultimaVisita == null) return false;
    final hoy = DateTime.now();
    return ultimaVisita.year == hoy.year &&
        ultimaVisita.month == hoy.month &&
        ultimaVisita.day == hoy.day;
  }

  @override
  Widget build(BuildContext context) {
    if (!_esAdmin()) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F14),
        body: const Center(
          child: Text('Acceso denegado', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        title: const Text('Panel Admin — Testers',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('perfiles').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF7C6AF7)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay perfiles en Firestore',
                  style: TextStyle(color: Colors.white38)),
            );
          }

          final docs = snapshot.data!.docs;

          // Mostrar TODOS excepto admin
          final testers = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final email = (data['email'] as String? ?? '').toLowerCase().trim();
            return email != AdminPage.adminEmail.toLowerCase();
          }).toList();

          // Ordenar: ingresaron hoy primero, luego por racha
          testers.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final visitaA = (dataA['ultimaVisita'] as Timestamp?)?.toDate();
            final visitaB = (dataB['ultimaVisita'] as Timestamp?)?.toDate();
            final hoyA = _ingresoHoy(visitaA) ? 0 : 1;
            final hoyB = _ingresoHoy(visitaB) ? 0 : 1;
            if (hoyA != hoyB) return hoyA.compareTo(hoyB);
            final rachaA = dataA['rachaMaxima'] ?? 0;
            final rachaB = dataB['rachaMaxima'] ?? 0;
            return (rachaB as int).compareTo(rachaA as int);
          });

          // Contar cuántos ingresaron hoy
          final ingresaronHoy = testers.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final visita = (data['ultimaVisita'] as Timestamp?)?.toDate();
            return _ingresoHoy(visita);
          }).length;

          return Column(
            children: [
              // Resumen arriba
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2A1F5E), Color(0xFF1F3A35)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statAdmin('Hoy', '$ingresaronHoy/${testers.length}', Icons.today, const Color(0xFF5DE0C5)),
                    _statAdmin('Total', '${testers.length}', Icons.people, const Color(0xFF7C6AF7)),
                    _statAdmin('Faltan', '${testers.length - ingresaronHoy}', Icons.warning, const Color(0xFFF7584A)),
                  ],
                ),
              ),

              // Lista de testers
              Expanded(
                child: testers.isEmpty
                    ? const Center(
                        child: Text('No hay testers registrados',
                            style: TextStyle(color: Colors.white38)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: testers.length,
                        itemBuilder: (context, i) {
                          final data = testers[i].data() as Map<String, dynamic>;
                          final nombre = data['nombre'] as String? ?? 'Sin nombre';
                          final racha = data['racha'] ?? 0;
                          final rachaMaxima = data['rachaMaxima'] ?? 0;
                          final ultimaVisita = (data['ultimaVisita'] as Timestamp?)?.toDate();
                          final ingresoHoy = _ingresoHoy(ultimaVisita);
                          final email = data['email'] as String? ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: ingresoHoy
                                  ? const Color(0xFF5DE0C5).withOpacity(0.1)
                                  : const Color(0xFF1E1E2A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: ingresoHoy
                                    ? const Color(0xFF5DE0C5).withOpacity(0.4)
                                    : const Color(0xFFF7584A).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Icono estado
                                Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(
                                    color: ingresoHoy
                                        ? const Color(0xFF5DE0C5).withOpacity(0.2)
                                        : const Color(0xFFF7584A).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      ingresoHoy ? '✅' : '❌',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(nombre,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                      Text(email,
                                          style: const TextStyle(
                                              color: Colors.white38, fontSize: 10)),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        Text('🔥 Racha: $racha',
                                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                        const SizedBox(width: 12),
                                        Text('🏆 Max: $rachaMaxima',
                                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                      ]),
                                      if (ultimaVisita != null)
                                        Text(
                                          ingresoHoy
                                              ? '✅ Ingresó hoy ${_tiempoDesde(ultimaVisita)}'
                                              : '❌ Última visita: ${_tiempoDesde(ultimaVisita)}',
                                          style: TextStyle(
                                            color: ingresoHoy
                                                ? const Color(0xFF5DE0C5)
                                                : const Color(0xFFF7584A),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      else
                                        const Text('⚠️ Nunca ingresó',
                                            style: TextStyle(color: Colors.orange, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                // Racha badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: rachaMaxima >= 14
                                        ? const Color(0xFF5DE0C5).withOpacity(0.2)
                                        : const Color(0xFF7C6AF7).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$rachaMaxima/14',
                                    style: TextStyle(
                                      color: rachaMaxima >= 14
                                          ? const Color(0xFF5DE0C5)
                                          : const Color(0xFF7C6AF7),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statAdmin(String label, String valor, IconData icono, Color color) {
    return Column(
      children: [
        Icon(icono, color: color, size: 24),
        const SizedBox(height: 4),
        Text(valor, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}