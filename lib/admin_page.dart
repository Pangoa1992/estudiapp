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

  // Fecha de hoy en zona horaria Lima (UTC-5, sin horario de verano)
  String _fechaHoyLima() {
    final lima = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    return '${lima.year}-'
        '${lima.month.toString().padLeft(2, '0')}-'
        '${lima.day.toString().padLeft(2, '0')}';
  }

  // ¿El timestamp pertenece al mes y año actuales?
  bool _esMesActual(Timestamp? ts) {
    if (ts == null) return false;
    final fecha = ts.toDate();
    final ahora = DateTime.now();
    return fecha.year == ahora.year && fecha.month == ahora.month;
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
        title: const Text('Panel Admin',
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

          // Todos los perfiles excepto el admin
          final testers = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final email = (data['email'] as String? ?? '').toLowerCase().trim();
            return email != AdminPage.adminEmail.toLowerCase();
          }).toList();

          // ── Métricas globales ────────────────────────────────────────────
          final fechaHoy = _fechaHoyLima();

          // Total usuarios (sin contar admin)
          final totalUsuarios = testers.length;

          // Premium activos: isPremium == true y no expirado
          final premiumActivos = testers.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['isPremium'] != true) return false;
            final expiry = (data['premiumExpiry'] as Timestamp?)?.toDate();
            if (expiry != null && expiry.isBefore(DateTime.now())) return false;
            return true;
          }).length;

          // Búsquedas IA hoy: suma de ia_usos_hoy donde ia_fecha_hoy == hoy
          final busquedasHoy = testers.fold<int>(0, (suma, doc) {
            final data = doc.data() as Map<String, dynamic>;
            if ((data['ia_fecha_hoy'] as String?) != fechaHoy) return suma;
            return suma + ((data['ia_usos_hoy'] as num?)?.toInt() ?? 0);
          });

          // Ingresos estimados del mes: suscripciones pagadas (no trial) × S/. 15
          final suscripcionesMes = testers.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final plan = data['planPremium'] as String? ?? '';
            if (plan.isEmpty || plan == 'trial_7d') return false;
            return _esMesActual(data['premiumActivadoEn'] as Timestamp?);
          }).length;
          final ingresosMes = suscripcionesMes * 15;

          // ── Datos para sección de testers ────────────────────────────────
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

          final ingresaronHoy = testers.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final visita = (data['ultimaVisita'] as Timestamp?)?.toDate();
            return _ingresoHoy(visita);
          }).length;

          return Column(
            children: [
              // ── Tarjeta de métricas del negocio ──────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1240), Color(0xFF0D2B28)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7C6AF7).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MÉTRICAS',
                      style: TextStyle(
                        color: Color(0xFF7C6AF7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _metricaTile(
                            icono: Icons.people_outline,
                            valor: '$totalUsuarios',
                            label: 'Usuarios',
                            color: const Color(0xFF7C6AF7),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _metricaTile(
                            icono: Icons.star_outline,
                            valor: '$premiumActivos',
                            label: 'Premium activos',
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _metricaTile(
                            icono: Icons.auto_awesome_outlined,
                            valor: '$busquedasHoy',
                            label: 'Búsquedas IA hoy',
                            color: const Color(0xFF5DE0C5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _metricaTile(
                            icono: Icons.attach_money,
                            valor: 'S/. $ingresosMes',
                            label: 'Ingresos del mes',
                            sublabel: '($suscripcionesMes suscripción${suscripcionesMes != 1 ? 'es' : ''})',
                            color: const Color(0xFF5DE0C5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Tarjeta de actividad de testers ──────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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

              // ── Lista de testers ──────────────────────────────────────────
              Expanded(
                child: testers.isEmpty
                    ? const Center(
                        child: Text('No hay usuarios registrados',
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
                          final esPremium = data['isPremium'] == true;
                          final plan = data['planPremium'] as String? ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: ingresoHoy
                                  ? const Color(0xFF5DE0C5).withValues(alpha: 0.1)
                                  : const Color(0xFF1E1E2A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: ingresoHoy
                                    ? const Color(0xFF5DE0C5).withValues(alpha: 0.4)
                                    : const Color(0xFFF7584A).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Icono estado
                                Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(
                                    color: ingresoHoy
                                        ? const Color(0xFF5DE0C5).withValues(alpha: 0.2)
                                        : const Color(0xFFF7584A).withValues(alpha: 0.2),
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
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(nombre,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14)),
                                          ),
                                          if (esPremium)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                plan == 'trial_7d' ? '⭐ Trial' : '⭐ Premium',
                                                style: const TextStyle(
                                                    color: Color(0xFFFFD700),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
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
                                        ? const Color(0xFF5DE0C5).withValues(alpha: 0.2)
                                        : const Color(0xFF7C6AF7).withValues(alpha: 0.2),
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

  // Tile de métrica para la tarjeta de negocio
  Widget _metricaTile({
    required IconData icono,
    required String valor,
    required String label,
    String? sublabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          if (sublabel != null)
            Text(
              sublabel,
              style: const TextStyle(color: Colors.white30, fontSize: 10),
            ),
        ],
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
