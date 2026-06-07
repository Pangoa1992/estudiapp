import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificacionesService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Lima'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  static const AndroidNotificationDetails _androidHabitos = AndroidNotificationDetails(
    'habitos_alarma_canal',
    'Alarmas de Habitos',
    channelDescription: 'Alarmas para recordatorios de habitos',
    importance: Importance.max,
    priority: Priority.max,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
  );

  static const AndroidNotificationDetails _androidExamenes = AndroidNotificationDetails(
    'examenes_alarma_canal',
    'Alarmas de Examenes',
    channelDescription: 'Alarmas para examenes proximos',
    importance: Importance.max,
    priority: Priority.max,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
  );

  static Future<void> programarNotificacionHabito({
    required int id,
    required String nombre,
    required String hora,
  }) async {
    try {
      String horaLimpia = hora.toUpperCase().trim();
      final espm = horaLimpia.contains('PM');
      final esam = horaLimpia.contains('AM');
      horaLimpia = horaLimpia.replaceAll('AM', '').replaceAll('PM', '').trim();
      final partes = horaLimpia.split(':');
      if (partes.length < 2) return;
      int horas = int.tryParse(partes[0].trim()) ?? 0;
      final minutos = int.tryParse(partes[1].trim()) ?? 0;
      if (espm && horas != 12) horas += 12;
      if (esam && horas == 12) horas = 0;

      final ahora = tz.TZDateTime.now(tz.local);
      var programado = tz.TZDateTime(
          tz.local, ahora.year, ahora.month, ahora.day, horas, minutos);
      if (programado.isBefore(ahora)) {
        programado = programado.add(const Duration(days: 1));
      }

      await _plugin.cancel(id);

      await _plugin.zonedSchedule(
        id,
        '⏰ Hora de tu habito!',
        'Es momento de: $nombre',
        programado,
        NotificationDetails(android: _androidHabitos),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      return;
    }
  }

  // Reserva espacios de ID separados para evitar colisiones entre exámenes:
  // - Notificación el mismo día: id % 30000           (rango 0–29999)
  // - 2 días antes:             id % 30000 + 30000    (rango 30000–59999)
  // - 1 día antes:              id % 30000 + 60000    (rango 60000–89999)
  static int _baseId(int id) => id.abs() % 30000;

  static Future<void> programarNotificacionesExamen({
    required int id,
    required String curso,
    required DateTime fecha,
    required String hora,
  }) async {
    try {
      String horaLimpia = hora.toUpperCase().trim();
      final espm = horaLimpia.contains('PM');
      final esam = horaLimpia.contains('AM');
      horaLimpia = horaLimpia.replaceAll('AM', '').replaceAll('PM', '').trim();
      final partes = horaLimpia.split(':');
      int horasExamen = partes.length >= 2 ? int.tryParse(partes[0].trim()) ?? 8 : 8;
      final minutosExamen = partes.length >= 2 ? int.tryParse(partes[1].trim()) ?? 0 : 0;
      if (espm && horasExamen != 12) horasExamen += 12;
      if (esam && horasExamen == 12) horasExamen = 0;

      final ahora = tz.TZDateTime.now(tz.local);
      final base = _baseId(id);

      // Notificacion el mismo dia
      final mismodia = tz.TZDateTime(
        tz.local, fecha.year, fecha.month, fecha.day, horasExamen, minutosExamen,
      );
      if (mismodia.isAfter(ahora)) {
        await _plugin.cancel(base);
        await _plugin.zonedSchedule(
          base,
          '📚 Hoy es tu examen!',
          'Tu examen de $curso empieza hoy. Mucho exito!',
          mismodia,
          NotificationDetails(android: _androidExamenes),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
        );
      }

      // Notificacion 2 dias antes a las 8 AM
      final dosAntes = tz.TZDateTime(
        tz.local,
        fecha.subtract(const Duration(days: 2)).year,
        fecha.subtract(const Duration(days: 2)).month,
        fecha.subtract(const Duration(days: 2)).day,
        8, 0,
      );
      if (dosAntes.isAfter(ahora)) {
        await _plugin.cancel(base + 30000);
        await _plugin.zonedSchedule(
          base + 30000,
          '⚠️ Examen en 2 dias!',
          'Tu examen de $curso es pasado manana. Estudia hoy!',
          dosAntes,
          NotificationDetails(android: _androidExamenes),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
        );
      }

      // Notificacion 1 dia antes a las 8 AM
      final unAntes = tz.TZDateTime(
        tz.local,
        fecha.subtract(const Duration(days: 1)).year,
        fecha.subtract(const Duration(days: 1)).month,
        fecha.subtract(const Duration(days: 1)).day,
        8, 0,
      );
      if (unAntes.isAfter(ahora)) {
        await _plugin.cancel(base + 60000);
        await _plugin.zonedSchedule(
          base + 60000,
          '🚨 Examen manana!',
          'Tu examen de $curso es manana. Repasa bien hoy!',
          unAntes,
          NotificationDetails(android: _androidExamenes),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
        );
      }
    } catch (e) {
      return;
    }
  }

  static Future<void> programarAlertaExamen({
    required int id,
    required String curso,
    required DateTime fecha,
  }) async {
    await programarNotificacionesExamen(
      id: id,
      curso: curso,
      fecha: fecha,
      hora: '08:00',
    );
  }

  static Future<void> cancelarNotificacion(int id) async {
    final base = _baseId(id);
    await _plugin.cancel(base);
    await _plugin.cancel(base + 30000);
    await _plugin.cancel(base + 60000);
  }

  static Future<void> cancelarTodas() async {
    await _plugin.cancelAll();
  }

  // ── Notificaciones Inteligentes ────────────────────────────────────────────
  // IDs 90000-99999 reservados para este bloque.

  static const _androidInteligente = AndroidNotificationDetails(
    'estudio_inteligente_canal',
    'Estudio Inteligente',
    channelDescription: 'Recordatorios personalizados de estudio',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
  );

  /// Programa recordatorios inteligentes basados en exámenes próximos y racha.
  /// Cancela los anteriores antes de reprogramar.
  static Future<void> programarNotificacionesInteligentes({
    required List<Map<String, dynamic>> examenes,
    required int racha,
  }) async {
    // Limpiar bloque inteligente anterior
    for (int i = 90000; i < 90020; i++) {
      await _plugin.cancel(i);
    }

    final ahora = tz.TZDateTime.now(tz.local);
    int idBase = 90000;

    // 1. Por cada examen próximo (≤ 7 días) programa recordatorios de estudio
    for (final examen in examenes) {
      final fechaRaw = examen['fecha'];
      if (fechaRaw == null) continue;
      DateTime fecha;
      if (fechaRaw is DateTime) {
        fecha = fechaRaw;
      } else {
        continue;
      }

      final diasRestantes =
          DateTime(fecha.year, fecha.month, fecha.day)
              .difference(DateTime(ahora.year, ahora.month, ahora.day))
              .inDays;
      if (diasRestantes < 0 || diasRestantes > 7) continue;

      final curso = examen['curso'] as String? ?? 'tu examen';

      // Recordatorio de estudio nocturno: hoy a las 8 PM
      final hoy8pm = tz.TZDateTime(tz.local, ahora.year, ahora.month, ahora.day, 20, 0);
      if (hoy8pm.isAfter(ahora) && idBase < 90010) {
        String titulo;
        String cuerpo;
        if (diasRestantes == 0) {
          titulo = '🎯 ¡Hoy es tu examen de $curso!';
          cuerpo = 'Ya es el día. Repasa tus notas rápidas y confía en ti.';
        } else if (diasRestantes == 1) {
          titulo = '📖 Mañana: $curso';
          cuerpo = 'Haz un repaso final esta noche. ¡Tú puedes!';
        } else {
          titulo = '📚 Estudia $curso hoy';
          cuerpo = 'Faltan $diasRestantes días. Un repaso ahora vale mucho.';
        }
        await _plugin.zonedSchedule(
          idBase,
          titulo,
          cuerpo,
          hoy8pm,
          NotificationDetails(android: _androidInteligente),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        idBase++;
      }

      // Recordatorio matutino mañana a las 9 AM (si faltan ≥ 2 días)
      if (diasRestantes >= 2 && idBase < 90010) {
        final manana9am = tz.TZDateTime(
            tz.local, ahora.year, ahora.month, ahora.day, 9, 0)
            .add(const Duration(days: 1));
        await _plugin.zonedSchedule(
          idBase,
          '☀️ Buenos días — Examen de $curso en $diasRestantes días',
          'Empieza temprano: estudia al menos 30 minutos hoy.',
          manana9am,
          NotificationDetails(android: _androidInteligente),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        idBase++;
      }
    }

    // 2. Recordatorio de racha: si lleva ≥ 3 días, avisa a las 9 PM
    if (racha >= 3) {
      final hoy9pm = tz.TZDateTime(tz.local, ahora.year, ahora.month, ahora.day, 21, 0);
      if (hoy9pm.isAfter(ahora) && idBase < 90020) {
        await _plugin.zonedSchedule(
          idBase,
          '🔥 ¡No pierdas tu racha de $racha días!',
          'Completa aunque sea una actividad hoy para mantener la racha.',
          hoy9pm,
          NotificationDetails(android: _androidInteligente),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        idBase++;
      }
    }

    // 3. Si no hay exámenes próximos, recordatorio genérico a las 7 PM
    if (examenes.isEmpty && idBase == 90000) {
      final hoy7pm = tz.TZDateTime(tz.local, ahora.year, ahora.month, ahora.day, 19, 0);
      if (hoy7pm.isAfter(ahora)) {
        await _plugin.zonedSchedule(
          90000,
          '📚 Hora de estudiar',
          'Mantén el hábito: 20 minutos al día hacen la diferencia.',
          hoy7pm,
          NotificationDetails(android: _androidInteligente),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }
}