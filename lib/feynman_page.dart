import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/ia_service.dart';
import 'services/carrera_service.dart';
import 'mixins/ia_limite_mixin.dart';

class FeynmanPage extends StatefulWidget {
  const FeynmanPage({super.key});
  @override
  State<FeynmanPage> createState() => _FeynmanPageState();
}

class _FeynmanPageState extends State<FeynmanPage>
    with IaLimiteMixin<FeynmanPage> {
  final _temaCtrl = TextEditingController();
  final _explicacionCtrl = TextEditingController();
  final _respuestaCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String _carrera = '';
  String _fase = 'inicio'; // inicio | explicando | conversando | resultado
  String _tema = '';
  bool _cargando = false;

  // Conversación IA
  List<Map<String, String>> _mensajes = [];
  int _turnosRestantes = 3;

  // Resultado final
  String _resultadoTexto = '';
  int _puntuacion = 0; // 0-100

  @override
  void initState() {
    super.initState();
    _cargarCarrera();
    initIaLimite();
  }

  @override
  void dispose() {
    _temaCtrl.dispose();
    _explicacionCtrl.dispose();
    _respuestaCtrl.dispose();
    _scrollCtrl.dispose();
    disposeIaLimite();
    super.dispose();
  }

  Future<void> _cargarCarrera() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('perfiles').doc(uid).get();
    if (mounted) setState(() => _carrera = (doc.data()?['carrera'] as String?) ?? '');
  }

  Future<void> _iniciarFeynman() async {
    if (_temaCtrl.text.trim().isEmpty || _explicacionCtrl.text.trim().isEmpty) return;
    if (!await verificarYConsumir()) return; // ── LÍMITE DIARIO
    setState(() {
      _tema = _temaCtrl.text.trim();
      _cargando = true;
      _fase = 'conversando';
      _mensajes = [
        {'role': 'user', 'text': _explicacionCtrl.text.trim()}
      ];
    });

    final contexto = CarreraService.contextoIA(_carrera);
    final prompt = '''
Eres un estudiante curioso que está aprendiendo "${_tema}" de un compañero tutor.
${contexto.isNotEmpty ? "Contexto de carrera: $contexto" : ""}
El tutor acaba de explicarte: "${_explicacionCtrl.text.trim()}"

Tu tarea es:
1. Identificar conceptos incompletos, incorrectos o confusos en la explicación.
2. Hacer UNA sola pregunta de seguimiento sobre el punto más débil que detectaste.
3. Ser curioso y específico, como alguien que realmente quiere entender.
4. NO te presentes, solo haz la pregunta directamente.
5. Máximo 2 oraciones.

Responde SOLO con la pregunta de seguimiento.
''';

    final respuesta = await IAService.llamar(prompt);
    if (mounted) {
      setState(() {
        _mensajes.add({'role': 'ia', 'text': respuesta ?? '¿Puedes explicarlo con más detalle?'});
        _cargando = false;
        _turnosRestantes = 3;
      });
      _scrollAbajo();
    }
  }

  Future<void> _responder() async {
    final texto = _respuestaCtrl.text.trim();
    if (texto.isEmpty || _cargando) return;
    if (!await verificarYConsumir()) return; // ── LÍMITE DIARIO
    _respuestaCtrl.clear();

    setState(() {
      _mensajes.add({'role': 'user', 'text': texto});
      _cargando = true;
      _turnosRestantes--;
    });
    _scrollAbajo();

    if (_turnosRestantes <= 0) {
      await _generarResultado();
      return;
    }

    final contexto = CarreraService.contextoIA(_carrera);
    final historialTexto = _mensajes
        .map((m) => '${m['role'] == 'user' ? 'Tutor' : 'Estudiante'}: ${m['text']}')
        .join('\n');

    final prompt = '''
Estás aprendiendo "${_tema}" de un compañero tutor.
${contexto.isNotEmpty ? "Contexto: $contexto" : ""}

Conversación hasta ahora:
$historialTexto

Basándote en la última respuesta del tutor, haz UNA pregunta de seguimiento sobre el aspecto más débil o confuso.
Si el tutor lo explicó bien, profundiza más con una pregunta avanzada.
Máximo 2 oraciones. Solo la pregunta, sin presentación.
''';

    final respuesta = await IAService.llamar(prompt);
    if (mounted) {
      setState(() {
        _mensajes.add({'role': 'ia', 'text': respuesta ?? '¿Puedes dar un ejemplo concreto?'});
        _cargando = false;
      });
      _scrollAbajo();
    }
  }

  Future<void> _generarResultado() async {
    final contexto = CarreraService.contextoIA(_carrera);
    final historialTexto = _mensajes
        .map((m) => '${m['role'] == 'user' ? 'Tutor' : 'Evaluador'}: ${m['text']}')
        .join('\n');

    final prompt = '''
Eres un evaluador académico experto. Evalúa si el estudiante realmente domina el tema "${_tema}".
${contexto.isNotEmpty ? "Carrera: $contexto" : ""}

Conversación de enseñanza:
$historialTexto

Responde SOLO con JSON válido:
{
  "puntuacion": (0-100 basado en claridad, profundidad, precisión y ejemplos),
  "nivel": ("Dominado" | "En desarrollo" | "Necesita refuerzo"),
  "fortalezas": ["punto fuerte 1", "punto fuerte 2"],
  "debilidades": ["punto débil 1", "punto débil 2"],
  "consejo": "Un consejo concreto para mejorar el dominio del tema"
}
''';

    final json = await IAService.llamarJSON(prompt);
    if (mounted) {
      setState(() {
        _puntuacion = (json?['puntuacion'] as num?)?.toInt() ?? 50;
        _resultadoTexto = json?['nivel']?.toString() ?? 'En desarrollo';
        _mensajes.add({
          'role': 'ia',
          'text': '✅ Sesión completada. Ve los resultados abajo.',
        });
        _cargando = false;
        _fase = 'resultado';
        _turnosRestantes = 0;

        // Guardar el resultado en Firestore
        _guardarResultado(json);
      });
      _scrollAbajo();
    }
  }

  Future<void> _guardarResultado(Map<String, dynamic>? json) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('feynman_sesiones').add({
      'userId': uid,
      'tema': _tema,
      'carrera': _carrera,
      'puntuacion': json?['puntuacion'] ?? 0,
      'nivel': json?['nivel'] ?? '',
      'fecha': Timestamp.now(),
    });
  }

  void _scrollAbajo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _colorPuntuacion() {
    if (_puntuacion >= 80) return const Color(0xFF5DE0C5);
    if (_puntuacion >= 60) return const Color(0xFF4A90E2);
    if (_puntuacion >= 40) return const Color(0xFFF7A26A);
    return const Color(0xFFF7584A);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        title: const Text('Técnica Feynman',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_fase != 'inicio')
            TextButton(
              onPressed: () => setState(() {
                _fase = 'inicio';
                _mensajes = [];
                _turnosRestantes = 3;
                _temaCtrl.clear();
                _explicacionCtrl.clear();
                _resultadoTexto = '';
              }),
              child: const Text('Nueva sesión',
                  style: TextStyle(color: Color(0xFF7C6AF7))),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_fase == 'inicio') _buildInicio(),
          if (_fase != 'inicio') ...[
            _buildInfoBanner(),
            Expanded(child: _buildChat()),
          ],
          if (_fase == 'resultado') _buildResultado(),
          if (_fase == 'conversando' || _fase == 'explicando')
            _buildInputRespuesta(),
        ],
      ),
    );
  }

  Widget _buildInicio() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A40), Color(0xFF0F1A20)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF7C6AF7).withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Cómo funciona?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  _Paso('1', 'Escribe el tema que crees que dominas'),
                  _Paso('2', 'Explícalo como si se lo enseñaras a alguien'),
                  _Paso('3', 'La IA te hará preguntas para encontrar tus vacíos'),
                  _Paso('4', 'Obtienes un diagnóstico real de tu comprensión'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _campo('Tema a enseñar', _temaCtrl,
                hint: 'Ej: La ley de Ohm, El ciclo del nitrógeno, Habeas Corpus'),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF7C6AF7).withOpacity(0.3)),
              ),
              child: TextField(
                controller: _explicacionCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText:
                      'Explica el tema aquí, como si se lo enseñaras a alguien que no sabe nada...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                  contentPadding: EdgeInsets.all(14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _iniciarFeynman,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C6AF7), Color(0xFF5A4ED4)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.science_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Iniciar sesión Feynman',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    final color = _turnosRestantes > 1
        ? const Color(0xFF7C6AF7)
        : const Color(0xFFF7A26A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: const Color(0xFF1E1E2A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Tema: $_tema',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          if (_fase == 'conversando')
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_turnosRestantes preguntas restantes',
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChat() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: _mensajes.length + (_cargando ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _mensajes.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(children: [
              SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF7C6AF7))),
              SizedBox(width: 10),
              Text('La IA está evaluando...',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
          );
        }
        final msg = _mensajes[i];
        final esUsuario = msg['role'] == 'user';
        return Align(
          alignment:
              esUsuario ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
            decoration: BoxDecoration(
              color: esUsuario
                  ? const Color(0xFF7C6AF7)
                  : const Color(0xFF1E1E2A),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(esUsuario ? 14 : 4),
                bottomRight: Radius.circular(esUsuario ? 4 : 14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!esUsuario)
                  const Text('IA evaluadora',
                      style: TextStyle(
                          color: Color(0xFF7C6AF7),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                Text(
                  msg['text'] ?? '',
                  style: TextStyle(
                      color: esUsuario ? Colors.white : Colors.white70,
                      fontSize: 14,
                      height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputRespuesta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      color: const Color(0xFF1E1E2A),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _respuestaCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: _turnosRestantes > 0
                    ? 'Responde a la pregunta...'
                    : 'Última respuesta...',
                hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0F0F14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(12),
              ),
              onSubmitted: (_) => _responder(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _cargando ? null : _responder,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cargando
                    ? Colors.grey
                    : const Color(0xFF7C6AF7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultado() {
    final color = _colorPuntuacion();
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0F0F14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _puntuacion >= 80
                            ? '🎓'
                            : _puntuacion >= 60
                                ? '📚'
                                : '⚠️',
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_resultadoTexto,
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            Text('Puntuación: $_puntuacion / 100',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl,
      {String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: Colors.white38, fontSize: 13),
              contentPadding: const EdgeInsets.all(14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _Paso extends StatelessWidget {
  final String numero;
  final String texto;
  const _Paso(this.numero, this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF7C6AF7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(numero,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: Text(texto,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
