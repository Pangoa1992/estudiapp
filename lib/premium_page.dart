import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'services/premium_service.dart';
import 'l10n_helper.dart';

// IMPORTANTE: en Play Console NO hay dos productos separados. Hay UN ÚNICO
// producto de suscripción (`estudiapp_premium_mensual`) con VARIOS base plans;
// uno de ellos tiene el base plan ID 'anual'. Google devuelve un
// [GooglePlayProductDetails] por cada base plan/oferta, todos con el mismo
// `id` (= productId) pero distinto `basePlanId` y `offerToken`.
//
// El código anterior consultaba un segundo producto 'estudiapp_premium_anual'
// que NO existe → queryProductDetails lo devolvía en notFoundIDs, _productoAnual
// quedaba null y —al estar el plan anual seleccionado por defecto— el botón
// mostraba "No disponible en este dispositivo".
//
// Ahora se consulta un solo producto y se distinguen los planes por su
// `basePlanId`. Como el productID es idéntico para mensual y anual, la duración
// real (365 vs 31 días) NO puede deducirse del productID: PremiumService guarda
// el plan elegido justo antes de comprar (ver PremiumService.guardarPlanPendiente).
const _kProductId     = 'estudiapp_premium_mensual';
const _kBasePlanAnual = 'anual';

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
  GooglePlayProductDetails? _productoMensual;
  GooglePlayProductDetails? _productoAnual;
  // Oferta de suscripción de Google Play que incluye una fase de prueba
  // gratuita. Solo aparece si Play Console tiene configurada esa oferta y el
  // usuario es elegible (Google exige un método de pago para iniciarla y
  // auto-cobra al vencer). Si es null, NO se ofrece prueba gratuita.
  GooglePlayProductDetails? _ofertaTrial;
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
    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        if (mounted) setState(() { _iapAvailable = false; _loadingProducts = false; });
        return;
      }
      final res = await InAppPurchase.instance
          .queryProductDetails({_kProductId});

      // El producto de suscripción se expande en un GooglePlayProductDetails por
      // cada base plan/oferta (todos con el mismo `id`). Los separamos por
      // basePlanId: 'anual' → plan anual; cualquier otro → plan mensual.
      final ofertas =
          res.productDetails.whereType<GooglePlayProductDetails>().toList();

      // Diagnóstico: deja constancia en Crashlytics de los base plans que
      // devolvió Play. Permite verificar contra Play Console sin acceso directo
      // al dispositivo (p. ej. confirmar que existe el base plan 'anual').
      FirebaseCrashlytics.instance.log(
        '[Premium] queryProductDetails '
        'basePlans=${ofertas.map((p) => _basePlanId(p) ?? '?').toList()} '
        'notFound=${res.notFoundIDs}',
      );
      if (res.notFoundIDs.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(
          Exception('IAP productos no encontrados en Play: ${res.notFoundIDs}'),
          null,
          reason: 'queryProductDetails notFoundIDs',
          fatal: false,
        );
      }
      if (!mounted) return;
      setState(() {
        _iapAvailable = true;
        _productoAnual =
            _mejorOfertaBase(ofertas, (bp) => bp == _kBasePlanAnual);
        _productoMensual =
            _mejorOfertaBase(ofertas, (bp) => bp != _kBasePlanAnual);
        // Garantiza que el plan seleccionado por defecto sea uno realmente
        // disponible (en cualquiera de las dos direcciones), para no mostrar
        // "No disponible" mientras el otro plan sí se puede comprar.
        if (_planAnualSeleccionado &&
            _productoAnual == null &&
            _productoMensual != null) {
          _planAnualSeleccionado = false;
        } else if (!_planAnualSeleccionado &&
            _productoMensual == null &&
            _productoAnual != null) {
          _planAnualSeleccionado = true;
        }
        _ofertaTrial = _buscarOfertaTrial(res.productDetails);
        _loadingProducts = false;
      });
    } catch (_) {
      if (mounted) setState(() { _iapAvailable = false; _loadingProducts = false; });
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != _kProductId) continue;

      FirebaseCrashlytics.instance.log(
        '[Premium] PremiumPage evento: status=${p.status} product=${p.productID}',
      );

      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        try {
          await PremiumService.activarDesdePago(
            planId: p.productID,
            purchaseToken: p.verificationData.serverVerificationData,
          );
          FirebaseCrashlytics.instance.log(
            '[Premium] activarDesdePago OK: ${p.productID}',
          );
        } catch (e, st) {
          FirebaseCrashlytics.instance.recordError(
            e, st, reason: 'activarDesdePago falló en PremiumPage: ${p.productID}',
          );
        }
        if (p.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(p);
        }
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.premiumSuccess),
            backgroundColor: const Color(0xFF7C6AF7),
            duration: const Duration(seconds: 3),
          ));
        }
      } else if (p.status == PurchaseStatus.pending) {
        if (mounted) setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.paymentPending),
            backgroundColor: const Color(0xFF2A2A3E),
            duration: const Duration(seconds: 4),
          ));
        }
      } else if (p.status == PurchaseStatus.error) {
        FirebaseCrashlytics.instance.recordError(
          Exception('IAP error: ${p.error?.message} [${p.error?.code}]'),
          null,
          reason: 'Pago fallido en PremiumPage: ${p.productID}',
        );
        if (p.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(p);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.paymentError(
                p.error?.message ?? context.l10n.retry)),
            backgroundColor: Colors.red.shade700,
          ));
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Busca entre las ofertas devueltas por Google Play una que tenga una fase
  /// de precio 0 (prueba gratuita). Cada [GooglePlayProductDetails] representa
  /// una única oferta de un plan base. Devuelve `null` si ninguna tiene prueba
  /// gratuita (p. ej. no está configurada en Play Console o el usuario ya no es
  /// elegible por haberla usado antes).
  GooglePlayProductDetails? _buscarOfertaTrial(List<ProductDetails> productos) {
    for (final p in productos) {
      if (p is! GooglePlayProductDetails) continue;
      if (_tieneFaseGratis(p)) return p;
    }
    return null;
  }

  /// Devuelve el `basePlanId` de la oferta que representa este
  /// [GooglePlayProductDetails], o `null` si no se puede determinar.
  String? _basePlanId(GooglePlayProductDetails p) {
    final idx = p.subscriptionIndex;
    final ofertas = p.productDetails.subscriptionOfferDetails;
    if (idx == null || ofertas == null || idx >= ofertas.length) return null;
    return ofertas[idx].basePlanId;
  }

  /// `true` si la oferta incluye una fase de precio 0 (prueba gratuita o fase
  /// introductoria gratis).
  bool _tieneFaseGratis(GooglePlayProductDetails p) {
    final idx = p.subscriptionIndex;
    final ofertas = p.productDetails.subscriptionOfferDetails;
    if (idx == null || ofertas == null || idx >= ofertas.length) return false;
    return ofertas[idx]
        .pricingPhases
        .any((fase) => fase.priceAmountMicros == 0);
  }

  /// Elige, entre las ofertas cuyo basePlanId cumple [coincide], la oferta base
  /// recurrente para mostrar/comprar: se prefiere la que NO tiene fase gratuita
  /// (el precio "normal" del plan), dejando las ofertas con prueba gratuita para
  /// el flujo de trial. Devuelve `null` si no hay ninguna coincidencia.
  GooglePlayProductDetails? _mejorOfertaBase(
      List<GooglePlayProductDetails> ofertas, bool Function(String) coincide) {
    final candidatos = ofertas.where((p) {
      final bp = _basePlanId(p);
      return bp != null && coincide(bp);
    }).toList();
    if (candidatos.isEmpty) return null;
    return candidatos.firstWhere((p) => !_tieneFaseGratis(p),
        orElse: () => candidatos.first);
  }

  /// Inicia la prueba gratuita a través de Google Play (NO es un regalo local).
  /// Google Play exige un método de pago para arrancar el trial y auto-cobra la
  /// suscripción al vencer los 7 días. El resultado de la compra lo procesa
  /// [_handlePurchases] (y el listener global de main.dart para las renovaciones).
  Future<void> _activarTrial() async {
    final oferta = _ofertaTrial;
    // Si no hay oferta de prueba de Google Play disponible/elegible, no se
    // concede nada gratis: se informa que se requiere un método de pago.
    if (oferta == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.trialNeedsPaymentMethod),
        backgroundColor: const Color(0xFF2A2A3E),
        duration: const Duration(seconds: 5),
      ));
      return;
    }
    // La prueba gratuita está adjunta a un base plan concreto; al terminar el
    // trial la suscripción se convierte en ese plan. Guardamos ese plan para
    // que activarDesdePago otorgue la duración coherente.
    await PremiumService.guardarPlanPendiente(
        _basePlanId(oferta) == _kBasePlanAnual ? 'anual' : 'mensual');
    setState(() => _loading = true);
    try {
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: GooglePlayPurchaseParam(
          productDetails: oferta,
          offerToken: oferta.offerToken,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _comprar() async {
    final producto = _planAnualSeleccionado ? _productoAnual : _productoMensual;
    if (producto == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.notAvailable),
      ));
      return;
    }
    // El productID es el mismo para mensual y anual (un único producto con dos
    // base plans), así que guardamos el plan elegido para que activarDesdePago
    // otorgue la duración correcta (365 vs 31 días) sin depender del productID.
    await PremiumService.guardarPlanPendiente(
        _planAnualSeleccionado ? 'anual' : 'mensual');
    setState(() => _loading = true);
    try {
      // En un producto con varios base plans hay que indicar el offerToken del
      // base plan concreto; un PurchaseParam genérico no basta.
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: GooglePlayPurchaseParam(
          productDetails: producto,
          offerToken: producto.offerToken,
        ),
      );
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
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(l10n.premiumTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  Text(l10n.premiumTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(l10n.premiumSlogan,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 16),
                  if (_isPremium && _expiry != null)
                    _chip(l10n.activeUntilDate(_expiry!.day, _expiry!.month, _expiry!.year))
                  else
                    _chip(l10n.fromPrice(_precioMensual)),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Benefits
            Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.premiumIncludes,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
            ),
            const SizedBox(height: 12),
            ..._buildBeneficios(l10n).map((b) =>
                _beneficioCard(b['icon']!, b['titulo']!, b['desc']!)),
            const SizedBox(height: 28),

            // Plan selector (solo si no tiene Premium activo)
            if (!_isPremium) ...[
              _buildSelectorPlan(l10n),
              const SizedBox(height: 28),
            ],

            // Comparison
            _buildComparacion(l10n),
            const SizedBox(height: 28),

            // CTA
            if (_isPremium) ...[
              _activoCard(l10n),
            ] else ...[
              // Solo se muestra si el usuario nunca usó el trial (flag local)
              // Y Google Play tiene una oferta de prueba gratuita elegible.
              if (_trialDisponible && _ofertaTrial != null) ...[
                _botonTrialGratuito(l10n),
                const SizedBox(height: 12),
              ],
              _botonSuscribirse(l10n),
              const SizedBox(height: 12),
              if (_iapAvailable)
                TextButton(
                  onPressed: _loading ? null : _restaurar,
                  child: Text(l10n.restorePurchase,
                      style: const TextStyle(color: Colors.white38, fontSize: 13)),
                ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  l10n.securePayment,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white24, fontSize: 11),
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

  Widget _buildSelectorPlan(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.choosePlan,
          style: const TextStyle(
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
                        child: Text(l10n.recommended,
                            style: const TextStyle(
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
                      Text(l10n.perYear,
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 6),
                      const Text(
                        '≈ S/.8.25/mes',
                        style: TextStyle(
                            color: Color(0xFF5DE0C5),
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
                        child: Text(l10n.save45pct,
                            style: const TextStyle(
                                color: Color(0xFF5DE0C5),
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                      if (_planAnualSeleccionado)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(children: [
                            const Icon(Icons.check_circle,
                                color: Color(0xFF7C6AF7), size: 14),
                            const SizedBox(width: 4),
                            Text(l10n.selected,
                                style: const TextStyle(
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
                        child: Text(l10n.monthlyLabel,
                            style: const TextStyle(
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
                      Text(l10n.perMonth,
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 18),
                      if (!_planAnualSeleccionado)
                        Row(children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF5DE0C5), size: 14),
                          const SizedBox(width: 4),
                          Text(l10n.selected,
                              style: const TextStyle(
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

  Widget _botonTrialGratuito(AppLocalizations l10n) {
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
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.tryFree,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.tryFreeSubtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _botonSuscribirse(AppLocalizations l10n) {
    final productoActual = _planAnualSeleccionado ? _productoAnual : _productoMensual;
    final disponible = _iapAvailable && !_loadingProducts && productoActual != null;
    final precio = _planAnualSeleccionado ? _precioAnual : _precioMensual;
    final periodo = _planAnualSeleccionado ? l10n.perYear : l10n.perMonth;
    final sublinea = _planAnualSeleccionado ? l10n.billingAnnual : l10n.billingMonthly;

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
                        ? l10n.subscribeBtn(precio, periodo)
                        : l10n.notAvailable,
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

  Widget _activoCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF5DE0C5).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF5DE0C5), size: 20),
          const SizedBox(width: 8),
          Text(l10n.alreadyPremium,
              style: const TextStyle(
                  color: Color(0xFF5DE0C5),
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }

  List<Map<String, String>> _buildBeneficios(AppLocalizations l10n) => [
    {'icon': '🏫', 'titulo': l10n.b1Title, 'desc': l10n.b1Desc},
    {'icon': '📄', 'titulo': l10n.b2Title, 'desc': l10n.b2Desc},
    {'icon': '👥', 'titulo': l10n.b3Title, 'desc': l10n.b3Desc},
    {'icon': '🔔', 'titulo': l10n.b4Title, 'desc': l10n.b4Desc},
    {'icon': '🎓', 'titulo': l10n.b5Title, 'desc': l10n.b5Desc},
    {'icon': '🌎', 'titulo': l10n.b6Title, 'desc': l10n.b6Desc},
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

  Widget _buildComparacion(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _fila('', l10n.compFree, l10n.compPremium, esHeader: true),
          _fila(l10n.compAI, l10n.comp5day, l10n.compUnlimited),
          _fila(l10n.compFlashcards, '✓', '✓'),
          _fila(l10n.compSimulacros, l10n.comp5questions, l10n.compUnlimited),
          _fila(l10n.compPDF, '✗', '✓'),
          _fila(l10n.compGroups, '✗', '✓'),
          _fila(l10n.compTeacher, '✗', '✓'),
          _fila(l10n.compNoAds, '✗', '✓'),
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
