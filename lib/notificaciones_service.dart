import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'services/idioma_service.dart';

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
        IdiomaService.t('⏰ Hora de tu habito!', '⏰ Time for your habit!'),
        IdiomaService.t('Es momento de: $nombre', 'Time for: $nombre'),
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
          IdiomaService.t('📚 Hoy es tu examen!', '📚 Your exam is today!'),
          IdiomaService.t('Tu examen de $curso empieza hoy. Mucho exito!', 'Your $curso exam starts today. Good luck!'),
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
          IdiomaService.t('⚠️ Examen en 2 dias!', '⚠️ Exam in 2 days!'),
          IdiomaService.t('Tu examen de $curso es pasado manana. Estudia hoy!', 'Your $curso exam is the day after tomorrow. Study today!'),
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
          IdiomaService.t('🚨 Examen manana!', '🚨 Exam tomorrow!'),
          IdiomaService.t('Tu examen de $curso es manana. Repasa bien hoy!', 'Your $curso exam is tomorrow. Review well today!'),
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
          titulo = IdiomaService.t('🎯 ¡Hoy es tu examen de $curso!', '🎯 Today is your $curso exam!');
          cuerpo = IdiomaService.t('Ya es el día. Repasa tus notas rápidas y confía en ti.', "It's the day. Review your quick notes and trust yourself.");
        } else if (diasRestantes == 1) {
          titulo = IdiomaService.t('📖 Mañana: $curso', '📖 Tomorrow: $curso');
          cuerpo = IdiomaService.t('Haz un repaso final esta noche. ¡Tú puedes!', 'Do a final review tonight. You got this!');
        } else {
          titulo = IdiomaService.t('📚 Estudia $curso hoy', '📚 Study $curso today');
          cuerpo = IdiomaService.t('Faltan $diasRestantes días. Un repaso ahora vale mucho.', '$diasRestantes days left. A review now goes a long way.');
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
          IdiomaService.t('☀️ Buenos días — Examen de $curso en $diasRestantes días', '☀️ Good morning — $curso exam in $diasRestantes days'),
          IdiomaService.t('Empieza temprano: estudia al menos 30 minutos hoy.', 'Start early: study at least 30 minutes today.'),
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
          IdiomaService.t('🔥 ¡No pierdas tu racha de $racha días!', '🔥 Don\'t lose your $racha-day streak!'),
          IdiomaService.t('Completa aunque sea una actividad hoy para mantener la racha.', 'Complete at least one activity today to keep your streak.'),
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
          IdiomaService.t('📚 Hora de estudiar', '📚 Time to study'),
          IdiomaService.t('Mantén el hábito: 20 minutos al día hacen la diferencia.', 'Keep the habit: 20 minutes a day makes a difference.'),
          hoy7pm,
          NotificationDetails(android: _androidInteligente),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  // ── Recordatorio diario de misiones ───────────────────────────────────────
  // ID 89000 reservado para este canal.

  static const _androidMisiones = AndroidNotificationDetails(
    'misiones_canal',
    'Misiones del día',
    channelDescription: 'Recordatorio diario de misiones pendientes a las 8 AM',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
  );

  /// Programa (o reprograma) el recordatorio diario de misiones a las 8 AM.
  /// [pendientes] es el número de misiones diarias sin reclamar hoy.
  static Future<void> programarRecordatorioMisiones(int pendientes) async {
    await _plugin.cancel(89000);
    final cuerpo = pendientes > 0
        ? IdiomaService.t(
            'Tienes $pendientes ${pendientes == 1 ? 'misión' : 'misiones'} pendientes. ¡Gana monedas y XP!',
            'You have $pendientes ${pendientes == 1 ? 'mission' : 'missions'} pending. Earn coins and XP!',
          )
        : IdiomaService.t(
            '¡Completa tus misiones diarias y gana monedas y XP!',
            'Complete your daily missions and earn coins and XP!',
          );

    final ahora = tz.TZDateTime.now(tz.local);
    var prox8am =
        tz.TZDateTime(tz.local, ahora.year, ahora.month, ahora.day, 8, 0);
    if (prox8am.isBefore(ahora)) {
      prox8am = prox8am.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      89000,
      IdiomaService.t('🎯 Misiones del día', '🎯 Daily missions'),
      cuerpo,
      prox8am,
      NotificationDetails(android: _androidMisiones),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}