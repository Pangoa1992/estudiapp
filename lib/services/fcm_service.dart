import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../admin_page.dart';

/// Gestiona el token FCM del usuario actual.
///
/// - Guarda el token en `perfiles/{uid}.fcmToken` para que la Cloud Function
///   pueda enviarle notificaciones personalizadas (Feature 3: racha sin cupo).
/// - Si el usuario es admin, también lo guarda en `fcm_tokens/admin` para que
///   las Cloud Functions puedan notificarle eventos globales (Feature 2: nuevo Premium).
///
/// Llamar [inicializar] una sola vez, cuando el usuario ya esté autenticado
/// (típicamente en HomePage.initState).
class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  /// Solicita permisos, obtiene el token FCM y lo persiste en Firestore.
  /// No lanza excepciones: todos los errores se loguean con debugPrint.
  static Future<void> inicializar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Solicitar permisos (Android 13+ e iOS requieren esta llamada explícita)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FcmService] Permisos de notificación denegados.');
        return;
      }

      // Obtener token actual y guardarlo
      final token = await _messaging.getToken();
      if (token != null) {
        await _guardarToken(user, token);
      }

      // Escuchar renovaciones automáticas del token (Firebase lo rota periódicamente)
      _messaging.onTokenRefresh.listen((nuevoToken) async {
        final u = FirebaseAuth.instance.currentUser;
        if (u != null) await _guardarToken(u, nuevoToken);
      });
    } catch (e) {
      debugPrint('[FcmService] Error al inicializar: $e');
    }
  }

  static Future<void> _guardarToken(User user, String token) async {
    try {
      // 1. Perfil del usuario — para notificaciones personalizadas (racha sin cupo)
      await _db.collection('perfiles').doc(user.uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );

      // 2. Si es admin, también en fcm_tokens/admin — para alertas globales
      if (user.email?.toLowerCase() == AdminPage.adminEmail.toLowerCase()) {
        await _db.collection('fcm_tokens').doc('admin').set(
          {
            'token': token,
            'actualizadoEn': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('[FcmService] Error al guardar token: $e');
    }
  }

  /// Elimina el token al cerrar sesión para no recibir notificaciones post-logout.
  static Future<void> limpiarToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _db.collection('perfiles').doc(user.uid).set(
        {'fcmToken': FieldValue.delete()},
        SetOptions(merge: true),
      );
      if (user.email?.toLowerCase() == AdminPage.adminEmail.toLowerCase()) {
        await _db.collection('fcm_tokens').doc('admin').delete();
      }
    } catch (e) {
      debugPrint('[FcmService] Error al limpiar token: $e');
    }
  }
}
