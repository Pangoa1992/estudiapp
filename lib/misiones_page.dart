import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/mision_model.dart';
import 'services/misiones_service.dart';
import 'services/niveles_service.dart';
import 'widgets/celebracion_widget.dart';

class MisionesPage extends StatefulWidget {
  const MisionesPage({super.key});

  @override
  State<MisionesPage> createState() => _MisionesPageState();
}

class _MisionesPageState extends State<MisionesPage> {
  final _db = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<Mision> _diarias = [];
  List<Mision> _semanales = [];
  bool _cargando = true;
  bool _reclamando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    await MisionesService.actualizarProgreso();
    final (diarias, semanales) = await MisionesService.obtenerMisiones();
    if (mounted) {
      setState(() {
        _diarias = diarias;
        _semanales = semanales;
        _cargando = false;
      });
    }
  }

  Future<void> _reclamar(Mision m, bool esSemanal) async {
    if (_reclamando) return;
    setState(() => _reclamando = true);
    try {
      final nivelSubio = await MisionesService.reclamarRecompensa(
        misionId: m.id,
        esSemanal: esSemanal,
        monedas: m.recompensaMonedas,
        xp: m.recompensaXp,
      );

      if (!mounted) return;

      CelebracionWidget.mostrarMisionCompletada(
        context,
        m.descripcion,
        m.recompensaMonedas,
        m.recompensaXp,
      );

      if (nivelSubio != null) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        await CelebracionWidget.mostrarSubidaNivel(context, nivelSubio);
      }

      await _cargar();
    } finally {
      if (mounted) setState(() => _reclamando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        title: const Text('Misiones',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF7C6AF7)),
            onPressed: _cargando ? null : _cargar,
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C6AF7)))
          : RefreshIndicator(
              color: const Color(0xFF7C6AF7),
              backgroundColor: const Color(0xFF1E1E2A),
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildNivelBanner(),
                  const SizedBox(height: 20),
                  _buildSeccion(
                    titulo: 'MISIONES DIARIAS',
                    icono: '☀️',
                    subtitulo: 'Se renuevan cada día',
                    misiones: _diarias,
                    esSemanal: false,
                  ),
                  const SizedBox(height: 20),
                  _buildSeccion(
                    titulo: 'MISIONES SEMANALES',
                    icono: '📅',
                    subtitulo: 'Se renuevan cada lunes',
                    misiones: _semanales,
                    esSemanal: true,
                  ),
                  const SizedBox(height: 24),
                  _buildTipXP(),
                ],
              ),
            ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildNivelBanner() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _uid.isNotEmpty
          ? _db.collection('perfiles').doc(_uid).snapshots()
          : const Stream.empty(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final xpTotal = (data?['xp_total'] as num? ?? 0).toInt();
        final nivel = NivelesService.nivelDesdeXpTotal(xpTotal);
        final xpEnNivel = NivelesService.xpEnNivelActual(xpTotal);
        final xpSiguiente = NivelesService.xpParaSiguienteNivel(nivel);
        final nombre = NivelesService.nombreDeNivel(nivel);
        final emoji = NivelesService.emojiDeNivel(nivel);
        final pct = xpSiguiente > 0 ? xpEnNivel / xpSiguiente : 0.0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A1F5E), Color(0xFF1F1A40)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF7C6AF7).withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(colors: [
                        Color(0xFF9D8FFF),
                        Color(0xFF5A4ED4),
                      ]),
                    ),
                    child: Center(
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nivel $nivel — $nombre',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('$xpEnNivel / $xpSiguiente XP',
                            style: const TextStyle(
                                color: Color(0xFF9D8FFF), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: pct.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C6AF7), Color(0xFF5DE0C5)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C6AF7).withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeccion({
    required String titulo,
    required String icono,
    required String subtitulo,
    required List<Mision> misiones,
    required bool esSemanal,
  }) {
    final completadas = misiones.where((m) => m.reclamada).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Text(icono, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(titulo,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
            ]),
            Text('$completadas/${misiones.length}',
                style: const TextStyle(
                    color: Color(0xFF5DE0C5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitulo,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 12),
        ...misiones.map((m) => _MisionCard(
              mision: m,
              onReclamar: () => _reclamar(m, esSemanal),
              reclamando: _reclamando,
            )),
      ],
    );
  }

  Widget _buildTipXP() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('⚡', style: TextStyle(fontSize: 16)),
            SizedBox(width: 6),
            Text('Cómo ganar XP',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ]),
          SizedBox(height: 10),
          _TipRow('Completar misiones diarias', '+10–50 XP'),
          _TipRow('Completar misiones semanales', '+80–250 XP'),
          _TipRow('Recompensa de inicio diario', '+25 XP'),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String texto;
  final String xp;
  const _TipRow(this.texto, this.xp);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(texto,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(xp,
              style: const TextStyle(
                  color: Color(0xFF9D8FFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Tarjeta de misión ──────────────────────────────────────────────────────

class _MisionCard extends StatelessWidget {
  final Mision mision;
  final VoidCallback onReclamar;
  final bool reclamando;

  const _MisionCard({
    required this.mision,
    required this.onReclamar,
    required this.reclamando,
  });

  @override
  Widget build(BuildContext context) {
    final pct = mision.porcentaje;
    final Color barColor;
    final Color borderColor;

    if (mision.reclamada) {
      barColor = const Color(0xFF5DE0C5);
      borderColor = const Color(0xFF5DE0C5).withOpacity(0.4);
    } else if (mision.completada) {
      barColor = const Color(0xFFFFD700);
      borderColor = const Color(0xFFFFD700).withOpacity(0.5);
    } else {
      barColor = const Color(0xFF7C6AF7);
      borderColor = const Color(0xFF7C6AF7).withOpacity(0.2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(mision.descripcion,
                    style: TextStyle(
                        color: mision.reclamada
                            ? Colors.white54
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: mision.reclamada
                            ? TextDecoration.lineThrough
                            : null)),
              ),
              if (mision.reclamada)
                const Icon(Icons.check_circle,
                    color: Color(0xFF5DE0C5), size: 20),
            ],
          ),
          const SizedBox(height: 10),
          // Barra de progreso
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF12121E),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: mision.reclamada
                        ? []
                        : [
                            BoxShadow(
                              color: barColor.withOpacity(0.4),
                              blurRadius: 4,
                            )
                          ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text('${mision.progreso}/${mision.objetivo}',
                    style: TextStyle(
                        color: pct >= 1 ? barColor : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Text('🪙 ${mision.recompensaMonedas}',
                    style: const TextStyle(
                        color: Color(0xFFFFD700), fontSize: 12)),
                const SizedBox(width: 8),
                Text('⚡ ${mision.recompensaXp} XP',
                    style: const TextStyle(
                        color: Color(0xFF9D8FFF), fontSize: 12)),
              ]),
              if (mision.completada && !mision.reclamada)
                GestureDetector(
                  onTap: reclamando ? null : onReclamar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFF7A26A)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      reclamando ? '...' : 'Reclamar',
                      style: const TextStyle(
                          color: Color(0xFF1A1A10),
                          fontSize: 12,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
