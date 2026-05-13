import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const _calendarScope = 'https://www.googleapis.com/auth/calendar.events';

class CalendarSyncService {
  static final _signIn = GoogleSignIn(scopes: [_calendarScope]);

  static Future<String?> _obtenerToken() async {
    try {
      // Reutiliza sesión activa sin mostrar pantalla de login
      GoogleSignInAccount? cuenta = await _signIn.signInSilently();
      // Si no hay sesión previa, muestra el selector de cuenta
      cuenta ??= await _signIn.signIn();
      if (cuenta == null) return null;

      // Solicita el scope de Calendar si aún no fue concedido
      final scopeOk = await _signIn.requestScopes([_calendarScope]);
      if (!scopeOk) return null;

      final auth = await cuenta.authentication;
      return auth.accessToken;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> exportarExamen({
    required String curso,
    required DateTime fecha,
    String hora = '',
    String notas = '',
  }) async {
    final token = await _obtenerToken();
    if (token == null) return false;

    final inicio = _parsearHora(fecha, hora);
    final fin = inicio.add(const Duration(hours: 2));

    final evento = {
      'summary': 'Examen: $curso',
      'description':
          notas.isNotEmpty ? notas : 'Examen registrado en EstudiApp',
      'start': {
        'dateTime': inicio.toUtc().toIso8601String(),
        'timeZone': 'America/Lima',
      },
      'end': {
        'dateTime': fin.toUtc().toIso8601String(),
        'timeZone': 'America/Lima',
      },
      'reminders': {
        'useDefault': false,
        'overrides': [
          {'method': 'popup', 'minutes': 1440},
          {'method': 'popup', 'minutes': 60},
        ],
      },
    };

    try {
      final response = await http.post(
        Uri.parse(
            'https://www.googleapis.com/calendar/v3/calendars/primary/events'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(evento),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<int> exportarTodos(List<Map<String, dynamic>> examenes) async {
    int exportados = 0;
    for (final ex in examenes) {
      final fechaMs = ex['fecha'];
      if (fechaMs == null) continue;
      final fecha = DateTime.fromMillisecondsSinceEpoch(fechaMs as int);
      if (fecha.isBefore(DateTime.now())) continue;
      final ok = await exportarExamen(
        curso: ex['curso'] ?? '',
        fecha: fecha,
        hora: ex['hora'] ?? '',
        notas: ex['notas'] ?? '',
      );
      if (ok) exportados++;
    }
    return exportados;
  }

  static DateTime _parsearHora(DateTime fecha, String hora) {
    if (hora.isEmpty) return DateTime(fecha.year, fecha.month, fecha.day, 8, 0);
    try {
      final partes = hora.trim().split(' ');
      final tiempoPartes = partes[0].split(':');
      int h = int.parse(tiempoPartes[0]);
      final m = tiempoPartes.length > 1 ? int.parse(tiempoPartes[1]) : 0;
      final pm = partes.length > 1 && partes[1].toUpperCase() == 'PM';
      final am = partes.length > 1 && partes[1].toUpperCase() == 'AM';
      if (pm && h != 12) h += 12;
      if (am && h == 12) h = 0;
      return DateTime(fecha.year, fecha.month, fecha.day, h, m);
    } catch (_) {
      return DateTime(fecha.year, fecha.month, fecha.day, 8, 0);
    }
  }
}
