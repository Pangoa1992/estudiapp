import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/mision_model.dart';
import 'niveles_service.dart';
import 'monedas_service.dart';

class MisionesService {
  static final _db = FirebaseFirestore.instance;
  static User? get _user => FirebaseAuth.instance.currentUser;

  // ── Pools de misiones ──────────────────────────────────────────────────────

  static const _poolDiario = [
    {'id': 'd_racha', 'tipo': 'racha', 'descripcion': 'Mantén tu racha activa hoy', 'objetivo': 1, 'monedas': 15, 'xp': 10},
    {'id': 'd_pomo1', 'tipo': 'pomodoro_dia', 'descripcion': 'Completa 1 sesión Pomodoro', 'objetivo': 1, 'monedas': 20, 'xp': 15},
    {'id': 'd_pomo2', 'tipo': 'pomodoro_dia', 'descripcion': 'Estudia 50 min (2 Pomodoros)', 'objetivo': 2, 'monedas': 35, 'xp': 25},
    {'id': 'd_hab3', 'tipo': 'habito_dia', 'descripcion': 'Marca 3 hábitos completados', 'objetivo': 3, 'monedas': 30, 'xp': 20},
    {'id': 'd_hab5', 'tipo': 'habito_dia', 'descripcion': 'Completa 5 hábitos hoy', 'objetivo': 5, 'monedas': 50, 'xp': 35},
    {'id': 'd_ia1', 'tipo': 'ia_dia', 'descripcion': 'Usa el Asistente IA 1 vez', 'objetivo': 1, 'monedas': 15, 'xp': 10},
    {'id': 'd_ia3', 'tipo': 'ia_dia', 'descripcion': 'Usa el Asistente IA 3 veces', 'objetivo': 3, 'monedas': 35, 'xp': 25},
    {'id': 'd_racha3', 'tipo': 'racha_minima', 'descripcion': 'Mantén racha de 3+ días', 'objetivo': 3, 'monedas': 25, 'xp': 20},
  ];

  static const _poolSemanal = [
    {'id': 's_pomo5', 'tipo': 'pomodoro_semana', 'descripcion': 'Completa 5 Pomodoros esta semana', 'objetivo': 5, 'monedas': 100, 'xp': 80},
    {'id': 's_pomo10', 'tipo': 'pomodoro_semana', 'descripcion': 'Completa 10 Pomodoros esta semana', 'objetivo': 10, 'monedas': 180, 'xp': 140},
    {'id': 's_racha5', 'tipo': 'racha_minima', 'descripcion': 'Alcanza racha de 5 días', 'objetivo': 5, 'monedas': 120, 'xp': 90},
    {'id': 's_racha7', 'tipo': 'racha_minima', 'descripcion': 'Alcanza racha de 7 días', 'objetivo': 7, 'monedas': 200, 'xp': 150},
    {'id': 's_racha14', 'tipo': 'racha_minima', 'descripcion': 'Alcanza racha de 14 días', 'objetivo': 14, 'monedas': 350, 'xp': 250},
    {'id': 's_hab20', 'tipo': 'habito_dia', 'descripcion': 'Completa 20 hábitos esta semana', 'objetivo': 20, 'monedas': 150, 'xp': 120},
  ];

  // ── Helpers de fecha ───────────────────────────────────────────────────────

