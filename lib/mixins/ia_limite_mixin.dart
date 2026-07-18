import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../services/ia_limite_service.dart';
import '../services/unity_ads_config.dart';
import '../premium_page.dart';

/// Mixin reutilizable que añade la pasarela de límite diario de búsquedas IA.
///
/// Uso en cualquier StatefulWidget:
/// ```dart
/// class _MiPageState extends State<MiPage> with IaLimiteMixin<MiPage> {
///   @override
///   void initState() {
///     super.initState();
///     initIaLimite();      // ← obligatorio
///   }
///
///   @override
///   void dispose() {
///     disposeIaLimite();   // ← obligatorio
///     super.dispose();
///   }
///
///   Future<void> _miAccionIA() async {
///     if (!await verificarYConsumir()) return;  // ← portón
///     // ...llamada a IAService...
///   }
/// }
/// ```
mixin IaLimiteMixin<T extends StatefulWidget> on State<T> {
  bool _iaRewardedLoaded = false;

  // Video recompensado de Unity Ads. Usa el mismo placement que ia_page.dart
  // (UnityAdsConfig.rewarded).

  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  void initIaLimite() => _cargarIaRewardedAd();

  // Unity usa un modelo estático por placement; no hay instancia que liberar.
  void disposeIaLimite() {}

  // ── API pública ───────────────────────────────────────────────────────────

  /// Verifica el límite diario y descuenta 1 búsqueda.
  /// Devuelve `false` (y muestra la pasarela) si el cupo está agotado.
  Future<bool> verificarYConsumir() async {
    final ok = await IaLimiteService.consumir();
    if (!ok) {
      await _mostrarIaPasarela();
      return false;
    }
    return true;
  }

  // ── Helpers internos ──────────────────────────────────────────────────────

  void _cargarIaRewardedAd() {
    UnityAds.load(
      placementId: UnityAdsConfig.rewarded,
      onComplete: (_) => _iaRewardedLoaded = true,
      onFailed: (_, error, message) => _iaRewardedLoaded = false,
    );
  }

  Future<void> _mostrarIaRewardedAd() async {
    if (!_iaRewardedLoaded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Anuncio no disponible. Intenta en un momento.')),
        );
      }
      return;
    }
    _iaRewardedLoaded = false;
    UnityAds.showVideoAd(
      placementId: UnityAdsConfig.rewarded,
      onComplete: (_) async {
        await IaLimiteService.agregarBonus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Ganaste 3 búsquedas extra! 🎉'),
              backgroundColor: Color(0xFF5DE0C5),
            ),
          );
        }
        _cargarIaRewardedAd(); // precarga el siguiente
      },
      onSkipped: (_) => _cargarIaRewardedAd(), // salteado → sin recompensa
      onFailed: (_, error, message) => _cargarIaRewardedAd(),
    );
  }

  Future<void> _mostrarIaPasarela() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E2A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7C6AF7).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Color(0xFF7C6AF7), size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin búsquedas disponibles',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Usaste tus 5 búsquedas gratuitas de hoy.\nVuelve mañana o gana más ahora mismo.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _iaRewardedLoaded
                    ? () {
                        Navigator.pop(ctx);
                        _mostrarIaRewardedAd();
                      }
                    : null,
                icon: const Icon(Icons.play_circle_outline,
                    color: Colors.white),
                label: const Text(
                  'Ver anuncio  (+3 búsquedas gratis)',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5DE0C5),
                  disabledBackgroundColor: const Color(0xFF2A2A3A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (!_iaRewardedLoaded)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Anuncio cargando, intenta de nuevo en un momento',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PremiumPage()),
                  );
                },
                icon: const Icon(Icons.star_rounded, color: Colors.white),
                label: const Text(
                  'Hacerse Premium — búsquedas ilimitadas',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6AF7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
      ),
    );
  }
}
