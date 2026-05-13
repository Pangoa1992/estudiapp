import 'package:flutter/material.dart';
import 'main.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final PageController _pageController = PageController();
  int _paginaActual = 0;

  final List<Map<String, dynamic>> _paginas = [
    {
      'emoji': '🎓',
      'titulo': 'Bienvenido a EstudiApp',
      'descripcion': 'Tu compañero de estudio ideal. Organiza tus exámenes, cumple tus hábitos y no reprobes.',
      'color': const Color(0xFF7C6AF7),
    },
    {
      'emoji': '📅',
      'titulo': 'Tus exámenes',
      'descripcion': 'Agrega tus exámenes con fecha y recibe alertas automáticas. Nunca más olvides una evaluación.',
      'color': const Color(0xFFF7584A),
    },
    {
      'emoji': '✅',
      'titulo': 'Hábitos de estudio',
      'descripcion': 'Crea hábitos personalizados y márcalos cada día. Construye una rutina de estudio consistente.',
      'color': const Color(0xFF5DE0C5),
    },
    {
      'emoji': '🔥',
      'titulo': 'Racha diaria',
      'descripcion': 'Mantén tu racha de estudio. Entre más días consecutivos estudies, más fuerte será tu racha.',
      'color': const Color(0xFFF7A26A),
    },
    {
      'emoji': '⏱️',
      'titulo': 'Timer Pomodoro',
      'descripcion': 'Estudia con la técnica Pomodoro. 25 minutos de estudio y 5 de descanso para máxima concentración.',
      'color': const Color(0xFF7C6AF7),
    },
    {
      'emoji': '🤖',
      'titulo': 'Estudiar con IA',
      'descripcion': 'Escribe cualquier tema y la IA generará resumen, preguntas, flashcards y plan de estudio para ti.',
      'color': const Color(0xFF5DE0C5),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _paginaActual = i),
                itemCount: _paginas.length,
                itemBuilder: (context, i) {
                  final pagina = _paginas[i];
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: (pagina['color'] as Color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(pagina['emoji'], style: const TextStyle(fontSize: 60)),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          pagina['titulo'],
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          pagina['descripcion'],
                          style: const TextStyle(color: Colors.white60, fontSize: 16, height: 1.6),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _paginas.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _paginaActual ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _paginaActual ? const Color(0xFF7C6AF7) : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_paginaActual < _paginas.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const HomePage()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C6AF7),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _paginaActual < _paginas.length - 1 ? 'Siguiente' : '¡Empezar!',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (_paginaActual < _paginas.length - 1) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      ),
                      child: const Text('Saltar tutorial', style: TextStyle(color: Colors.white38, fontSize: 14)),
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