  static String _hoyStr() {
    final d = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String _semanaStr() {
    final d = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    // ISO week: Monday-based
    final lunes = d.subtract(Duration(days: d.weekday - 1));
    return '${lunes.year}-W${lunes.month.toString().padLeft(2, '0')}-${lunes.day.toString().padLeft(2, '0')}';
  }

  static DateTime _inicioSemana() {
    final d = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    final lunes = d.subtract(Duration(days: d.weekday - 1));
    return DateTime(lunes.year, lunes.month, lunes.day);
  }

  // ── Selección de misiones ──────────────────────────────────────────────────

  static List<Mision> _seleccionarDiarias(String uid, String hoy) {
    final seed = uid.hashCode ^ hoy.hashCode;
    final rng = Random(seed.abs());
    final pool = List<Map<String, Object>>.from(_poolDiario)..shuffle(rng);
    return pool.take(3).map((m) => Mision(
          id: m['id'] as String,
          tipo: m['tipo'] as String,
          descripcion: m['descripcion'] as String,
          objetivo: m['objetivo'] as int,
          recompensaMonedas: m['monedas'] as int,
          recompensaXp: m['xp'] as int,
        )).toList();
  }

  static List<Mision> _seleccionarSemanales(String uid, String semana) {
    final seed = uid.hashCode ^ semana.hashCode;
    final rng = Random(seed.abs());
    final pool = List<Map<String, Object>>.from(_poolSemanal)..shuffle(rng);
    return pool.take(2).map((m) => Mision(
          id: m['id'] as String,
          tipo: m['tipo'] as String,
          descripcion: m['descripcion'] as String,
          objetivo: m['objetivo'] as int,
          recompensaMonedas: m['monedas'] as int,
          recompensaXp: m['xp'] as int,
        )).toList();
  }

  // ── API pública ────────────────────────────────────────────────────────────

  /// Llama al arrancar la app. Genera misiones nuevas si el día/semana cambió.
  static Future<void> generarMisionesSiNecesario() async {
    final uid = _user?.uid;
    if (uid == null) return;
    try {
      final hoy = _hoyStr();
      final semana = _semanaStr();
      final ref = _db.collection('misiones').doc(uid);
      final doc = await ref.get();
      final data = doc.exists ? doc.data()! : <String, dynamic>{};

      final bool nuevoDia = data['ultima_actualizacion_diaria'] != hoy;
      final bool nuevaSemana = data['ultima_actualizacion_semanal'] != semana;

      final diarias = nuevoDia
          ? _seleccionarDiarias(uid, hoy)
          : (data['diarias'] as List? ?? [])
              .map((m) => Mision.fromMap(m as Map<String, dynamic>))
              .toList();

      final semanales = nuevaSemana
          ? _seleccionarSemanales(uid, semana)
          : (data['semanales'] as List? ?? [])
              .map((m) => Mision.fromMap(m as Map<String, dynamic>))
              .toList();

      if (nuevoDia || nuevaSemana) {
        await ref.set({
          'diarias': diarias.map((m) => m.toMap()).toList(),
          'semanales': semanales.map((m) => m.toMap()).toList(),
          'ultima_actualizacion_diaria': hoy,
          'ultima_actualizacion_semanal': semana,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[MisionesService] Error generarMisiones: $e');
    }
  }

  /// Actualiza el progreso de cada misión consultando Firestore.
  /// Llama al abrir MisionesPage.
  static Future<void> actualizarProgreso() async {
    final uid = _user?.uid;
    if (uid == null) return;
    try {
      final hoy = _hoyStr();
      final ref = _db.collection('misiones').doc(uid);
      final [misionesDoc, perfilDoc] = await Future.wait([
        ref.get(),
        _db.collection('perfiles').doc(uid).get(),
      ]);

      if (!misionesDoc.exists) return;
      final mData = misionesDoc.data()!;
      final pData = perfilDoc.data() ?? {};

      final racha = (pData['racha'] as num? ?? 0).toInt();
      final iaFecha = pData['ia_fecha_hoy'] as String? ?? '';
      final iaUsos = iaFecha == hoy ? (pData['ia_usos_hoy'] as num? ?? 0).toInt() : 0;

      final diarias = (mData['diarias'] as List? ?? [])
          .map((m) => Mision.fromMap(m as Map<String, dynamic>))
          .toList();
      final semanales = (mData['semanales'] as List? ?? [])
          .map((m) => Mision.fromMap(m as Map<String, dynamic>))
          .toList();
      final todas = [...diarias, ...semanales];

      // Queries de Firestore solo cuando se necesitan
      int pomodorosDia = 0;
      int pomodorosSemana = 0;
      int habitosDia = 0;

      final necPomoDia = todas.any((m) => m.tipo == 'pomodoro_dia' && !m.reclamada);
      final necPomoSemana = todas.any((m) => m.tipo == 'pomodoro_semana' && !m.reclamada);
      final necHabito = todas.any((m) => m.tipo == 'habito_dia' && !m.reclamada);

      final futures = <Future>[];
      if (necPomoDia) {
        futures.add(
          _db.collection('sesiones_pomodoro')
              .where('userId', isEqualTo: uid)
              .where('fechaStr', isEqualTo: hoy)
              .get()
              .then((s) => pomodorosDia = s.docs.length),
        );
      }
      if (necPomoSemana) {
        futures.add(
          _db.collection('sesiones_pomodoro')
              .where('userId', isEqualTo: uid)
              .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(_inicioSemana()))
              .get()
              .then((s) => pomodorosSemana = s.docs.length),
        );
      }
      if (necHabito) {
        futures.add(
          _db.collection('habitos')
              .where('userId', isEqualTo: uid)
              .where('done', isEqualTo: true)
              .get()
              .then((s) => habitosDia = s.docs.length),
        );
      }
      await Future.wait(futures);

      void actualizar(List<Mision> lista) {
        for (final m in lista) {
          if (m.reclamada) continue;
          final p = switch (m.tipo) {
            'racha' => racha > 0 ? 1 : 0,
            'racha_minima' => racha.clamp(0, m.objetivo),
            'pomodoro_dia' => pomodorosDia.clamp(0, m.objetivo),
            'pomodoro_semana' => pomodorosSemana.clamp(0, m.objetivo),
            'habito_dia' => habitosDia.clamp(0, m.objetivo),
            'ia_dia' => iaUsos.clamp(0, m.objetivo),
            _ => m.progreso,
          };
          m.progreso = p;
          m.completada = p >= m.objetivo;
        }
      }

      actualizar(diarias);
      actualizar(semanales);

      await ref.update({
        'diarias': diarias.map((m) => m.toMap()).toList(),
        'semanales': semanales.map((m) => m.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('[MisionesService] Error actualizarProgreso: $e');
    }
  }

  /// Reclama la recompensa de una misión completada.
  /// Retorna el nuevo nivel si subió de nivel, null si no.
  static Future<int?> reclamarRecompensa({
    required String misionId,
    required bool esSemanal,
    required int monedas,
    required int xp,
  }) async {
    final uid = _user?.uid;
    if (uid == null) return null;
    try {
      final ref = _db.collection('misiones').doc(uid);
      final doc = await ref.get();
      if (!doc.exists) return null;

      final key = esSemanal ? 'semanales' : 'diarias';
      final lista = (doc.data()![key] as List)
          .map((m) => Mision.fromMap(m as Map<String, dynamic>))
          .toList();

      final idx = lista.indexWhere((m) => m.id == misionId);
      if (idx < 0 || !lista[idx].completada || lista[idx].reclamada) return null;
      lista[idx].reclamada = true;

      await Future.wait([
        ref.update({key: lista.map((m) => m.toMap()).toList()}),
        MonedasService.agregar(monedas, 'mision_$misionId'),
      ]);

      return NivelesService.ganarXP(xp, 'mision_$misionId');
    } catch (e) {
      debugPrint('[MisionesService] Error reclamarRecompensa: $e');
      return null;
    }
  }

  /// Obtiene las misiones actuales del usuario (sin actualizar progreso).
  static Future<(List<Mision>, List<Mision>)> obtenerMisiones() async {
    final uid = _user?.uid;
    if (uid == null) return (<Mision>[], <Mision>[]);
    try {
      final doc = await _db.collection('misiones').doc(uid).get();
      if (!doc.exists) return (<Mision>[], <Mision>[]);
      final data = doc.data()!;
      final diarias = (data['diarias'] as List? ?? [])
          .map((m) => Mision.fromMap(m as Map<String, dynamic>))
          .toList();
      final semanales = (data['semanales'] as List? ?? [])
          .map((m) => Mision.fromMap(m as Map<String, dynamic>))
          .toList();
      return (diarias, semanales);
    } catch (e) {
      debugPrint('[MisionesService] Error obtenerMisiones: $e');
      return (<Mision>[], <Mision>[]);
    }
  }
}
