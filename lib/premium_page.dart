import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'services/premium_service.dart';

const _kProductId      = 'estudiapp_premium_mensual';
const _kProductIdAnual = 'estudiapp_premium_mensual:anual';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});
  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  bool _loading = false;
  bool _isPremium = false;
  DateTime? _expiry;
  bool _trialDisponible = false;

  bool _iapAvailable = false;
  bool _loadingProducts = true;
  ProductDetails? _productoMensual;
  ProductDetails? _productoAnual;
  bool _planAnualSeleccionado = true; // anual recomendado por defecto
  late StreamSubscription<List<PurchaseDetails>> _purchaseSub;

  @override
  void initState() {
    super.initState();
    _purchaseSub = InAppPurchase.instance.purchaseStream
        .listen(_handlePurchases, onError: (_) {});
    _load();
    _initIAP();
  }

  @override
  void dispose() {
    _purchaseSub.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      PremiumService.isPremium(),
      PremiumService.expiry(),
      PremiumService.trialDisponible(),
    ]);
    if (mounted) {
      setState(() {
        _isPremium = results[0] as bool;
        _expiry    = results[1] as DateTime?;
        _trialDisponible = results[2] as bool;
      });
    }
  }

  Future<void> _initIAP() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      if (mounted) setState(() { _iapAvailable = false; _loadingProducts = false; });
      return;
    }
    if (!mounted) return;
    final res = await InAppPurchase.instance
        .queryProductDetails({_kProductId, _kProductIdAnual});
    if (mounted) {
      setState(() {
        _iapAvailable = true;
        _productoMensual = res.productDetails
            .where((p) => p.id == _kProductId).firstOrNull;
        _productoAnual = res.productDetails
            .where((p) => p.id == _kProductIdAnual).firstOrNull;
        // Si solo existe el mensual, pre-seleccionarlo
        if (_productoAnual == null && _productoMensual != null) {
          _planAnualSeleccionado = false;
        }
        _loadingProducts = false;
      });
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != _kProductId && p.productID != _kProductIdAnual) continue;

      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        await PremiumService.activarDesdePago(
          planId: p.productID,
          purchaseToken: p.verificationData.serverVerificationData,
        );
        await _load();
        if (p.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(p);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('¡Premium activado con éxito! 🎉'),
            backgroundColor: Color(0xFF7C6AF7),
            duration: Duration(seconds: 3),
          ));
        }
      } else if (p.status == PurchaseStatus.error) {
        if (p.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(p);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Error en el pago: ${p.error?.message ?? 'Intenta de nuevo'}'),
            backgroundColor: Colors.red.shade700,
          ));
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _activarTrial() async {
    setState(() => _loading = true);
    final activado = await PremiumService.activarTrialGratuito();
    if (!mounted) return;
    if (activado) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('¡7 días Premium activados! Disfruta sin límites 🎉'),
        backgroundColor: Color(0xFF5DE0C5),
        duration: Duration(seconds: 3),
      ));
    } else {
      if (!mounted) return;
      setState(() { _loading = false; _trialDisponible = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ya usaste el período de prueba gratuito.'),
        backgroundColor: Color(0xFF1E1E2A),
      ));
    }
  }

  Future<void> _comprar() async {
    final producto = _planAnualSeleccionado ? _productoAnual : _productoMensual;
    if (producto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Suscripción no disponible aún. Verifica tu conexión e intenta de nuevo.'),
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      await InAppPurchase.instance
          .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: producto));
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restaurar() async {
    setState(() => _loading = true);
    await InAppPurchase.instance.restorePurchases();
  }

  String get _precioMensual  => _productoMensual?.price  ?? 'S/. 15.00';
  String get _precioAnual    => _productoAnual?.price    ?? 'S/. 99.00';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('EstudiApp Premium',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C6AF7), Color(0xFF4A90E2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 12),
                  const Text('EstudiApp Premium',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Todo el poder del aprendizaje, sin límites',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 16),
                  if (_isPremium && _expiry != null)
                    _chip('✓ Activo hasta ${_expiry!.day}/${_expiry!.month}/${_expiry!.year}')
                  else
                    _chip('Desde $_precioMensual/mes · Cancela cuando quieras'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Benefits
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('QUÉ INCLUYE PREMIUM',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
            ),
            const SizedBox(height: 12),
            ..._beneficios.map((b) =>
                _beneficioCard(b['icon']!, b['titulo']!, b['desc']!)),
            const SizedBox(height: 28),

            // Plan selector (solo si no tiene Premium activo)
            if (!_isPremium) ...[
              _buildSelectorPlan(),
              const SizedBox(height: 28),
            ],

            // Comparison
            _buildComparacion(),
            const SizedBox(height: 28),

            // CTA
            if (_isPremium) ...[
              _activoCard(),
            ] else ...[
              if (_trialDisponible) ...[
                _botonTrialGratuito(),
                const SizedBox(height: 12),
              ],
              _botonSuscribirse(),
              const SizedBox(height: 12),
              if (_iapAvailable)
                TextButton(
                  onPressed: _loading ? null : _restaurar,
                  child: const Text('Restaurar compra anterior',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Pago seguro a través de Google Play · Cancela cuando quieras',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Selector de plan (Anual / Mensual) ──────────────────────────────────────

  Widget _buildSelectorPlan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ELIGE TU PLAN',
          style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // ── Anual ──────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _planAnualSeleccionado = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _planAnualSeleccionado
                        ? const Color(0xFF7C6AF7).withValues(alpha: 0.15)
                        : const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _planAnualSeleccionado
                          ? const Color(0xFF7C6AF7)
                          : Colors.white12,
                      width: _planAnualSeleccionado ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge RECOMENDADO
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C6AF7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('RECOMENDADO',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _precioAnual,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const Text('por año',
                          style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 6),
                      Text(
                        '≈ S/.8.25/mes',
                        style: TextStyle(
                            color: const Color(0xFF5DE0C5),
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5DE0C5).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('AHORRAS 45%',
                            style: TextStyle(
                                color: Color(0xFF5DE0C5),
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                      if (_planAnualSeleccionado)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Row(children: [
                            Icon(Icons.check_circle,
                                color: Color(0xFF7C6AF7), size: 14),
                            SizedBox(width: 4),
                            Text('Seleccionado',
                                style: TextStyle(
                                    color: Color(0xFF7C6AF7), fontSize: 10)),
                          ]),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // ── Mensual ────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _planAnualSeleccionado = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: !_planAnualSeleccionado
                        ? const Color(0xFF5DE0C5).withValues(alpha: 0.08)
                        : const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: !_planAnualSeleccionado
                          ? const Color(0xFF5DE0C5)
                          : Colors.white12,
                      width: !_planAnualSeleccionado ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('MENSUAL',
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _precioMensual,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const Text('por mes',
                          style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 18),
                      if (!_planAnualSeleccionado)
                        const Row(children: [
                          Icon(Icons.check_circle,
                              color: Color(0xFF5DE0C5), size: 14),
                          SizedBox(width: 4),
                          Text('Seleccionado',
                              style: TextStyle(
                                  color: Color(0xFF5DE0C5), fontSize: 10)),
                        ]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child:
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _botonTrialGratuito() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _activarTrial,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5DE0C5),
          disabledBackgroundColor: const Color(0xFF2E2E3E),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Probar 7 días gratis',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Sin tarjeta · Solo una vez por cuenta',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _botonSuscribirse() {
    final productoActual = _planAnualSeleccionado ? _productoAnual : _productoMensual;
    final disponible = _iapAvailable && !_loadingProducts && productoActual != null;
    final precio = _planAnualSeleccionado ? _precioAnual : _precioMensual;
    final periodo = _planAnualSeleccionado ? 'año' : 'mes';
    final sublinea = _planAnualSeleccionado
        ? 'Cobro anual vía Google Play · S/.8.25/mes'
        : 'Cobro mensual vía Google Play';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_loading || !disponible) ? null : _comprar,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C6AF7),
          disabledBackgroundColor: const Color(0xFF2E2E3E),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _loading || _loadingProducts
            ? const SizedBox(
                height: 22, width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    disponible
                        ? 'Suscribirse — $precio/$periodo'
                        : 'No disponible en este dispositivo',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (disponible) ...[
                    const SizedBox(height: 2),
                    Text(sublinea,
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _activoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF5DE0C5).withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Color(0xFF5DE0C5), size: 20),
          SizedBox(width: 8),
          Text('¡Ya tienes Premium activo!',
              style: TextStyle(
                  color: Color(0xFF5DE0C5),
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }

  static const _beneficios = [
    {
      'icon': '🏫',
      'titulo': 'Panel de Docente',
      'desc': 'Crea tu academia, agrega alumnos y gestiona exámenes'
    },
    {
      'icon': '📄',
      'titulo': 'PDF a Simulacro',
      'desc': 'Sube exámenes reales en PDF y la IA los convierte a tests interactivos'
    },
    {
      'icon': '👥',
      'titulo': 'Grupos de Estudio',
      'desc': 'Estudia en tiempo real con tus compañeros'
    },
    {
      'icon': '🔔',
      'titulo': 'Notificaciones Inteligentes',
      'desc': 'La IA programa tus recordatorios según tus exámenes y racha'
    },
    {
      'icon': '🎓',
      'titulo': 'IA sin límites',
      'desc': 'Genera contenido, flashcards y documentos sin restricciones'
    },
    {
      'icon': '🌎',
      'titulo': 'Simulacros de Admisión',
      'desc': 'Acceso a todos los países y tipos de examen de admisión'
    },
  ];

  Widget _beneficioCard(String icon, String titulo, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF7C6AF7).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7C6AF7).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.check_circle,
              color: Color(0xFF5DE0C5), size: 16),
        ],
      ),
    );
  }

  Widget _buildComparacion() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _fila('', 'Gratis', 'Premium', esHeader: true),
          _fila('Asistente IA', '5/día', 'Ilimitado'),
          _fila('Flashcards SRS', '✓', '✓'),
          _fila('Simulacros', '5 preguntas', 'Ilimitado'),
          _fila('PDF a Simulacro', '✗', '✓'),
          _fila('Grupos de estudio', '✗', '✓'),
          _fila('Panel Docente', '✗', '✓'),
          _fila('Sin anuncios', '✗', '✓'),
        ],
      ),
    );
  }

  Widget _fila(String feature, String free, String premium,
      {bool esHeader = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: esHeader
            ? const Color(0xFF7C6AF7).withValues(alpha: 0.15)
            : Colors.transparent,
        border: const Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(feature,
                style: TextStyle(
                    color:
                        esHeader ? const Color(0xFF7C6AF7) : Colors.white70,
                    fontSize: 13,
                    fontWeight:
                        esHeader ? FontWeight.bold : FontWeight.normal)),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(free,
                  style: TextStyle(
                      color: esHeader
                          ? Colors.white54
                          : free == '✓'
                              ? const Color(0xFF5DE0C5)
                              : free == '✗'
                                  ? Colors.red.shade300
                                  : Colors.white54,
                      fontSize: 13,
                      fontWeight: esHeader
                          ? FontWeight.bold
                          : FontWeight.normal)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(premium,
                  style: TextStyle(
                      color: esHeader
                          ? const Color(0xFF7C6AF7)
                          : premium == '✓' || premium == 'Ilimitado'
                              ? const Color(0xFF7C6AF7)
                              : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
