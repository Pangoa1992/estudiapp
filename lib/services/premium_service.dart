import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static final _db = FirebaseFirestore.instance;

  // Clave donde PremiumPage guarda el plan elegido ('anual' | 'mensual') justo
  // antes de lanzar la compra. Necesario porque mensual y anual comparten el
  // mismo productID de Google Play (un producto con dos base plans), así que el
  // productID que llega en el purchaseStream no permite distinguir la duración.
  static const _kPlanPendienteKey = 'premium_plan_pendiente';

  static Future<bool> isPremium() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final doc = await _db.collection('perfiles').doc(user.uid).get();
      return _evaluar(doc.data());
    } catch (_) {
      return false;
    }
  }

  static Stream<bool> streamPremium() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(false);
    return _db
        .collection('perfiles')
        .doc(user.uid)
        .snapshots()
        .map((s) => _evaluar(s.data()));
  }

  static bool _evaluar(Map<String, dynamic>? data) {
    if (data?['isPremium'] != true) return false;
    final expiry = (data?['premiumExpiry'] as Timestamp?)?.toDate();
    if (expiry != null && expiry.isBefore(DateTime.now())) return false;
    return true;
  }

  static Future<DateTime?> expiry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final doc = await _db.collection('perfiles').doc(user.uid).get();
      return (doc.data()?['premiumExpiry'] as Timestamp?)?.toDate();
    } catch (_) {
      return null;
    }
  }

  // NOTA: El antiguo `activarTrialGratuito()` se eliminó a propósito.
  // Concedía 7 días de Premium escribiendo directamente en Firestore, SIN
  // ninguna suscripción de Google Play detrás → nunca se cobraba al vencer.
  // Ahora la prueba gratuita se inicia como una oferta real de suscripción de
  // Google Play desde PremiumPage (`GooglePlayPurchaseParam` con offerToken de
  // la fase gratuita): Google exige método de pago y auto-cobra al terminar.
  // El alta la procesa `activarDesdePago()` vía el purchaseStream.

  /// `true` si la cuenta nunca ha usado el período de prueba gratuito.
  /// Guarda local anti-abuso; la elegibilidad real la determina Google Play.
  static Future<bool> trialDisponible() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final doc = await _db.collection('perfiles').doc(user.uid).get();
      return doc.data()?['trialUsado'] != true;
    } catch (_) {
      return false;
    }
  }

  /// Guarda el plan que el usuario está a punto de comprar ('anual' | 'mensual').
  /// Lo consume [activarDesdePago] cuando el productID no basta para distinguir
  /// la duración (mensual y anual comparten productID).
  static Future<void> guardarPlanPendiente(String plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPlanPendienteKey, plan);
    } catch (_) {/* si prefs falla, activarDesdePago usa el fallback 'mensual' */}
  }

  /// Resuelve el plan ('anual' | 'mensual') a partir del [planId] recibido de
  /// Google Play. Si el planId ya lo indica (compat. con datos antiguos) se usa;
  /// si es el productID genérico, se usa el plan guardado antes de comprar.
  /// Es determinista: los dos listeners (PremiumPage y HomePage) que procesan el
  /// mismo evento resuelven lo mismo, evitando escrituras contradictorias.
  static Future<String> _resolverPlan(String planId) async {
    final low = planId.toLowerCase();
    if (low.contains('anual')) return 'anual';
    if (low.contains('mensual') && !low.contains('estudiapp')) return 'mensual';
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendiente = prefs.getString(_kPlanPendienteKey);
      if (pendiente == 'anual' || pendiente == 'mensual') return pendiente!;
    } catch (_) {/* fallback abajo */}
    return 'mensual';
  }

  static Future<void> activarDesdePago({
    required String planId,
    String? purchaseToken,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Plan anual = 365 días; mensual = 31 días.
    final plan = await _resolverPlan(planId);
    final dias = plan == 'anual' ? 365 : 31;
    final expiry = DateTime.now().add(Duration(days: dias));
    await _db.collection('perfiles').doc(user.uid).set({
      'isPremium': true,
      'premiumExpiry': Timestamp.fromDate(expiry),
      'premiumActivadoEn': Timestamp.now(),
      // Etiqueta limpia ('anual' | 'mensual') en vez del productID crudo: la usa
      // la Cloud Function onPremiumActivado para el texto de la notificación.
      'planPremium': plan,
      'purchaseToken': purchaseToken,
    }, SetOptions(merge: true));
  }

  static Future<void> cancelar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db.collection('perfiles').doc(user.uid).set(
      {'isPremium': false},
      SetOptions(merge: true),
    );
  }
}
