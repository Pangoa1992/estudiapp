import 'dart:math';
import 'package:flutter/material.dart';
import '../services/niveles_service.dart';

class CelebracionWidget {
  CelebracionWidget._();

  /// Muestra un dialog de subida de nivel con animación de partículas.
  static Future<void> mostrarSubidaNivel(
      BuildContext context, int nivel) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'cerrar',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => _NivelSubidoDialog(nivel: nivel),
      transitionBuilder: (ctx, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  /// Muestra una notificación flotante al completar una misión.
  static void mostrarMisionCompletada(
      BuildContext context, String descripcion, int monedas, int xp) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _MisionBanner(
        descripcion: descripcion,
        monedas: monedas,
        xp: xp,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

// ── Dialog de nivel subido ─────────────────────────────────────────────────

class _NivelSubidoDialog extends StatefulWidget {
  final int nivel;
  const _NivelSubidoDialog({required this.nivel});

  @override
  State<_NivelSubidoDialog> createState() => _NivelSubidoDialogState();
}

class _NivelSubidoDialogState extends State<_NivelSubidoDialog>
    with TickerProviderStateMixin {
  late final AnimationController _particulas;
  late final AnimationController _pulso;
  late final List<_Particula> _lista;

  @override
  void initState() {
    super.initState();
    _lista = _generarParticulas(60);
    _particulas = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _particulas.dispose();
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nombre = NivelesService.nombreDeNivel(widget.nivel);
    final emoji = NivelesService.emojiDeNivel(widget.nivel);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti
          SizedBox(
            width: 340,
            height: 420,
            child: AnimatedBuilder(
              animation: _particulas,
              builder: (_, __) => CustomPaint(
                painter: _ParticulasPainter(
                  _lista,
                  _particulas.value,
                ),
                size: const Size(340, 420),
              ),
            ),
          ),
          // Tarjeta
          Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1E2A), Color(0xFF2A1F5E)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: const Color(0xFF7C6AF7).withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C6AF7).withOpacity(0.25),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('¡SUBISTE DE NIVEL!',
                    style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _pulso,
                  builder: (_, __) => Transform.scale(
                    scale: 1.0 + _pulso.value * 0.06,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(colors: [
                          Color(0xFF9D8FFF),
                          Color(0xFF5A4ED4),
                        ]),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C6AF7)
                                .withOpacity(0.5 + _pulso.value * 0.3),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 42)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Nivel ${widget.nivel}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(nombre,
                    style: const TextStyle(
                        color: Color(0xFF9D8FFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6AF7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('¡Seguir estudiando!',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Banner de misión completada ────────────────────────────────────────────

class _MisionBanner extends StatefulWidget {
  final String descripcion;
  final int monedas;
  final int xp;
  final VoidCallback onDismiss;

  const _MisionBanner({
    required this.descripcion,
    required this.monedas,
    required this.xp,
    required this.onDismiss,
  });

  @override
  State<_MisionBanner> createState() => _MisionBannerState();
}

class _MisionBannerState extends State<_MisionBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _slide = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), _salir);
  }

  Future<void> _salir() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).viewPadding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _salir,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14201E), Color(0xFF1A2A20)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF5DE0C5).withOpacity(0.6)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5DE0C5).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle,
                          color: Color(0xFF5DE0C5), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('¡Misión completada!',
                              style: TextStyle(
                                  color: Color(0xFF5DE0C5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                          Text(widget.descripcion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          Row(children: [
                            Text('🪙 +${widget.monedas}',
                                style: const TextStyle(
                                    color: Color(0xFFFFD700), fontSize: 12)),
                            const SizedBox(width: 10),
                            Text('⚡ +${widget.xp} XP',
                                style: const TextStyle(
                                    color: Color(0xFF9D8FFF), fontSize: 12)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Partículas de confeti ──────────────────────────────────────────────────

class _Particula {
  final double x;
  final double startY;
  final double velocidad;
  final double rotSpeed;
  final double ancho;
  final double alto;
  final Color color;

  const _Particula({
    required this.x,
    required this.startY,
    required this.velocidad,
    required this.rotSpeed,
    required this.ancho,
    required this.alto,
    required this.color,
  });
}

List<_Particula> _generarParticulas(int count) {
  const colores = [
    Color(0xFF7C6AF7),
    Color(0xFFFFD700),
    Color(0xFF5DE0C5),
    Color(0xFFF7584A),
    Color(0xFFF7A26A),
    Colors.white,
  ];
  final rng = Random();
  return List.generate(count, (_) {
    return _Particula(
      x: rng.nextDouble(),
      startY: -rng.nextDouble() * 200,
      velocidad: 0.6 + rng.nextDouble() * 0.8,
      rotSpeed: (rng.nextDouble() - 0.5) * 8,
      ancho: 6 + rng.nextDouble() * 6,
      alto: 4 + rng.nextDouble() * 4,
      color: colores[rng.nextInt(colores.length)],
    );
  });
}

class _ParticulasPainter extends CustomPainter {
  final List<_Particula> particulas;
  final double t;

  _ParticulasPainter(this.particulas, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particulas) {
      final paint = Paint()
        ..color = p.color.withOpacity((1 - t * 0.8).clamp(0.0, 1.0));
      final x = p.x * size.width;
      final y = p.startY + t * size.height * p.velocidad;
      if (y > size.height) continue;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * p.rotSpeed);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.ancho, height: p.alto),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticulasPainter old) => old.t != t;
}
