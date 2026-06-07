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

  /// Activa 7 días de prueba gratuita.
  /// Devuelve `true` si se activó, `false` si ya fue usado antes.
  /// Usa una transacción atómica para que nadie pueda activarlo dos veces.
  static Future<bool> activarTrialGratuito() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final ref = _db.collection('perfiles').doc(user.uid);
    bool activado = false;
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (doc.data()?['trialUsado'] == true) return; // ya usado → no hace nada
      tx.set(
        ref,
        {
          'isPremium': true,
          'premiumExpiry': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 7)),
          ),
          'premiumActivadoEn': Timestamp.now(),
          'planPremium': 'trial_7d',
          'trialUsado': true, // bandera anti-abuso (irreversible)
        },
        SetOptions(merge: true),
      );
      activado = true;
    });
    return activado;
  }

  /// `true` si la cuenta nunca ha usado el período de prueba gratuito.
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
