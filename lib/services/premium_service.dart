import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static final _db = FirebaseFirestore.instance;

  // Clave donde PremiumPage guarda el plan elegido ('anual' | 'mensual') justo
  // antes de lanzar la compra. Necesario porque mensual y anual comparten el
  // mismo productID de Google Play (un producto con dos base plans), así que el
  // productID que llega en el purchaseStream no permite distinguir la duración.
  static const _kPlanPendienteKey = 'premium_plan_pendiente';

  // ── Prueba gratuita ─────────────────────────────────────────────────────────
  // El purchaseStream NO dice si la compra usó la oferta de prueba gratuita: el
  // productID y el token son idénticos a los de una compra pagada. Estas claves
  // llevan ese dato desde el momento en que PremiumPage lanza el flujo de compra
  // hasta que llega el evento de Google Play.
  static const _kTrialDiasKey    = 'premium_trial_dias';
  static const _kTrialLanzadoKey = 'premium_trial_lanzado';
  static const _kTrialHastaKey   = 'premium_trial_hasta';

  /// Ventana durante la cual un trial lanzado sigue considerándose "pendiente".
  /// Google Play puede tardar (compras en estado `pending`, pagos en efectivo),
  /// pero pasado este plazo asumimos que el usuario abandonó el flujo de prueba;
  /// así una compra PAGADA posterior no se etiqueta como trial por error.
  static const _kTrialPendienteTtl = Duration(hours: 24);

  /// Etiqueta de `planPremium` para un trial en curso.
  ///
  /// Es una ETIQUETA, no una duración: los días reales de la prueba los define
  /// la oferta de Play Console y viajan en `premiumExpiry`. La consumen las
  /// Cloud Functions `recordarExpiracionTrial` y `desactivarTrialsVencidos`, y
  /// `onPremiumActivado` para el texto del push al admin.
  static const planTrial = 'trial_7d';

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

  /// Marca que se acaba de lanzar la compra de la oferta con prueba gratuita.
  ///
  /// [dias] son los días de la fase gratuita según Play Console y [planBase] es
  /// el plan al que la suscripción se convertirá cuando la prueba termine
  /// ('anual' | 'mensual'), para que la conversión otorgue la duración correcta.
  static Future<void> iniciarTrialPendiente({
    required int dias,
    required String planBase,
  }) async {
    await guardarPlanPendiente(planBase);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kTrialDiasKey, dias);
      await prefs.setString(
          _kTrialLanzadoKey, DateTime.now().toIso8601String());
      // Una prueba anterior pudo dejar su fecha de fin: sin limpiarla, el paso 1
      // de [_trialHasta] la reutilizaría para este trial nuevo.
      await prefs.remove(_kTrialHastaKey);
    } catch (_) {/* sin prefs el trial se activará como plan pagado */}
  }

  /// Descarta el trial pendiente. La llama PremiumPage antes de una compra
  /// PAGADA: si el usuario abrió el flujo de prueba, lo canceló y acabó
  /// suscribiéndose, esa compra no debe etiquetarse como trial.
  static Future<void> limpiarTrialPendiente() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTrialDiasKey);
      await prefs.remove(_kTrialLanzadoKey);
    } catch (_) {/* el TTL de _kTrialPendienteTtl cubre este caso */}
  }

  /// Fecha de fin del trial en curso, o `null` si esta compra no es un trial.
  ///
  /// Se resuelve en tres pasos:
  ///  1. `_kTrialHastaKey`: el trial ya se activó antes en este dispositivo. Se
  ///     devuelve tal cual para que `premiumExpiry` quede ESTABLE — los eventos
  ///     `restored` que llegan en cada arranque no deben empujar la fecha hacia
  ///     adelante, o la prueba nunca vencería.
  ///  2. `_kTrialDiasKey`: la compra recién lanzada era el trial → se calcula el
  ///     fin (ahora + días) y se persiste para el paso 1.
  ///  3. Firestore: reinstalación a mitad de la prueba, sin claves locales. Sin
  ///     este paso el `restored` posterior escribiría un plan pagado con 31 días.
  ///
  /// Si la prueba ya terminó, limpia las claves y devuelve `null`: ese evento es
  /// la conversión a suscripción pagada.
  static Future<DateTime?> _trialHasta(String uid) async {
    final ahora = DateTime.now();
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {/* sin prefs se intenta el paso 3 */}

    // ── 1. Trial ya activado en este dispositivo ──────────────────────────────
    final guardada = DateTime.tryParse(prefs?.getString(_kTrialHastaKey) ?? '');
    if (guardada != null) {
      if (guardada.isAfter(ahora)) return guardada;
      await prefs?.remove(_kTrialHastaKey);
      await prefs?.remove(_kTrialDiasKey);
      await prefs?.remove(_kTrialLanzadoKey);
      return null;
    }

    // ── 2. Trial lanzado hace poco y aún sin activar ──────────────────────────
    final dias = prefs?.getInt(_kTrialDiasKey) ?? 0;
    final lanzado =
        DateTime.tryParse(prefs?.getString(_kTrialLanzadoKey) ?? '');
    if (dias > 0 &&
        lanzado != null &&
        ahora.difference(lanzado) <= _kTrialPendienteTtl) {
      final hasta = ahora.add(Duration(days: dias));
      await prefs?.setString(_kTrialHastaKey, hasta.toIso8601String());
      return hasta;
    }

    // ── 3. ¿Firestore dice que este perfil tiene un trial vigente? ────────────
    // Solo se consulta cuando las prefs no son de fiar. Si `_kPlanPendienteKey`
    // sigue ahí, las prefs sobrevivieron y la ausencia de claves de trial ya es
    // respuesta suficiente; así los eventos `restored` que llegan en cada
    // arranque (los de quien ya paga) no cuestan una lectura extra de Firestore.
    if (prefs?.getString(_kPlanPendienteKey) != null) return null;

    try {
      final doc = await _db.collection('perfiles').doc(uid).get();
      final data = doc.data();
      if (data?['planPremium'] != planTrial) return null;
      final expiry = (data?['premiumExpiry'] as Timestamp?)?.toDate();
      if (expiry == null || !expiry.isAfter(ahora)) return null;
      await prefs?.setString(_kTrialHastaKey, expiry.toIso8601String());
      return expiry;
    } catch (_) {
      return null;
    }
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

  /// Activa Premium en Firestore a partir de una compra de Google Play.
  ///
  /// Devuelve `true` si la activación se escribió. Devuelve `false` —sin tocar
  /// Firestore— cuando [purchaseToken] llega nulo o vacío.
  ///
  /// El token (`serverVerificationData` del purchaseStream) es el purchaseToken
  /// de Google Play Billing y es la ÚNICA prueba de que existe una suscripción
  /// real detrás. Si viene vacío no hay nada que verificar contra la Play
  /// Developer API, así que escribir `isPremium: true` regalaría la suscripción.
  /// Bug detectado el 02-sep-2026: un perfil quedó Premium (`planPremium:
  /// 'mensual'`) con `purchaseToken: ''`, y el panel admin lo contó como
  /// S/. 15 de ingreso. [origen] identifica el call site en los logs.
  static Future<bool> activarDesdePago({
    required String planId,
    String? purchaseToken,
    String origen = 'desconocido',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final token = purchaseToken?.trim() ?? '';
    if (token.isEmpty) {
      // No-fatal a Crashlytics: hay que poder verlo en el dashboard sin
      // depender de que el usuario reporte que pagó y no le activó.
      FirebaseCrashlytics.instance.log(
        '[Premium] RECHAZADA activación sin purchaseToken '
        '(origen=$origen, planId=$planId, uid=${user.uid})',
      );
      await FirebaseCrashlytics.instance.setCustomKey(
          'premium_token_vacio_origen', origen);
      await FirebaseCrashlytics.instance.recordError(
        Exception(
          'purchaseToken vacío: Premium NO activado '
          '(origen=$origen, planId=$planId, uid=${user.uid}, '
          'tokenEraNulo=${purchaseToken == null})',
        ),
        StackTrace.current,
        reason: 'serverVerificationData vacío en purchaseStream',
        fatal: false,
      );
      return false;
    }

    // ── Prueba gratuita de Google Play ────────────────────────────────────────
    // Un trial no es una compra pagada: se etiqueta [planTrial] y expira cuando
    // termina la fase gratuita, no a los 31/365 días. Así `desactivarTrialsVencidos`
    // puede apagar el Premium de quien cancele antes de la conversión (en ese caso
    // Play nunca manda el evento de cobro y el perfil quedaría Premium para siempre).
    final trialHasta = await _trialHasta(user.uid);
    if (trialHasta != null) {
      FirebaseCrashlytics.instance.log(
        '[Premium] trial activado hasta ${trialHasta.toIso8601String()} '
        '(origen=$origen, planId=$planId)',
      );
      await _db.collection('perfiles').doc(user.uid).set({
        'isPremium': true,
        'premiumExpiry': Timestamp.fromDate(trialHasta),
        'premiumActivadoEn': Timestamp.now(),
        'planPremium': planTrial,
        'purchaseToken': token,
        // Cierra el botón "probar gratis" en este perfil (ver trialDisponible).
        'trialUsado': true,
      }, SetOptions(merge: true));
      return true;
    }

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
      'purchaseToken': token,
    }, SetOptions(merge: true));
    return true;
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
