import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'notificaciones_service.dart';
import 'services/carrera_service.dart';
import 'l10n_helper.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _paginaActual = 0;
  bool _mostrandoCarrera = false;
  String _carreraSeleccionada = '';

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
    if (_carreraSeleccionada.isNotEmpty) {
      await prefs.setString('carrera_onboarding', _carreraSeleccionada);
    }
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mostrandoCarrera) return _buildSeleccionCarrera();
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
                          // Último paso: selección de carrera
                          setState(() => _mostrandoCarrera = true);
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
                      onTap: () => setState(() => _mostrandoCarrera = true),
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

  Widget _buildSeleccionCarrera() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text('🎓', style: TextStyle(fontSize: 56)),
                  SizedBox(height: 20),
                  Text(
                    '¿Cuál es tu carrera?',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Personaliza la IA y el contenido\npara tu área de estudio.',
                    style: TextStyle(color: Colors.white60, fontSize: 15, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: CarreraService.lista.length,
                itemBuilder: (ctx, i) {
                  final c = CarreraService.lista[i];
                  final sel = c == _carreraSeleccionada;
                  return GestureDetector(
                    onTap: () => setState(() => _carreraSeleccionada = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF7C6AF7).withOpacity(0.18) : const Color(0xFF1E1E2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? const Color(0xFF7C6AF7) : Colors.white12,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              c,
                              style: TextStyle(
                                color: sel ? const Color(0xFF7C6AF7) : Colors.white70,
                                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (sel)
                            const Icon(Icons.check_circle, color: Color(0xFF7C6AF7), size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _terminarOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C6AF7),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _carreraSeleccionada.isEmpty ? 'Omitir por ahora' : 'Comenzar con $_carreraSeleccionada',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (_carreraSeleccionada.isEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Puedes cambiarla después en tu Perfil',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
