import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'services/idioma_service.dart';

class ServicioNotificaciones {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    // Inicializar zonas horarias
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // Pedir permisos en Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> mostrarNotificacion({
    required int id,
    required String titulo,
    required String cuerpo,
  }) async {
    const detallesAndroid = AndroidNotificationDetails(
      'estudiapp_canal',
      'EstudiApp Notificaciones',
      channelDescription: 'Notificaciones de habitos y examenes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const detalles = NotificationDetails(android: detallesAndroid);
    await _plugin.show(id, titulo, cuerpo, detalles);
  }

  // ──────────────────────────────────────────────
  //  3 RECORDATORIOS DIARIOS AUTOMÁTICOS
  //  ID 97 → 8:00 AM  (mañana)
  //  ID 98 → 2:00 PM  (tarde)
  //  ID 99 → 8:00 PM  (noche)
  // ──────────────────────────────────────────────
  static Future<void> programarRecordatorioDiario(int rachaActual) async {
    // Cancelar recordatorios anteriores
    await _plugin.cancel(97);
    await _plugin.cancel(98);
    await _plugin.cancel(99);

    const detallesAndroid = AndroidNotificationDetails(
      'estudiapp_racha',
      'Recordatorio diario',
      channelDescription: 'Recordatorio para no perder la racha',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const detalles = NotificationDetails(android: detallesAndroid);

    final peru = tz.getLocation('America/Lima');
    final ahora = tz.TZDateTime.now(peru);

    // Definir los 3 horarios con su mensaje
    final recordatorios = [
      {
        'id': 97,
        'hora': 8,
        'minuto': 0,
        'titulo': IdiomaService.t('☀️ ¡Buenos días!', '☀️ Good morning!'),
        'cuerpo': rachaActual > 0
            ? IdiomaService.t(
                'Llevas $rachaActual días de racha. ¡Hoy también puedes!',
                'You\'re on a $rachaActual-day streak. Keep it up today!')
            : IdiomaService.t(
                '¡Empieza bien el día! Abre EstudiApp y cumple tus hábitos.',
                'Start your day right! Open EstudiApp and complete your habits.'),
      },
      {
        'id': 98,
        'hora': 14,
        'minuto': 0,
        'titulo': IdiomaService.t('📖 ¡Hora de estudiar!', '📖 Time to study!'),
        'cuerpo': rachaActual > 0
            ? IdiomaService.t(
                '¿Ya entraste hoy? No pierdas tu racha de $rachaActual días.',
                'Checked in today? Don\'t lose your $rachaActual-day streak.')
            : IdiomaService.t(
                '¡La tarde es perfecta para estudiar! Abre la app.',
                'Afternoon is perfect for studying! Open the app.'),
      },
      {
        'id': 99,
        'hora': 20,
        'minuto': 0,
        'titulo': IdiomaService.t('🔥 ¡Última oportunidad!', '🔥 Last chance!'),
        'cuerpo': rachaActual > 0
            ? IdiomaService.t(
                'Son las 8 PM. Llevas $rachaActual días seguidos, ¡no la pierdas!',
                'It\'s 8 PM. You\'re on a $rachaActual-day streak — don\'t break it!')
            : IdiomaService.t(
                '¡Todavía estás a tiempo! Entra y comienza tu racha hoy.',
                'Still time! Open the app and start your streak today.'),
      },
    ];

    for (final r in recordatorios) {
      var proximaVez = tz.TZDateTime(
          peru, ahora.year, ahora.month, ahora.day, r['hora'] as int, r['minuto'] as int);

      // Si esa hora ya pasó hoy, programar para mañana
      if (proximaVez.isBefore(ahora)) {
        proximaVez = proximaVez.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        r['id'] as int,
        r['titulo'] as String,
        r['cuerpo'] as String,
        proximaVez,
        detalles,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: DateTimeComponents.time, // Repite cada día
      );
    }
  }

  static Future<void> cancelarRecordatorioDiario() async {
    await _plugin.cancel(97);
    await _plugin.cancel(98);
    await _plugin.cancel(99);
  }

  // ──────────────────────────────────────────────
  //  NOTIFICACIONES MANUALES (ya existían)
  // ──────────────────────────────────────────────
  static Future<void> notificarHabito(String nombreHabito, String hora) async {
    await mostrarNotificacion(
      id: 1,
      titulo: '⏰ ¡Hora de tu hábito!',
      cuerpo: 'Es momento de: $nombreHabito a las $hora',
    );
  }

  static Future<void> notificarExamen(String curso, int diasRestantes) async {
    await mostrarNotificacion(
      id: 2,
      titulo: '📚 ¡Examen próximo!',
      cuerpo: diasRestantes == 1
          ? 'Mañana es tu examen de $curso. ¡Estudia hoy!'
          : 'Tu examen de $curso es en $diasRestantes días. ¡Prepárate!',
    );
  }

  static Future<void> notificarRacha(int dias) async {
    await mostrarNotificacion(
      id: 3,
      titulo: '🔥 ¡No pierdas tu racha!',
      cuerpo: 'Llevas $dias días seguidos. ¡Completa tus hábitos hoy!',
    );
  }
}

// ──────────────────────────────────────────────
//  PANTALLA DE NOTIFICACIONES (sin cambios de UI)
// ──────────────────────────────────────────────
class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({super.key});

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones> {
  final user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        title: const Text('Notificaciones',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── BANNER recordatorio diario ──
            StreamBuilder<DocumentSnapshot>(
              stream: _db.collection('perfiles').doc(user!.uid).snapshots(),
              builder: (context, snapshot) {
                final racha = snapshot.data?.get('racha') ?? 0;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF2A1F5E), Color(0xFF1F3A35)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3D2FA0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🔔 Recordatorio diario activo',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Te recordaremos 3 veces al día (8 AM, 2 PM y 8 PM) para que no pierdas tu racha de $racha días.',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C6AF7),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.alarm_on,
                            size: 16, color: Colors.white),
                        label: const Text('Activar recordatorio',
                            style: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          await ServicioNotificaciones
                              .programarRecordatorioDiario(racha);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    '✅ Recordatorio activado para las 8:00 PM diario'),
                                backgroundColor: Color(0xFF5DE0C5),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── HÁBITOS ──
            const Text('Mis hábitos',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('habitos')
                  .where('userId', isEqualTo: user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('No tienes hábitos aún',
                        style: TextStyle(color: Colors.white38)),
                  );
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _botonNotificacion(
                      icono: Icons.alarm,
                      titulo: data['nombre'] ?? '',
                      subtitulo: 'Hora: ${data['hora'] ?? 'No definida'}',
                      color: const Color(0xFF7C6AF7),
                      onTap: () => ServicioNotificaciones.notificarHabito(
                        data['nombre'] ?? '',
                        data['hora'] ?? '',
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── EXÁMENES ──
            const Text('Mis exámenes próximos',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('examenes')
                  .where('userId', isEqualTo: user!.uid)
                  .orderBy('fecha')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('No tienes exámenes aún',
                        style: TextStyle(color: Colors.white38)),
                  );
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final fecha = (data['fecha'] as Timestamp).toDate();
                    final dias = fecha.difference(DateTime.now()).inDays;
                    final color = dias <= 1
                        ? const Color(0xFFF7584A)
                        : dias <= 4
                            ? const Color(0xFFF7A26A)
                            : const Color(0xFF5DE0C5);
                    return _botonNotificacion(
                      icono: Icons.school,
                      titulo: data['curso'] ?? '',
                      subtitulo:
                          dias <= 0 ? '¡Examen hoy!' : 'Faltan $dias día${dias > 1 ? 's' : ''}',
                      color: color,
                      onTap: () => ServicioNotificaciones.notificarExamen(
                        data['curso'] ?? '',
                        dias,
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── RACHA ──
            const Text('Racha',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot>(
              stream: _db.collection('perfiles').doc(user!.uid).snapshots(),
              builder: (context, snapshot) {
                final racha = snapshot.data?.get('racha') ?? 0;
                return _botonNotificacion(
                  icono: Icons.local_fire_department,
                  titulo: 'Alerta de racha',
                  subtitulo: 'Llevas $racha días de racha',
                  color: const Color(0xFFF7584A),
                  onTap: () => ServicioNotificaciones.notificarRacha(racha),
                );
              },
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2E2E3E)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cómo funcionan las notificaciones',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text(
                    '• Recordatorios automáticos a las 8 AM, 2 PM y 8 PM cada día\n'
                    '• Toca cualquier hábito para recibir una notificación de prueba\n'
                    '• Toca un examen para recibir alerta de días restantes',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 13, height: 1.7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonNotificacion({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(subtitulo,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.notifications_active, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}