import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/ia_service.dart';
import 'services/monedas_service.dart';
import 'services/resena_service.dart';
import 'mixins/ia_limite_mixin.dart';
import 'l10n_helper.dart';

// ── Country + exam metadata ────────────────────────────────────────────────
const _paises = <String, Map<String, dynamic>>{
  'Perú': {
    'flag': '🇵🇪',
    'examenes': ['UNMSM', 'PUCP', 'UNI', 'Preuniversitario General'],
    'areas': 'Razón verbal, Razonamiento matemático, Ciencias naturales, Historia del Perú, Geografía',
  },
  'México': {
    'flag': '🇲🇽',
    'examenes': ['COMIPEMS (UNAM/IPN)', 'EXANI-II', 'Preuniversitario General'],
    'areas': 'Matemáticas, Español, Ciencias naturales, Historia y geografía de México',
  },
  'Colombia': {
    'flag': '🇨🇴',
    'examenes': ['Saber 11 (ICFES)', 'Preuniversitario General'],
    'areas': 'Lectura crítica, Matemáticas, Ciencias sociales, Ciencias naturales, Inglés',
  },
  'Argentina': {
    'flag': '🇦🇷',
    'examenes': ['UBA - CBC', 'UNLP', 'Preuniversitario General'],
    'areas': 'Lengua y literatura, Matemática, Historia, Ciencias naturales',
  },
  'Chile': {
    'flag': '🇨🇱',
    'examenes': ['PAES', 'Preuniversitario General'],
    'areas': 'Competencia Lectora, Matemática M1, Matemática M2, Ciencias, Historia y Cs. Sociales',
  },
  'Ecuador': {
    'flag': '🇪🇨',
    'examenes': ['SENESCYT (ENES)', 'Preuniversitario General'],
    'areas': 'Razonamiento verbal, Razonamiento abstracto, Razonamiento numérico',
  },
  'Bolivia': {
    'flag': '🇧🇴',
    'examenes': ['UMSA', 'UMSS', 'Preuniversitario General'],
    'areas': 'Matemáticas, Lenguaje y comunicación, Ciencias sociales, Ciencias naturales',
  },
  'Venezuela': {
    'flag': '🇻🇪',
    'examenes': ['CNU - PAA', 'Preuniversitario General'],
    'areas': 'Razonamiento verbal, Razonamiento abstracto, Matemáticas',
  },
  'España': {
    'flag': '🇪🇸',
    'examenes': ['EBAU (Selectividad)', 'Preuniversitario General'],
    'areas': 'Lengua castellana, Matemáticas, Historia de España, Inglés, Materia de modalidad',
  },
  'Panamá': {
    'flag': '🇵🇦',
    'examenes': ['UP - Examen de Ingreso', 'Preuniversitario General'],
    'areas': 'Español, Matemáticas, Ciencias naturales, Estudios sociales',
  },
};

// ── Page ──────────────────────────────────────────────────────────────────
class AdmisionPage extends StatefulWidget {
  const AdmisionPage({super.key});
  @override
  State<AdmisionPage> createState() => _AdmisionPageState();
}

enum _Fase { seleccion, examen, resultado }

