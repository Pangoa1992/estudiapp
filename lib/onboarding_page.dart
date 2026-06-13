import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'notificaciones_service.dart';
import 'l10n_helper.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _paginaActual = 0;

  List<Map<String, dynamic>> _paginas(AppLocalizations l10n) => [
    {
      'emoji': '🔥',
      'titulo': l10n.onb1Title,
      'subtitulo': l10n.onb1Sub,
      'color1': const Color(0xFF2A1F5E),
      'color2': const Color(0xFF1F3A35),
      'colorAccent': const Color(0xFF7C6AF7),
    },
    {
      'emoji': '🤖',
      'titulo': l10n.onb2Title,
      'subtitulo': l10n.onb2Sub,
      'color1': const Color(0xFF1A2A1F),
      'color2': const Color(0xFF1F2A3A),
      'colorAccent': const Color(0xFF5DE0C5),
    },
    {
      'emoji': '📚',
      'titulo': l10n.onb3Title,
      'subtitulo': l10n.onb3Sub,
      'color1': const Color(0xFF2A1A1F),
      'color2': const Color(0xFF1F1A2A),
      'colorAccent': const Color(0xFFF7A26A),
    },
    {
      'emoji': '🔔',
      'titulo': l10n.onb4Title,
      'subtitulo': l10n.onb4Sub,
      'color1': const Color(0xFF1A2030),
      'color2': const Color(0xFF0F1520),
      'colorAccent': const Color(0xFF5DE0C5),
    },
  ];

  Future<void> _terminarOnboarding() async {
    await NotificacionesService.inicializar();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completado', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final paginas = _paginas(l10n);
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: paginas.length,
            onPageChanged: (i) => setState(() => _paginaActual = i),
            itemBuilder: (context, i) {
              final p = paginas[i];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [p['color1'] as Color, p['color2'] as Color, const Color(0xFF0F0F14)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: (p['colorAccent'] as Color).withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: (p['colorAccent'] as Color).withOpacity(0.3), width: 2),
                          ),
                          child: Center(
                            child: Text(p['emoji'] as String, style: const TextStyle(fontSize: 56)),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          p['titulo'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          p['subtitulo'] as String,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 16,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 48),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(paginas.length, (i) {
                      final isActive = i == _paginaActual;
                      final color = paginas[_paginaActual]['colorAccent'] as Color;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? color : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_paginaActual < paginas.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _terminarOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: paginas[_paginaActual]['colorAccent'] as Color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _paginaActual < paginas.length - 1 ? l10n.next : l10n.getStarted,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  if (_paginaActual < paginas.length - 1) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _terminarOnboarding,
                      child: Text(
                        l10n.skip,
                        style: const TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
