import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'firebase_options.dart';
import 'cursos_page.dart';
import 'pomodoro_page.dart';
import 'notificaciones.dart';
import 'notificaciones_service.dart';
import 'login_page.dart';
import 'ia_page.dart';
import 'habitos_page.dart';
import 'examenes_page.dart';
import 'perfil_page.dart';
import 'racha_service.dart';
import 'dashboard_page.dart';
import 'onboarding_page.dart';
import 'logros_page.dart';
import 'sin_conexion_page.dart';
import 'admin_page.dart';
import 'racha_heatmap_page.dart';
import 'tema_service.dart';
import 'cache_service.dart';
import 'widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Caché offline Firestore — 50 MB
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 52428800,
  );

  // Inicializar servicios en paralelo para reducir el tiempo de arranque
  await Future.wait([
    ServicioNotificaciones.inicializar(),
    TemaService.cargar(),
    CacheService.inicializar(),
  ]);
  unawaited(MobileAds.instance.initialize());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData get _lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F0F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C6AF7),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF0F0F8),
          foregroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
        ),
        cardColor: Colors.white,
        useMaterial3: false,
      );

  ThemeData get _darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F14),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C6AF7),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F14),
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        useMaterial3: false,
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: TemaService.modoNotifier,
      builder: (context, modo, _) {
        return MaterialApp(
          title: 'EstudiApp',
          debugShowCheckedModeBanner: false,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: modo,
          home: _paginaInicial(),
        );
      },
    );
  }

  Widget _paginaInicial() {
    return SinConexionPage(
      child: FutureBuilder<bool>(
        future: SharedPreferences.getInstance()
            .then((p) => p.getBool('onboarding_completado') ?? false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F0F14),
              body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF7C6AF7))),
            );
          }
          // Onboarding no completado → mostrar onboarding primero
          if (snapshot.data != true) return const OnboardingPage();
          // Usar el stream de Auth para evitar la condición de carrera en Android
          // donde currentUser puede ser null brevemente al arrancar la app
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnap) {
              if (authSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF0F0F14),
                  body: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF7C6AF7))),
                );
              }
              return authSnap.data != null
                  ? const HomePage()
                  : const LoginPage();
            },
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;
  BannerAd? _bannerAd;
  bool _bannerAdReady = false;
  int _rachaWidget = 0;
  List<String> _habitosWidget = [];

  @override
  void initState() {
    super.initState();
    RachaService().verificarRacha();
    _activarRecordatorios();
    WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarAvisoBateria());
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-6530298594670805/7501861973',
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _bannerAdReady = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAdReady = false;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _mostrarAvisoBateria() async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getBool('aviso_bateria_visto') ?? false) || !mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Text('🔔', style: TextStyle(fontSize: 24)),
          SizedBox(width: 8),
          Text('Activa las notificaciones',
              style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: const Text(
          'Para recibir recordatorios desactiva la optimización de batería para EstudiApp.\n\n'
          'Ajustes → Apps → EstudiApp → Desactiva "Pausar actividades no utilizadas"',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.setBool('aviso_bateria_visto', true);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Ahora no', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C6AF7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await prefs.setBool('aviso_bateria_visto', true);
              if (context.mounted) Navigator.pop(context);
              if (Platform.isAndroid) {
                const AndroidIntent(
                  action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
                  data: 'package:com.willy.estudiapp',
                ).launch();
              }
            },
            child: const Text('Ir a Ajustes',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _activarRecordatorios() async {
    try {
      if (user == null) return;
      await NotificacionesService.cancelarTodas();
      final doc = await _db.collection('perfiles').doc(user!.uid).get();
      final racha = doc.data()?['racha'] ?? 0;
      await ServicioNotificaciones.cancelarRecordatorioDiario();
      await ServicioNotificaciones.programarRecordatorioDiario(racha);

      final habitosSnap = await _db
          .collection('habitos')
          .where('userId', isEqualTo: user!.uid)
          .get();
      for (final h in habitosSnap.docs) {
        final data = h.data();
        final hora = data['hora'] as String? ?? '';
        if (hora.isNotEmpty) {
          await NotificacionesService.programarNotificacionHabito(
            id: h.id.hashCode.abs(),
            nombre: data['nombre'] ?? '',
            hora: hora,
          );
        }
      }

      final examenesSnap = await _db
          .collection('examenes')
          .where('userId', isEqualTo: user!.uid)
          .where('completado', isEqualTo: false)
          .get();
      for (final e in examenesSnap.docs) {
        final data = e.data();
        final fechaRaw = data['fecha'];
        if (fechaRaw == null) continue;
        final fecha = (fechaRaw as Timestamp).toDate();
        if (fecha.isAfter(DateTime.now())) {
          await NotificacionesService.programarAlertaExamen(
            id: e.id.hashCode.abs(),
            curso: data['curso'] ?? '',
            fecha: fecha,
          );
        }
      }
    } catch (e) {
      debugPrint('[HomePage] Error al activar recordatorios: $e');
    }
  }

  String get _nombreUsuario => (user?.displayName ?? 'Estudiante').split(' ').first;

  String get _saludo {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días,';
    if (h < 18) return 'Buenas tardes,';
    return 'Buenas noches,';
  }

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      bottomNavigationBar: _bannerAdReady
          ? SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildStreakBanner(),
              const SizedBox(height: 12),
              _buildRecordatorioInteligente(),
              _buildBotonIA(),
              const SizedBox(height: 24),
              _buildSeccionExamenes(),
              const SizedBox(height: 24),
              _buildSeccionHabitos(),
              const SizedBox(height: 16),
              _buildBotones(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_saludo,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            Text('$_nombreUsuario 👋',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const CursosPage())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF7C6AF7).withOpacity(0.5)),
                ),
                child: const Text('Mis cursos',
                    style: TextStyle(
                        color: Color(0xFF7C6AF7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const PerfilPage())),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF7C6AF7),
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Text(
                        _nombreUsuario.isNotEmpty
                            ? _nombreUsuario[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStreakBanner() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('perfiles').doc(user!.uid).snapshots(),
      builder: (context, snapshot) {
        final perfilData = snapshot.data?.data() as Map<String, dynamic>?;
        final racha = perfilData?['racha'] ?? 0;

        // Actualiza cache y widget con la racha fresca
        if (snapshot.hasData) {
          final rachaInt = (racha as num).toInt();
          CacheService.guardarRacha(
            rachaInt,
            ((perfilData?['rachaMaxima'] ?? 0) as num).toInt(),
          );
          if (_rachaWidget != rachaInt) {
            _rachaWidget = rachaInt;
            WidgetService.actualizar(racha: rachaInt, habitosHoy: _habitosWidget);
          }
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF2A1F5E), Color(0xFF1F3A35)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3D2FA0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Text('🔥', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$racha días de racha',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const Text('Sigue así, no la pierdas',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ]),
                  ]),
                  GestureDetector(
                    onTap: () => Share.share(
                        '🔥 ¡Llevo $racha días de racha estudiando con EstudiApp!\n'
                        '📚 Organiza tus hábitos, exámenes y estudia con IA.'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C6AF7).withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.share,
                          color: Color(0xFF7C6AF7), size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const PomodoroPage())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C6AF7), Color(0xFF5A4ED4)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Iniciar Pomodoro',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecordatorioInteligente() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('examenes')
          .where('userId', isEqualTo: user!.uid)
          .where('completado', isEqualTo: false)
          .orderBy('fecha')
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final hoyBase = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final proximos = snapshot.data!.docs.where((doc) {
          final fecha =
              ((doc.data() as Map)['fecha'] as Timestamp).toDate();
          final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
          final dias = soloFecha.difference(hoyBase).inDays;
          return dias >= 0 && dias <= 3;
        }).toList();
        if (proximos.isEmpty) return const SizedBox(height: 12);
        final data = proximos.first.data() as Map<String, dynamic>;
        final fecha = (data['fecha'] as Timestamp).toDate();
        final soloFechaExamen = DateTime(fecha.year, fecha.month, fecha.day);
        final dias = soloFechaExamen.difference(hoyBase).inDays;
        final urgente = dias == 0;
        return GestureDetector(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const IAPage())),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: urgente
                    ? [const Color(0xFF2A1010), const Color(0xFF1A1020)]
                    : [const Color(0xFF1A1A30), const Color(0xFF101A20)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: urgente
                    ? const Color(0xFFF7584A).withOpacity(0.6)
                    : const Color(0xFFF7A26A).withOpacity(0.5),
              ),
            ),
            child: Row(children: [
              Text(urgente ? '🚨' : '🎯',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dias == 0
                            ? '¡Hoy es tu examen de ${data['curso']}!'
                            : dias == 1
                                ? 'Mañana: examen de ${data['curso']}'
                                : 'Examen de ${data['curso']} en $dias días',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                      const Text('Toca para estudiar con IA →',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 11)),
                    ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildBotonIA() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const IAPage())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2A),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.5)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF7C6AF7), size: 20),
            SizedBox(width: 8),
            Text('Estudiar con IA',
                style: TextStyle(
                    color: Color(0xFF7C6AF7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionExamenes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('EXÁMENES PRÓXIMOS',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ExamenesPage())),
              child: const Text('Ver todos',
                  style: TextStyle(color: Color(0xFF7C6AF7), fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('examenes')
              .where('userId', isEqualTo: user!.uid)
              .where('completado', isEqualTo: false)
              .orderBy('fecha')
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ExamenesPage())),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF7C6AF7).withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Color(0xFF7C6AF7), size: 18),
                      SizedBox(width: 8),
                      Text('Agregar examen',
                          style: TextStyle(color: Color(0xFF7C6AF7))),
                    ],
                  ),
                ),
              );
            }
            return SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, i) {
                  final data =
                      snapshot.data!.docs[i].data() as Map<String, dynamic>;
                  final fecha = (data['fecha'] as Timestamp).toDate();
                  final hoy = DateTime(DateTime.now().year,
                      DateTime.now().month, DateTime.now().day);
                  final dias =
                      DateTime(fecha.year, fecha.month, fecha.day)
                          .difference(hoy)
                          .inDays;
                  final color = dias <= 1
                      ? const Color(0xFFF7584A)
                      : dias <= 4
                          ? const Color(0xFFF7A26A)
                          : const Color(0xFF5DE0C5);
                  return Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: color),
                        const SizedBox(height: 8),
                        Text(data['curso'],
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        Text('${fecha.day}/${fecha.month}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11)),
                        const Spacer(),
                        Text(
                          dias <= 0
                              ? 'Hoy'
                              : dias == 1
                                  ? 'Mañana'
                                  : '$dias días',
                          style: TextStyle(
                              color: color,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSeccionHabitos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('HÁBITOS DE HOY',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HabitosPage())),
              child: const Text('Ver todos',
                  style: TextStyle(color: Color(0xFF7C6AF7), fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('habitos')
              .where('userId', isEqualTo: user!.uid)
              .limit(4)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              if (_habitosWidget.isNotEmpty) {
                _habitosWidget = [];
                WidgetService.actualizar(racha: _rachaWidget, habitosHoy: []);
              }
              return GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HabitosPage())),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF7C6AF7).withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Color(0xFF7C6AF7), size: 18),
                      SizedBox(width: 8),
                      Text('Agregar hábito',
                          style: TextStyle(color: Color(0xFF7C6AF7))),
                    ],
                  ),
                ),
              );
            }
            // Actualizar widget con hábitos frescos
            final nombresHabitos = snapshot.data!.docs
                .map((d) => (d.data() as Map)['nombre'] as String? ?? '')
                .where((n) => n.isNotEmpty)
                .toList();
            if (_habitosWidget.join() != nombresHabitos.join()) {
              _habitosWidget = nombresHabitos;
              WidgetService.actualizar(racha: _rachaWidget, habitosHoy: nombresHabitos);
            }
            const iconos = [
              Icons.book, Icons.water_drop, Icons.directions_run,
              Icons.edit_note, Icons.bed, Icons.restaurant,
              Icons.music_note, Icons.self_improvement
            ];
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final idx = (data['icono'] as int? ?? 0).clamp(0, iconos.length - 1);
                return GestureDetector(
                  onTap: () => _db
                      .collection('habitos')
                      .doc(doc.id)
                      .update({'done': !(data['done'] ?? false)}),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: data['done'] == true
                          ? const Color(0xFF14201E)
                          : const Color(0xFF1E1E2A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: data['done'] == true
                            ? const Color(0xFF5DE0C5).withOpacity(0.5)
                            : const Color(0xFF2E2E3E),
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(iconos[idx],
                            color: const Color(0xFF7C6AF7), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['nombre'],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            Text(data['hora'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: data['done'] == true
                            ? const Color(0xFF5DE0C5)
                            : Colors.transparent,
                        child: data['done'] == true
                            ? const Icon(Icons.check,
                                size: 14, color: Color(0xFF0A1A17))
                            : Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24))),
                      ),
                    ]),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBotones() {
    return Column(children: [
      _btn(
        icon: Icons.local_fire_department,
        color: const Color(0xFFF7584A),
        label: 'Historial de racha 🔥',
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const RachaHeatmapPage())),
      ),
      const SizedBox(height: 8),
      _btn(
        icon: Icons.emoji_events,
        color: const Color(0xFFFFD700),
        label: 'Mis logros 🏆',
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const LogrosPage())),
      ),
      const SizedBox(height: 8),
      _btn(
        icon: Icons.dashboard,
        color: const Color(0xFFFFD700),
        label: 'Dashboard semanal',
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const DashboardPage())),
      ),
      const SizedBox(height: 8),
      _btn(
        icon: Icons.notifications,
        color: const Color(0xFF5DE0C5),
        label: 'Configurar notificaciones',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PantallaNotificaciones())),
      ),
      const SizedBox(height: 8),
      if (user?.email?.toLowerCase() == AdminPage.adminEmail) ...[
        _btn(
          icon: Icons.admin_panel_settings,
          color: Colors.orange,
          label: 'Panel Admin 👁️',
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AdminPage())),
        ),
        const SizedBox(height: 8),
      ],
      _btn(
        icon: Icons.logout,
        color: Colors.white38,
        label: 'Cerrar sesión',
        onTap: _cerrarSesion,
        borderColor: Colors.white12,
      ),
    ]);
  }

  Widget _btn({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor ?? color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
