import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'logros_page.dart';
import 'racha_heatmap_page.dart';
import 'perfiles_academicos_page.dart';
import 'tema_service.dart';
import 'app_colors.dart';
import 'services/carrera_service.dart';
import 'services/premium_service.dart';
import 'premium_page.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;
  final _carreraController = TextEditingController();
  final _universidadController = TextEditingController();
  bool _editando = false;
  bool _isPremium = false;
  DateTime? _premiumExpiry;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _carreraController.dispose();
    _universidadController.dispose();
    super.dispose();
  }

  void _cargarPerfil() async {
    final doc = await _db.collection('perfiles').doc(user!.uid).get();
    if (doc.exists && mounted) {
      final data = doc.data()!;
      setState(() {
        _carreraController.text = data['carrera'] ?? '';
        _universidadController.text = data['universidad'] ?? '';
      });
    }
    final premium = await PremiumService.isPremium();
    final expiry = await PremiumService.expiry();
    if (mounted) setState(() { _isPremium = premium; _premiumExpiry = expiry; });
  }

  void _guardarPerfil() async {
    await _db.collection('perfiles').doc(user!.uid).set({
      'carrera': _carreraController.text,
      'universidad': _universidadController.text,
      'nombre': user!.displayName,
      'email': user!.email,
    }, SetOptions(merge: true));
    if (mounted) setState(() => _editando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        elevation: 0,
        title: Text(
          'Mi perfil',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: context.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: AppC.gold),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LogrosPage())),
          ),
          IconButton(
            icon: Icon(_editando ? Icons.check : Icons.edit, color: AppC.purple),
            onPressed: () {
              if (_editando) {
                _guardarPerfil();
              } else {
                setState(() => _editando = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppC.purple,
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null
                  ? Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Estudiante',
              style: TextStyle(
                  color: context.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? '',
              style: TextStyle(color: context.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Racha banner
            StreamBuilder<DocumentSnapshot>(
              stream: _db.collection('perfiles').doc(user!.uid).snapshots(),
              builder: (context, perfilSnapshot) {
                final racha = perfilSnapshot.data?.get('racha') ?? 0;
                final rachaMaxima = perfilSnapshot.data?.get('rachaMaxima') ?? 0;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppC.streakGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text('$racha',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                            const Text('Racha actual',
                                style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 60, color: Colors.white12),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('👑', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text('$rachaMaxima',
                                style: const TextStyle(
                                    color: AppC.gold,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                            const Text('Racha máxima',
                                style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 60, color: Colors.white12),
                      StreamBuilder<QuerySnapshot>(
                        stream: _db
                            .collection('historial_habitos')
                            .where('userId', isEqualTo: user!.uid)
                            .snapshots(),
                        builder: (context, histSnapshot) {
                          final diasEstudiados = histSnapshot.data?.docs
                                  .map((d) {
                                    final m = (d.data() as Map);
                                    return '${m['mes']}-${m['dia']}';
                                  })
                                  .toSet()
                                  .length ??
                              0;
                          return Expanded(
                            child: Column(
                              children: [
                                const Text('📅', style: TextStyle(fontSize: 28)),
                                const SizedBox(height: 4),
                                Text('$diasEstudiados',
                                    style: const TextStyle(
                                        color: AppC.teal,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                                const Text('Días activos',
                                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // Botones de navegación
            _navBtn(
              icon: Icons.emoji_events,
              color: AppC.gold,
              label: 'Ver mis logros',
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const LogrosPage())),
            ),
            const SizedBox(height: 10),
            _navBtn(
              icon: Icons.local_fire_department,
              color: AppC.red,
              label: 'Historial de racha',
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const RachaHeatmapPage())),
            ),
            const SizedBox(height: 10),
            _navBtn(
              icon: Icons.swap_horiz,
              color: AppC.purple,
              label: 'Perfiles académicos',
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const PerfilesAcademicosPage())),
            ),
            const SizedBox(height: 10),

            // Toggle de tema
            _buildToggleTema(),
            const SizedBox(height: 16),

            _buildCarreraSelector(),
            const SizedBox(height: 12),
            _buildCampo('Universidad', _universidadController, Icons.account_balance),
            const SizedBox(height: 16),
            _buildPremiumBanner(),
            const SizedBox(height: 12),

            // Estadísticas
            Align(
              alignment: Alignment.centerLeft,
              child: Text('ESTADÍSTICAS',
                  style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('habitos').where('userId', isEqualTo: user!.uid).snapshots(),
              builder: (context, habitosSnapshot) {
                final totalHabitos = habitosSnapshot.data?.docs.length ?? 0;
                final completados = habitosSnapshot.data?.docs
                        .where((d) => (d.data() as Map)['done'] == true)
                        .length ??
                    0;
                return Row(
                  children: [
                    _buildStat('Hábitos', '$totalHabitos', Icons.check_circle_outline),
                    const SizedBox(width: 12),
                    _buildStat('Hoy', '$completados', Icons.check_circle, color: AppC.teal),
                    const SizedBox(width: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: _db
                          .collection('examenes')
                          .where('userId', isEqualTo: user!.uid)
                          .snapshots(),
                      builder: (context, examSnapshot) {
                        final totalExamenes = examSnapshot.data?.docs.length ?? 0;
                        return _buildStat('Exámenes', '$totalExamenes', Icons.school,
                            color: AppC.orange);
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('cursos').where('userId', isEqualTo: user!.uid).snapshots(),
              builder: (context, cursosSnapshot) {
                final totalCursos = cursosSnapshot.data?.docs.length ?? 0;
                return Row(
                  children: [
                    _buildStat('Cursos', '$totalCursos', Icons.menu_book, color: AppC.blue),
                    const SizedBox(width: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: _db
                          .collection('examenes')
                          .where('userId', isEqualTo: user!.uid)
                          .where('completado', isEqualTo: true)
                          .snapshots(),
                      builder: (context, examCompSnapshot) {
                        final aprobados = examCompSnapshot.data?.docs.length ?? 0;
                        return _buildStat('Aprobados', '$aprobados', Icons.emoji_events,
                            color: AppC.gold);
                      },
                    ),
                    const SizedBox(width: 12),
                    StreamBuilder<DocumentSnapshot>(
                      stream: _db.collection('logros').doc(user!.uid).snapshots(),
                      builder: (context, logrosSnapshot) {
                        final logros = logrosSnapshot.data?.exists == true
                            ? List.from(
                                    ((logrosSnapshot.data!.data() as Map?) ?? {})['obtenidos'] ?? [])
                                .length
                            : 0;
                        return _buildStat('Logros', '$logros/10', Icons.star,
                            color: AppC.orange);
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _navBtn({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.chevron_right, color: context.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTema() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: TemaService.modoNotifier,
      builder: (ctx, modo, _) {
        final sistemaOscuro =
            MediaQuery.of(ctx).platformBrightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderPrimary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette, color: AppC.purple, size: 20),
                  const SizedBox(width: 10),
                  Text('Apariencia',
                      style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _botonTema('🌙 Oscuro', ThemeMode.dark, modo),
                  const SizedBox(width: 8),
                  _botonTema(
                    '⚙️ Sistema',
                    ThemeMode.system,
                    modo,
                    subtitulo: sistemaOscuro ? 'oscuro ahora' : 'claro ahora',
                  ),
                  const SizedBox(width: 8),
                  _botonTema('☀️ Claro', ThemeMode.light, modo),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _botonTema(String label, ThemeMode valor, ThemeMode actual,
      {String? subtitulo}) {
    final activo = valor == actual;
    return Expanded(
      child: GestureDetector(
        onTap: () => TemaService.setModo(valor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: subtitulo != null ? 7 : 10),
          decoration: BoxDecoration(
            color: activo ? AppC.purple.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: activo ? AppC.purple : context.borderSecondary,
              width: activo ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: activo ? AppC.purple : context.textSecondary,
                  fontSize: 12,
                  fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (subtitulo != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: TextStyle(
                    color: activo
                        ? AppC.purple.withOpacity(0.8)
                        : context.textTertiary,
                    fontSize: 9,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampo(String label, TextEditingController controller, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderPrimary),
      ),
      child: Row(
        children: [
          Icon(icono, color: AppC.purple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: _editando
                ? TextField(
                    controller: controller,
                    style: TextStyle(color: context.textPrimary),
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle: TextStyle(color: context.textSecondary),
                      border: InputBorder.none,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(color: context.textSecondary, fontSize: 11)),
                      Text(
                        controller.text.isEmpty ? 'No especificado' : controller.text,
                        style: TextStyle(color: context.textPrimary, fontSize: 14),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarreraSelector() {
    final carreraActual = _carreraController.text;
    return GestureDetector(
      onTap: () async {
        final seleccionada = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: const Color(0xFF1E1E2A),
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (ctx, scroll) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Selecciona tu carrera',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: CarreraService.lista.length,
                    itemBuilder: (ctx, i) {
                      final c = CarreraService.lista[i];
                      final sel = c == carreraActual;
                      return GestureDetector(
                        onTap: () => Navigator.pop(ctx, c),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFF7C6AF7).withValues(alpha: 0.2)
                                : const Color(0xFF0F0F14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: sel
                                    ? const Color(0xFF7C6AF7)
                                    : Colors.white12,
                                width: sel ? 1.5 : 1),
                          ),
                          child: Row(children: [
                            Expanded(
                              child: Text(c,
                                  style: TextStyle(
                                      color: sel
                                          ? const Color(0xFF7C6AF7)
                                          : Colors.white70,
                                      fontWeight: sel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 14)),
                            ),
                            if (sel)
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF7C6AF7), size: 18),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
        if (seleccionada != null) {
          setState(() => _carreraController.text = seleccionada);
          // Auto-save carrera immediately so AI context updates at once
          await _db.collection('perfiles').doc(user!.uid).set(
              {'carrera': seleccionada}, SetOptions(merge: true));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderPrimary),
        ),
        child: Row(
          children: [
            Icon(Icons.school, color: AppC.purple, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Carrera',
                      style: TextStyle(
                          color: context.textSecondary, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    carreraActual.isEmpty ? 'Toca para seleccionar' : carreraActual,
                    style: TextStyle(
                        color: carreraActual.isEmpty
                            ? context.textTertiary
                            : context.textPrimary,
                        fontSize: 14,
                        fontStyle: carreraActual.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down,
                color: AppC.purple, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const PremiumPage())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: _isPremium
              ? const LinearGradient(
                  colors: [Color(0xFF2A2050), Color(0xFF1A3030)])
              : LinearGradient(
                  colors: [
                    const Color(0xFF7C6AF7).withValues(alpha: 0.08),
                    const Color(0xFF4A90E2).withValues(alpha: 0.08),
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isPremium
                ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                : const Color(0xFF7C6AF7).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Text(_isPremium ? '⭐' : '🔒',
                style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isPremium ? 'EstudiApp Premium activo' : 'Desbloquear Premium',
                    style: TextStyle(
                        color: _isPremium
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF7C6AF7),
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  Text(
                    _isPremium && _premiumExpiry != null
                        ? 'Válido hasta ${_premiumExpiry!.day}/${_premiumExpiry!.month}/${_premiumExpiry!.year}'
                        : 'PDF simulacros, grupos de estudio y más',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String valor, IconData icono,
      {Color color = AppC.purple}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderPrimary),
        ),
        child: Column(
          children: [
            Icon(icono, color: color, size: 22),
            const SizedBox(height: 4),
            Text(valor,
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: context.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
