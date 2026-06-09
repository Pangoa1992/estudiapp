import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captura un widget como imagen PNG y lo comparte via share_plus.
class CompartirService {
  /// Muestra un bottom sheet con vista previa de la [tarjeta] y botón de compartir.
  static Future<void> mostrar({
    required BuildContext context,
    required Widget tarjeta,
    String texto = '',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CompartirSheet(tarjeta: tarjeta, texto: texto),
    );
  }

  // Captura la RepaintBoundary identificada por [key] y la comparte.
  static Future<void> _capturar(GlobalKey key, String texto) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/estudiapp_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes.buffer.asUint8List());
    await Share.shareXFiles([XFile(file.path)], text: texto);
  }

  // ── Tarjetas ──────────────────────────────────────────────────────────────

  static Widget tarjetaResultado({
    required String titulo,
    required int correctas,
    required int total,
    required int porcentaje,
    required String nombreUsuario,
  }) {
    final color = porcentaje >= 70
        ? const Color(0xFF5DE0C5)
        : porcentaje >= 50
            ? const Color(0xFFF7A26A)
            : const Color(0xFFF7584A);
    final emoji =
        porcentaje >= 70 ? '🎉' : porcentaje >= 50 ? '👍' : '💪';

    return _TarjetaBase(
      accentColor: color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Logo(),
          const SizedBox(height: 16),
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(titulo,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 10),
          Text('$porcentaje%',
              style: TextStyle(
                  color: color,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  height: 1.0)),
          const SizedBox(height: 4),
          Text('$correctas de $total correctas',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const _Divisor(),
          _Firma(nombre: nombreUsuario),
        ],
      ),
    );
  }

  static Widget tarjetaLogro({
    required String emoji,
    required String titulo,
    required String descripcion,
    required Color color,
    required String nombreUsuario,
  }) {
    return _TarjetaBase(
      accentColor: color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Logo(),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text('🏆 LOGRO DESBLOQUEADO',
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ),
          const SizedBox(height: 16),
          Text(emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          Text(titulo,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(descripcion,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12)),
          const _Divisor(),
          _Firma(nombre: nombreUsuario),
        ],
      ),
    );
  }

  static Widget tarjetaRacha({
    required int racha,
    required String nombreUsuario,
  }) {
    final color = racha >= 30
        ? const Color(0xFFFFD700)
        : racha >= 7
            ? const Color(0xFFF7A26A)
            : const Color(0xFFF7584A);

    return _TarjetaBase(
      accentColor: color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Logo(),
          const SizedBox(height: 16),
          const Text('🔥', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 6),
          Text('$racha',
              style: TextStyle(
                  color: color,
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  height: 1.0)),
          Text('días de racha',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  letterSpacing: 1)),
          const SizedBox(height: 6),
          Text('¡Sin parar! 🚀',
              style: TextStyle(
                  color: color.withValues(alpha: 0.8), fontSize: 12)),
          const _Divisor(),
          _Firma(nombre: nombreUsuario),
        ],
      ),
    );
  }
}

// ── Widgets internos de tarjeta ───────────────────────────────────────────────

class _TarjetaBase extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  const _TarjetaBase({required this.child, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: accentColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: accentColor.withValues(alpha: 0.12),
              blurRadius: 24,
              spreadRadius: 2),
        ],
      ),
      child: child,
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            'assets/icon/icono_estudiapp.png',
            width: 26,
            height: 26,
            errorBuilder: (_, __, ___) => Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFF7C6AF7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text('E',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text('EstudiApp',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ],
    );
  }
}

class _Divisor extends StatelessWidget {
  const _Divisor();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Container(height: 1, color: Colors.white12),
    );
  }
}

class _Firma extends StatelessWidget {
  final String nombre;
  const _Firma({required this.nombre});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.person_outline, color: Colors.white38, size: 13),
        const SizedBox(width: 4),
        Text(nombre,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}

// ── Bottom sheet de compartir ─────────────────────────────────────────────────

class _CompartirSheet extends StatefulWidget {
  final Widget tarjeta;
  final String texto;
  const _CompartirSheet(
      {required this.tarjeta, required this.texto});
  @override
  State<_CompartirSheet> createState() => _CompartirSheetState();
}

class _CompartirSheetState extends State<_CompartirSheet> {
  final _key = GlobalKey();
  bool _compartiendo = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('COMPARTIR',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            // Vista previa capturada
            RepaintBoundary(key: _key, child: widget.tarjeta),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _compartiendo
                    ? null
                    : () async {
                        setState(() => _compartiendo = true);
                        try {
                          await CompartirService._capturar(
                              _key, widget.texto);
                        } finally {
                          if (mounted) {
                            setState(() => _compartiendo = false);
                          }
                        }
                      },
                icon: _compartiendo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.share, color: Colors.white),
                label: Text(
                  _compartiendo ? 'Preparando...' : 'Compartir imagen',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6AF7),
                  disabledBackgroundColor: const Color(0xFF3A3A5A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
