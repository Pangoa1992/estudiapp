import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'racha_service.dart';
import 'services/monedas_service.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});
  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  static const int _tiempoEstudio = 25 * 60;
  static const int _tiempoDescanso = 5 * 60;

  int _segundosRestantes = _tiempoEstudio;
  bool _corriendo = false;
  bool _esDescanso = false;
  int _sesionesCompletadas = 0;
  Timer? _timer;

  static const _kFechaKey = 'pomodoro_fecha';
  static const _kSesionesKey = 'pomodoro_sesiones';

  @override
  void initState() {
    super.initState();
    _cargarSesionesHoy();
  }

  String _fechaHoy() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _cargarSesionesHoy() async {
    final prefs = await SharedPreferences.getInstance();
    final fechaGuardada = prefs.getString(_kFechaKey);
    if (fechaGuardada == _fechaHoy()) {
      if (mounted) {
        setState(() {
          _sesionesCompletadas = prefs.getInt(_kSesionesKey) ?? 0;
        });
      }
    } else {
      // Nuevo día: reiniciar el contador guardado
      await prefs.remove(_kFechaKey);
      await prefs.remove(_kSesionesKey);
    }
  }

  Future<void> _guardarSesionesHoy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFechaKey, _fechaHoy());
    await prefs.setInt(_kSesionesKey, _sesionesCompletadas);
  }

  void _guardarSesionFirestore() {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final ahora = DateTime.now();
    FirebaseFirestore.instance.collection('sesiones_pomodoro').add({
      'userId': u.uid,
      'minutos': _tiempoEstudio ~/ 60,
      'fechaStr': _fechaHoy(),
      'fecha': Timestamp.fromDate(ahora),
    });
  }

  void _iniciarPausar() {
    if (_corriendo) {
      _timer?.cancel();
      setState(() => _corriendo = false);
    } else {
      setState(() => _corriendo = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        if (_segundosRestantes > 0) {
          setState(() => _segundosRestantes--);
        } else {
          t.cancel();
          if (!mounted) return;
          setState(() {
            _corriendo = false;
            if (!_esDescanso) {
              _sesionesCompletadas++;
              _guardarSesionesHoy();
              _guardarSesionFirestore();
              MonedasService.agregar(MonedasService.porPomodoro, 'pomodoro');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🪙 +10 monedas por completar sesión'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Color(0xFF2A2A3E),
                  ),
                );
              }
              // Primera sesión del día: garantiza que la racha se registre
              if (_sesionesCompletadas == 1) {
                RachaService().verificarRacha();
                final pomUser = FirebaseAuth.instance.currentUser;
                if (pomUser != null) {
                  FirebaseFirestore.instance.collection('logros').doc(pomUser.uid).set(
                    {'obtenidos': FieldValue.arrayUnion(['pomodoro_1'])},
                    SetOptions(merge: true),
                  );
                }
              }
              _esDescanso = true;
              _segundosRestantes = _tiempoDescanso;
            } else {
              _esDescanso = false;
              _segundosRestantes = _tiempoEstudio;
            }
          });
        }
      });
    }
  }

  void _reiniciar() {
    _timer?.cancel();
    setState(() {
      _corriendo = false;
      _esDescanso = false;
      _segundosRestantes = _tiempoEstudio;
    });
  }

  String get _tiempoFormato {
    final m = (_segundosRestantes ~/ 60).toString().padLeft(2, '0');
    final s = (_segundosRestantes % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progreso {
    final total = _esDescanso ? _tiempoDescanso : _tiempoEstudio;
    return 1 - (_segundosRestantes / total);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _esDescanso ? const Color(0xFF5DE0C5) : const Color(0xFF7C6AF7);
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        title: const Text('Pomodoro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _esDescanso ? '☕ Tiempo de descanso' : '📚 Tiempo de estudio',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 40),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220, height: 220,
                  child: CircularProgressIndicator(
                    value: _progreso,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xFF2E2E3E),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text(
                  _tiempoFormato,
                  style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _reiniciar,
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2E2E3E)),
                    ),
                    child: const Icon(Icons.refresh, color: Colors.white54, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _iniciarPausar,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
                    child: Icon(
                      _corriendo ? Icons.pause : Icons.play_arrow,
                      color: Colors.white, size: 36,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2E2E3E)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      Text('$_sesionesCompletadas', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('sesiones hoy', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}