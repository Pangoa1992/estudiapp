import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PremiumService {
  static final _db = FirebaseFirestore.instance;

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

  static Future<void> activarDesdePago({
    required String planId,
    String? purchaseToken,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Plan anual = 365 días; mensual = 31 días
    final dias = planId.contains('anual') ? 365 : 31;
    final expiry = DateTime.now().add(Duration(days: dias));
    await _db.collection('perfiles').doc(user.uid).set({
      'isPremium': true,
      'premiumExpiry': Timestamp.fromDate(expiry),
      'premiumActivadoEn': Timestamp.now(),
      'planPremium': planId,
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