class _AdmisionPageState extends State<AdmisionPage>
    with IaLimiteMixin<AdmisionPage> {
  _Fase _fase = _Fase.seleccion;
  bool _cargando = false;

  String _paisSeleccionado = 'Perú';
  String _examenSeleccionado = 'UNMSM';
  int _cantidadPreguntas = 10;

  List<Map<String, dynamic>> _preguntas = [];
  List<String?> _respuestasUsuario = [];
  int _preguntaActual = 0;
  bool _terminado = false;

  @override
  void initState() {
    super.initState();
    _examenSeleccionado =
        (_paises['Perú']!['examenes'] as List<String>).first;
    initIaLimite();
  }

  @override
  void dispose() {
    disposeIaLimite();
    super.dispose();
  }

  void _onPaisChanged(String pais) {
    setState(() {
      _paisSeleccionado = pais;
      _examenSeleccionado =
          (_paises[pais]!['examenes'] as List<String>).first;
    });
  }

  Future<void> _generarSimulacro() async {
    if (!await verificarYConsumir()) return; // ── LÍMITE DIARIO
    setState(() => _cargando = true);

    final pais = _paises[_paisSeleccionado]!;
    final areas = pais['areas'] as String;

    final json = await IAService.llamarJSON(
      'Eres experto en exámenes de admisión universitaria de $_paisSeleccionado. '
      'Genera exactamente $_cantidadPreguntas preguntas estilo "$_examenSeleccionado" con opciones múltiples (A, B, C, D). '
      'Las preguntas deben ser representativas del examen real e incluir estas áreas: $areas. '
      'Responde SOLO con JSON válido sin texto extra. '
      'Formato: {"preguntas": [{"area": "nombre_area", "pregunta": "enunciado", '
      '"opciones": ["A. opción1", "B. opción2", "C. opción3", "D. opción4"], '
      '"correcta": "A", "explicacion": "razón breve"}]}. '
      'Todo en español. La clave "correcta" debe ser solo la letra A, B, C o D.',
    );

    if (json == null || json['preguntas'] == null) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.simError)),
        );
      }
      return;
    }

    final lista = List<Map<String, dynamic>>.from(
      (json['preguntas'] as List).map((e) => Map<String, dynamic>.from(e)),
    );

    setState(() {
      _preguntas = lista;
      _respuestasUsuario = List.filled(lista.length, null);
      _preguntaActual = 0;
      _terminado = false;
      _fase = _Fase.examen;
      _cargando = false;
    });
  }

  int get _puntaje {
    int correctas = 0;
    for (int i = 0; i < _preguntas.length; i++) {
      final correcta =
          _preguntas[i]['correcta']?.toString().trim().toUpperCase() ?? '';
      final resp = _respuestasUsuario[i]?.trim().toUpperCase() ?? '';
      if (resp.startsWith(correcta)) correctas++;
    }
    return correctas;
  }

  Future<void> _finalizarYGuardar() async {
    setState(() { _terminado = true; _fase = _Fase.resultado; });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final correctas = _puntaje;
    final total = _preguntas.length;
    final porcentaje = total > 0 ? (correctas / total * 100).round() : 0;

    try {
      await FirebaseFirestore.instance.collection('admision_sesiones').add({
        'userId': user.uid,
        'pais': _paisSeleccionado,
        'examen': _examenSeleccionado,
        'cantidadPreguntas': total,
        'correctas': correctas,
        'porcentaje': porcentaje,
        'fechaFin': Timestamp.now(),
      });
    } catch (_) {}

    MonedasService.agregar(MonedasService.porSimulacro, 'simulacro_admision');
    if (total > 0 && correctas == total) {
      MonedasService.agregar(MonedasService.porPerfecto, 'simulacro_admision_perfecto');
    }
    unawaited(ResenaService.onSimulacroCompletado());
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          context.l10n.admisionTitle,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          if (_fase != _Fase.seleccion)
            TextButton(
              onPressed: () => setState(() {
                _fase = _Fase.seleccion;
                _preguntas = [];
                _respuestasUsuario = [];
                _terminado = false;
              }),
              child: Text(context.l10n.newLabel,
                  style: const TextStyle(color: Color(0xFF7C6AF7))),
            ),
        ],
      ),
      body: _cargando
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF7C6AF7)),
                  const SizedBox(height: 16),
                  Text(context.l10n.generatingAI,
                      style: const TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : _fase == _Fase.seleccion
              ? _buildSeleccion()
              : _fase == _Fase.examen
                  ? _buildExamen()
                  : _buildResultado(),
    );
  }

  // ── Fase 1: Selección ───────────────────────────────────────────────────

  Widget _buildSeleccion() {
    final examenes = _paises[_paisSeleccionado]!['examenes'] as List<String>;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1F2A5E), Color(0xFF1A3A2F)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Text('🎓', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.admisionTitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text(context.l10n.admisionSubtitle,
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // País
          Text(context.l10n.countryLabel,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _paises.entries.map((entry) {
                final selected = _paisSeleccionado == entry.key;
                return GestureDetector(
                  onTap: () => _onPaisChanged(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF7C6AF7)
                          : const Color(0xFF1E1E2A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF7C6AF7)
                            : Colors.white12,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(entry.value['flag'] as String,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(entry.key,
                            style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Tipo de examen
          Text(context.l10n.examLabel,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          ...examenes.map((ex) {
            final selected = _examenSeleccionado == ex;
            return GestureDetector(
              onTap: () => setState(() => _examenSeleccionado = ex),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF7C6AF7).withOpacity(0.15)
                      : const Color(0xFF1E1E2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF7C6AF7)
                        : Colors.white12,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? const Color(0xFF7C6AF7)
                          : Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(ex,
                        style: TextStyle(
                            color: selected ? Colors.white : Colors.white70,
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),

          // Cantidad
          Text(context.l10n.questionsLabel,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Row(
            children: [5, 10, 15, 20].map((n) {
              final selected = _cantidadPreguntas == n;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _cantidadPreguntas = n),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF7C6AF7)
                          : const Color(0xFF1E1E2A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected
                              ? const Color(0xFF7C6AF7)
                              : Colors.white12),
                    ),
                    child: Center(
                      child: Text('$n',
                          style: TextStyle(
                              color: selected ? Colors.white : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Areas info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF5DE0C5), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _paises[_paisSeleccionado]!['areas'] as String,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Historial
          _buildHistorial(),
          const SizedBox(height: 20),

          // Botón
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generarSimulacro,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: Text(
                context.l10n.startSim(_paisSeleccionado),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6AF7),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorial() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.recentHistory,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('admision_sesiones')
              .where('userId', isEqualTo: user.uid)
              .orderBy('fechaFin', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError || !snap.hasData || snap.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    snap.hasError
                        ? context.l10n.historyError
                        : context.l10n.noSimulacros,
                    style: const TextStyle(color: Colors.white38, fontSize: 13)),
                ),
              );
            }
            return Column(
              children: snap.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final pct = d['porcentaje'] as int? ?? 0;
                final color = pct >= 70
                    ? const Color(0xFF5DE0C5)
                    : pct >= 50
                        ? const Color(0xFFF7A26A)
                        : const Color(0xFFF7584A);
                final flag = (_paises[d['pais']]?['flag'] as String?) ?? '🌎';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['examen'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            Text(
                                context.l10n.correctOf(
                                  (d['correctas'] as num? ?? 0).toInt(),
                                  (d['cantidadPreguntas'] as num? ?? 0).toInt(),
                                ),
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      ),
                      Text('$pct%',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ── Fase 2: Examen ──────────────────────────────────────────────────────

  Widget _buildExamen() {
    if (_terminado) return _buildResultado();
    final pregunta = _preguntas[_preguntaActual];
    final opciones = List<String>.from(pregunta['opciones'] ?? []);
    final respActual = _respuestasUsuario[_preguntaActual];
    final progreso = (_preguntaActual + 1) / _preguntas.length;
    final flag = _paises[_paisSeleccionado]!['flag'] as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$flag $_examenSeleccionado',
                style: const TextStyle(
                    color: Color(0xFF7C6AF7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                context.l10n.questionCounter(_preguntaActual + 1, _preguntas.length),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progreso,
              backgroundColor: Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF7C6AF7)),
              minHeight: 6,
            ),
          ),

          // Área
          const SizedBox(height: 16),
          if ((pregunta['area'] as String?)?.isNotEmpty == true)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7C6AF7).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF7C6AF7).withOpacity(0.3)),
              ),
              child: Text(pregunta['area'] as String,
                  style: const TextStyle(
                      color: Color(0xFF7C6AF7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),

          // Enunciado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF7C6AF7).withOpacity(0.2)),
            ),
            child: Text(
              pregunta['pregunta']?.toString() ?? '',
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),

          // Opciones
          ...opciones.map((opcion) {
            final letra =
                opcion.isNotEmpty ? opcion.substring(0, 1) : '';
            final selected = respActual == opcion;
            return GestureDetector(
              onTap: () =>
                  setState(() => _respuestasUsuario[_preguntaActual] = opcion),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF7C6AF7).withOpacity(0.15)
                      : const Color(0xFF1E1E2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF7C6AF7)
                        : const Color(0xFF2E2E3E),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF7C6AF7)
                            : const Color(0xFF0F0F14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(letra,
                            style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.white54,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opcion.length > 2
                            ? opcion.substring(2).trim()
                            : opcion,
                        style: TextStyle(
                            color: selected ? Colors.white : Colors.white70,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // Navegación
          Row(
            children: [
              if (_preguntaActual > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        setState(() => _preguntaActual--),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(context.l10n.previousQuestion,
                        style: const TextStyle(color: Colors.white54)),
                  ),
                ),
              if (_preguntaActual > 0) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: (respActual != null ||
                          _preguntaActual == _preguntas.length - 1)
                      ? () async {
                          if (_preguntaActual < _preguntas.length - 1) {
                            setState(() => _preguntaActual++);
                          } else {
                            await _finalizarYGuardar();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6AF7),
                    disabledBackgroundColor: const Color(0xFF2E2E3E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _preguntaActual < _preguntas.length - 1
                        ? context.l10n.next
                        : context.l10n.seeResult,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Fase 3: Resultado ───────────────────────────────────────────────────

  Widget _buildResultado() {
    final correctas = _puntaje;
    final total = _preguntas.length;
    final pct = total > 0 ? (correctas / total * 100).round() : 0;
    final color = pct >= 70
        ? const Color(0xFF5DE0C5)
        : pct >= 50
            ? const Color(0xFFF7A26A)
            : const Color(0xFFF7584A);
    final emoji = pct >= 70 ? '🎉' : pct >= 50 ? '👍' : '💪';
    final l10n = context.l10n;
    final msg = pct >= 70
        ? l10n.resultExcellent
        : pct >= 50
            ? l10n.resultGood
            : l10n.resultTryMore;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Tarjeta resultado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), const Color(0xFF0F0F14)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 8),
                Text(msg,
                    style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '$_examenSeleccionado · ${_paises[_paisSeleccionado]!['flag']}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Text('$pct%',
                    style: TextStyle(
                        color: color,
                        fontSize: 56,
                        fontWeight: FontWeight.bold)),
                Text(l10n.correctOf(correctas, total),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Revisión
          Align(
            alignment: Alignment.centerLeft,
            child: Text(l10n.reviewAnswers,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
          ),
          const SizedBox(height: 12),
          ..._preguntas.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final correctaLetra =
                p['correcta']?.toString().trim().toUpperCase() ?? '';
            final respLetra =
                _respuestasUsuario[i]?.trim().toUpperCase() ?? '';
            final esCorrecta = respLetra.startsWith(correctaLetra);
            final opciones = List<String>.from(p['opciones'] ?? []);
            final opCorrecta = opciones.firstWhere(
              (o) => o.toUpperCase().startsWith(correctaLetra),
              orElse: () => correctaLetra,
            );
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: esCorrecta
                      ? const Color(0xFF5DE0C5).withOpacity(0.3)
                      : const Color(0xFFF7584A).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        esCorrecta ? Icons.check_circle : Icons.cancel,
                        color: esCorrecta
                            ? const Color(0xFF5DE0C5)
                            : const Color(0xFFF7584A),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      if ((p['area'] as String?)?.isNotEmpty == true)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF7C6AF7).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(p['area'] as String,
                              style: const TextStyle(
                                  color: Color(0xFF7C6AF7), fontSize: 10)),
                        ),
                      Expanded(
                        child: Text(
                          '${i + 1}. ${p['pregunta']}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!esCorrecta) ...[
                    Text(
                      '${l10n.yourAnswer} ${_respuestasUsuario[i] ?? '—'}',
                      style: const TextStyle(
                          color: Color(0xFFF7584A), fontSize: 12),
                    ),
                    Text(
                      '${l10n.correctAnswer} $opCorrecta',
                      style: const TextStyle(
                          color: Color(0xFF5DE0C5), fontSize: 12),
                    ),
                  ] else
                    Text('✓ ${_respuestasUsuario[i]}',
                        style: const TextStyle(
                            color: Color(0xFF5DE0C5), fontSize: 12)),
                  if ((p['explicacion'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      '💡 ${p['explicacion']}',
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          height: 1.4),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _fase = _Fase.seleccion;
                    _preguntas = [];
                    _respuestasUsuario = [];
                    _terminado = false;
                  }),
                  icon: const Icon(Icons.list, color: Color(0xFF7C6AF7)),
                  label: Text(l10n.back,
                      style: const TextStyle(color: Color(0xFF7C6AF7))),
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFF7C6AF7)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generarSimulacro,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(l10n.anotherSim,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6AF7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
