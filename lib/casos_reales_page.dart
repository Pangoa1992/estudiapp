import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/ia_service.dart';
import 'services/carrera_service.dart';
import 'mixins/ia_limite_mixin.dart';

class CasosRealesPage extends StatefulWidget {
  const CasosRealesPage({super.key});
  @override
  State<CasosRealesPage> createState() => _CasosRealesPageState();
}

class _CasosRealesPageState extends State<CasosRealesPage>
    with IaLimiteMixin<CasosRealesPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String _carrera = '';
  String _escenario = '';
  String _fase = 'seleccion'; // seleccion | simulando | evaluando | resultado
  bool _cargando = false;

  List<Map<String, String>> _mensajes = [];
  String _evaluacion = '';
  int _puntuacion = 0;
  int _turnosRestantes = 5;

  @override
  void initState() {
    super.initState();
    _cargarCarrera();
    initIaLimite();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    disposeIaLimite();
    super.dispose();
  }

  Future<void> _cargarCarrera() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('perfiles').doc(uid).get();
    if (mounted) setState(() => _carrera = (doc.data()?['carrera'] as String?) ?? 'Otra');
  }

  Future<void> _iniciarCaso(String escenario) async {
    if (!await verificarYConsumir()) return; // ── LÍMITE DIARIO
    setState(() {
      _escenario = escenario;
      _fase = 'simulando';
      _mensajes = [];
      _cargando = true;
      _turnosRestantes = 5;
    });

    final rol = CarreraService.rolIAEnCaso(_carrera);
    final contexto = CarreraService.contextoIA(_carrera);

    final prompt = '''
Eres un $rol en una simulación de caso real para un estudiante de $_carrera.
Escenario: "$escenario"
$contexto

Inicia la simulación presentándote como el personaje.
Describe la situación de forma realista y urgente (2-3 oraciones).
Luego haz UNA pregunta o petición concreta al estudiante para que tome acción.
NO expliques que es una simulación. Actúa de forma completamente real.
''';

    final resp = await IAService.llamar(prompt, maxTokens: 400);
    if (mounted) {
      setState(() {
        _mensajes = [
          {'role': 'ia', 'text': resp ?? 'Iniciando escenario...'}
        ];
        _cargando = false;
      });
      _scrollAbajo();
    }
  }

  Future<void> _enviarRespuesta() async {
    final texto = _msgCtrl.text.trim();
    if (texto.isEmpty || _cargando) return;
    if (!await verificarYConsumir()) return; // ── LÍMITE DIARIO
    _msgCtrl.clear();

    setState(() {
      _mensajes.add({'role': 'user', 'text': texto});
      _cargando = true;
      _turnosRestantes--;
    });
    _scrollAbajo();

    if (_turnosRestantes <= 0) {
      await _evaluarDesempeno();
      return;
    }

    final rol = CarreraService.rolIAEnCaso(_carrera);
    final historial = _mensajes
        .map((m) =>
            '${m['role'] == 'user' ? 'Estudiante' : 'Personaje'}: ${m['text']}')
        .join('\n');

    final prompt = '''
Eres un $rol en una simulación de caso de $_carrera.
Escenario: "$_escenario"

Conversación hasta ahora:
$historial

Responde a la última acción/respuesta del estudiante de forma realista.
Mantén el rol. Si la respuesta es correcta, el caso avanza positivamente.
Si hay errores, el caso se complica (pero no te salgas del rol).
Haz una nueva pregunta o situación para el estudiante. Máximo 3 oraciones.
''';

    final resp = await IAService.llamar(prompt, maxTokens: 400);
    if (mounted) {
      setState(() {
        _mensajes.add({'role': 'ia', 'text': resp ?? 'Continúa...'});
        _cargando = false;
      });
      _scrollAbajo();
    }
  }

  Future<void> _evaluarDesempeno() async {
    setState(() => _fase = 'evaluando');

    final historial = _mensajes
        .map((m) =>
            '${m['role'] == 'user' ? 'Estudiante' : 'Evaluador'}: ${m['text']}')
        .join('\n');

    final prompt = '''
Eres un evaluador experto en $_carrera. Analiza el desempeño del estudiante en este caso real.

Escenario: "$_escenario"
Carrera: $_carrera

Caso simulado:
$historial

Responde SOLO con JSON válido:
{
  "puntuacion": (0-100),
  "nivel": ("Excelente" | "Bueno" | "Regular" | "Necesita mejorar"),
  "aciertos": ["acierto 1", "acierto 2"],
  "errores": ["error 1", "error 2"],
  "feedback": "Retroalimentación detallada de 2-3 oraciones",
  "recomendacion": "Qué debe estudiar o practicar para mejorar"
}
''';

    final json = await IAService.llamarJSON(prompt);
    if (mounted) {
      _puntuacion = (json?['puntuacion'] as num?)?.toInt() ?? 50;
      _evaluacion = json?['nivel']?.toString() ?? 'Regular';

      // Guardar en Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        FirebaseFirestore.instance.collection('casos_reales_sesiones').add({
          'userId': uid,
          'carrera': _carrera,
          'escenario': _escenario,
          'puntuacion': _puntuacion,
          'nivel': _evaluacion,
          'fecha': Timestamp.now(),
        });
      }

      setState(() {
        _mensajes.add({
          'role': 'ia',
          'text':
              '📋 Caso finalizado. Puntuación: $_puntuacion/100 — $_evaluacion',
        });
        _cargando = false;
        _fase = 'resultado';
        _evaluacionData = json;
      });
      _scrollAbajo();
    }
  }

  Map<String, dynamic>? _evaluacionData;

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
        title: const Text('Casos Reales 🎭',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_fase != 'seleccion')
            TextButton(
              onPressed: () => setState(() {
                _fase = 'seleccion';
                _mensajes = [];
                _escenario = '';
                _evaluacion = '';
              }),
              child: const Text('Nuevo caso',
                  style: TextStyle(color: Color(0xFF7C6AF7))),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_fase == 'seleccion') _buildSeleccion(),
          if (_fase != 'seleccion') ...[
            _buildBanner(),
            Expanded(child: _buildChat()),
            if (_fase == 'resultado') _buildResultado(),
            if (_fase == 'simulando') _buildInput(),
          ],
        ],
      ),
    );
  }

  Widget _buildSeleccion() {
    final escenarios = CarreraService.escenarios(_carrera);
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF2A1F5E), Color(0xFF1F3A35)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('🎭', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Simulador de Casos Reales',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text(
                          _carrera.isNotEmpty
                              ? 'Practicando como: $_carrera'
                              : 'Carrera no configurada — ve a tu perfil',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('ELIGE UN ESCENARIO',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            ...escenarios.map((e) => GestureDetector(
                  onTap: () => _iniciarCaso(e),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF7C6AF7).withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.play_circle_outline,
                            color: Color(0xFF7C6AF7), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(e,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            color: Colors.white24, size: 14),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            // Escenario personalizado
            GestureDetector(
              onTap: _pedirEscenarioPersonalizado,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF5DE0C5).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: Color(0xFF5DE0C5), size: 22),
                    SizedBox(width: 12),
                    Text('Escenario personalizado...',
                        style:
                            TextStyle(color: Color(0xFF5DE0C5), fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pedirEscenarioPersonalizado() async {
    final ctrl = TextEditingController();
    final resultado = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Escenario personalizado',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Describe el escenario...',
            hintStyle: TextStyle(color: Colors.white38),
            border: InputBorder.none,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C6AF7)),
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Iniciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (resultado != null && resultado.isNotEmpty) {
      _iniciarCaso(resultado);
    }
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: const Color(0xFF1E1E2A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(_escenario,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          if (_fase == 'simulando')
            Row(
              children: [
                const Icon(Icons.radio_button_on,
                    color: Color(0xFFF7584A), size: 10),
                const SizedBox(width: 4),
                Text('$_turnosRestantes turnos',
                    style: const TextStyle(
                        color: Color(0xFFF7A26A),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
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
              Text('El escenario continúa...',
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
                  Text(
                    CarreraService.rolIAEnCaso(_carrera).toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFFF7A26A),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
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

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      color: const Color(0xFF1E1E2A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: '¿Qué haces o dices?',
                    hintStyle:
                        TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: Color(0xFF0F0F14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  onSubmitted: (_) => _enviarRespuesta(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _cargando ? null : _enviarRespuesta,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _cargando ? Colors.grey : const Color(0xFF7C6AF7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _cargando
                ? null
                : () async {
                    if (!await verificarYConsumir()) return;
                    await _evaluarDesempeno();
                  }, // ── LÍMITE DIARIO (llamada directa)
            child: const Text('Finalizar caso y ver evaluación',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultado() {
    final color = _colorPuntuacion();
    final aciertos = List<String>.from(_evaluacionData?['aciertos'] ?? []);
    final errores = List<String>.from(_evaluacionData?['errores'] ?? []);
    final feedback = _evaluacionData?['feedback']?.toString() ?? '';
    final reco = _evaluacionData?['recomendacion']?.toString() ?? '';

    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0F0F14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    '$_evaluacion — $_puntuacion/100',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(feedback,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.4)),
            ],
            if (aciertos.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...aciertos.map((a) => Row(children: [
                    const Icon(Icons.check, color: Color(0xFF5DE0C5), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(a,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12))),
                  ])),
            ],
            if (errores.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...errores.map((e) => Row(children: [
                    const Icon(Icons.close, color: Color(0xFFF7584A), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(e,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12))),
                  ])),
            ],
            if (reco.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(reco,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
