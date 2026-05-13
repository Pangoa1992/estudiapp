import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'tutorial_page.dart';
import 'racha_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _cargando = false;

  Future<void> _loginConGoogle() async {
    setState(() => _cargando = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _cargando = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Verificar si es usuario nuevo
      final isNuevo = userCredential.additionalUserInfo?.isNewUser ?? false;
      
      // Actualizar racha
      await RachaService().verificarRacha();
      
      if (mounted) {
        if (isNuevo) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TutorialPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Text('🎓', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              const Text(
                'EstudiApp',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Organiza tus examenes,\ncumple tus habitos y no reprobes',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16, height: 1.5),
              ),
              const Spacer(),
              const Row(
                children: [
                  Expanded(child: _FeatureItem(icono: '🔥', texto: 'Racha diaria')),
                  Expanded(child: _FeatureItem(icono: '📚', texto: 'Tus cursos')),
                  Expanded(child: _FeatureItem(icono: '⏱', texto: 'Pomodoro')),
                ],
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _cargando ? null : _loginConGoogle,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: _cargando
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C6AF7)))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4285F4))),
                            SizedBox(width: 10),
                            Text('Continuar con Google', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Gratis para siempre · Sin tarjeta requerida', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String icono;
  final String texto;
  const _FeatureItem({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2E2E3E)),
          ),
          child: Center(child: Text(icono, style: const TextStyle(fontSize: 24))),
        ),
        const SizedBox(height: 8),
        Text(texto, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}