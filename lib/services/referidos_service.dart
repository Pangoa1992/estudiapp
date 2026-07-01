import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'monedas_service.dart';

class ReferidosService {
  static final _db = FirebaseFirestore.instance;
  static User? get _user => FirebaseAuth.instance.currentUser;

  static const int monedasNuevoUsuario = 50;
  static const int monedasReferidor = 100;

  /// Returns the existing referral code or generates a new unique one.
  static Future<String> generarOObtenerCodigo() async {
    if (_user == null) return '';
    try {
      final perfilDoc = await _db.collection('perfiles').doc(_user!.uid).get();
      final existing = perfilDoc.data()?['codigoReferido'] as String?;
      if (existing != null && existing.isNotEmpty) return existing;

      final nombre = (_user!.displayName ?? 'USER')
          .split(' ')
          .first
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final anio = DateTime.now().year.toString();
      final base = nombre.isEmpty ? 'USER$anio' : '$nombre$anio';

      String codigo = base;
      int sufijo = 2;
      while (true) {
        final doc = await _db.collection('referidos').doc(codigo).get();
        if (!doc.exists) break;
        if ((doc.data()?['uid'] as String?) == _user!.uid) {
          // Already exists for this user — sync and return
          await _db.collection('perfiles').doc(_user!.uid).set(
            {'codigoReferido': codigo},
            SetOptions(merge: true),
          );
          return codigo;
        }
        codigo = '$base$sufijo';
        sufijo++;
      }

      await _db.runTransaction((tx) async {
        tx.set(_db.collection('referidos').doc(codigo), {
          'uid': _user!.uid,
          'nombre': _user!.displayName ?? '',
          'codigo': codigo,
          'creadoEn': Timestamp.now(),
          'usos': 0,
        });
        tx.set(
          _db.collection('perfiles').doc(_user!.uid),
          {'codigoReferido': codigo},
          SetOptions(merge: true),
        );
      });
      return codigo;
    } catch (e) {
      debugPrint('[ReferidosService] generarOObtenerCodigo: $e');
      return '';
    }
  }

  /// Applies a referral code for the current user.
  /// Returns: 'ok' | 'ya_usado' | 'invalido' | 'propio' | 'error'
  static Future<String> aplicarCodigo(String codigo) async {
    if (_user == null) return 'error';
    codigo = codigo.trim().toUpperCase();
    if (codigo.isEmpty) return 'invalido';

    try {
      final perfilDoc = await _db.collection('perfiles').doc(_user!.uid).get();
      if (perfilDoc.data()?['codigoReferidoUsado'] != null) return 'ya_usado';

      final refDoc = await _db.collection('referidos').doc(codigo).get();
      if (!refDoc.exists) return 'invalido';

      final refUid = refDoc.data()?['uid'] as String?;
      if (refUid == _user!.uid) return 'propio';

      final usoRef = _db
          .collection('referidos')
          .doc(codigo)
          .collection('usos')
          .doc(_user!.uid);
      if ((await usoRef.get()).exists) return 'ya_usado';

      await _db.runTransaction((tx) async {
        tx.set(usoRef, {
          'uid': _user!.uid,
          'nombre': _user!.displayName ?? '',
          'fecha': Timestamp.now(),
          'monedasReferidor': monedasReferidor,
        });
        tx.update(_db.collection('referidos').doc(codigo), {
          'usos': FieldValue.increment(1),
        });
        tx.set(
          _db.collection('perfiles').doc(_user!.uid),
          {'codigoReferidoUsado': codigo},
          SetOptions(merge: true),
        );
      });

      await MonedasService.agregar(monedasNuevoUsuario, 'referido_bienvenida');
      if (refUid != null) {
        await _db.collection('perfiles').doc(refUid).set(
          {'monedas': FieldValue.increment(monedasReferidor)},
          SetOptions(merge: true),
        );
      }
      return 'ok';
    } catch (e) {
      debugPrint('[ReferidosService] aplicarCodigo: $e');
      return 'error';
    }
  }

  /// Returns the list of users referred by the current user.
  static Future<List<Map<String, dynamic>>> obtenerHistorial() async {
    if (_user == null) return [];
    try {
      final perfilDoc = await _db.collection('perfiles').doc(_user!.uid).get();
      final codigo = perfilDoc.data()?['codigoReferido'] as String? ?? '';
      if (codigo.isEmpty) return [];
      final snap = await _db
          .collection('referidos')
          .doc(codigo)
          .collection('usos')
          .orderBy('fecha', descending: true)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('[ReferidosService] obtenerHistorial: $e');
      return [];
    }
  }
}
