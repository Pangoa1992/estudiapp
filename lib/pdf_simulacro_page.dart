import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'services/compartir_service.dart';
import 'services/premium_service.dart';
import 'premium_page.dart';

// ── PDF Simulacro Page ────────────────────────────────────────────────────────
// Teacher uploads a PDF of a past exam → AI converts it → students take it.
class PdfSimulacroPage extends StatefulWidget {
  const PdfSimulacroPage({super.key});
  @override
  State<PdfSimulacroPage> createState() => _PdfSimulacroPageState();
}

enum _PdfFase { lista, subiendo, tomando, resultado }

class _PdfSimulacroPageState extends State<PdfSimulacroPage> {
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;
  static const _url = 'https://llamaria-2o5lsg4hxa-uc.a.run.app';

  _PdfFase _fase = _PdfFase.lista;
  bool _cargando = false;
  String _progreso = '';

  // Exam being taken
  String? _simulacroId;
  String _titulo = '';
  List<Map<String, dynamic>> _preguntas = [];
  List<String?> _respuestas = [];
  int _preguntaActual = 0;

  // Results
  int _correctas = 0;

  Future<String?> _token() async {
    try {
      return await _user?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _subirPDF() async {
    final isPremium = await PremiumService.isPremium();
    if (!isPremium) {
      if (!mounted) return;
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const PremiumPage()));
      return;
    }

    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result == null) return;

      setState(() {
        _fase = _PdfFase.subiendo;
        _cargando = true;
        _progreso = 'Leyendo PDF...';
      });

      final path = result.files.single.path;
      if (path == null) {
        setState(() { _cargando = false; _fase = _PdfFase.lista; });
        return;
      }
      final file = File(path);
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        setState(() { _cargando = false; _fase = _PdfFase.lista; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('PDF demasiado grande. Máximo 5 MB.')));
        }
        return;
      }

      final base64PDF = base64Encode(bytes);
      final nombreArchivo = result.files.single.name
          .replaceAll('.pdf', '')
          .replaceAll('_', ' ')
          .replaceAll('-', ' ');

      setState(() => _progreso = 'Analizando examen con IA...');

      final token = await _token();
      if (token == null) {
        setState(() { _cargando = false; _fase = _PdfFase.lista; });
        return;
      }

      final res = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'data': {
            'messages': [
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'document',
                    'source': {
                      'type': 'base64',
                      'media_type': 'application/pdf',
                      'data': base64PDF,
                    },
                  },
                  {
                    'type': 'text',
                    'text':
                        'Eres un asistente pedagógico. Analiza este examen y extrae TODAS las preguntas. '
                        'Para cada pregunta crea 4 opciones (A, B, C, D) si no las tiene, marcando la correcta. '
                        'Responde SOLO con JSON válido. '
                        'Formato: {"titulo": "nombre del examen", "preguntas": ['
                        '{"enunciado": "texto", "opciones": ["A. op1","B. op2","C. op3","D. op4"], '
                        '"correcta": "A", "explicacion": "razón breve"}]}. '
                        'Todo en español.',
                  },
                ],
              }
            ],
            'maxTokens': 4000,
          }
        }),
      );

      if (res.statusCode != 200) {
        setState(() { _cargando = false; _fase = _PdfFase.lista; });
        return;
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final texto =
          (body['result']?['content'] as List?)?.first['text'] as String? ?? '';

      String jsonLimpio = texto.trim();
      final ini = jsonLimpio.indexOf('{');
      final fin = jsonLimpio.lastIndexOf('}');
      if (ini == -1 || fin == -1) {
        setState(() { _cargando = false; _fase = _PdfFase.lista; });
        return;
      }
      jsonLimpio = jsonLimpio.substring(ini, fin + 1);

      final jsonData = jsonDecode(jsonLimpio) as Map<String, dynamic>;
      final titulo = jsonData['titulo'] as String? ?? nombreArchivo;
      final preguntasRaw = jsonData['preguntas'] as List? ?? [];
      final preguntas = preguntasRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (preguntas.isEmpty) {
        setState(() { _cargando = false; _fase = _PdfFase.lista; });
        return;
      }

      setState(() => _progreso = 'Guardando simulacro...');

      // Save to Firestore
      final codigo = _generarCodigo();
      final ref = await _db.collection('pdf_simulacros').add({
        'titulo': titulo,
        'creadorId': _user?.uid,
        'creadorNombre': _user?.displayName ?? 'Docente',
        'codigo': codigo,
        'preguntas': preguntas,
        'totalPreguntas': preguntas.length,
        'creadoEn': Timestamp.now(),
        'activo': true,
      });

      if (mounted) {
        setState(() { _cargando = false; _fase = _PdfFase.lista; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Simulacro "$titulo" creado! Código: $codigo'),
          backgroundColor: const Color(0xFF7C6AF7),
          duration: const Duration(seconds: 5),
        ));
      }
      debugPrint('PDF simulacro created: ${ref.id}');
    } catch (e) {
      setState(() { _cargando = false; _fase = _PdfFase.lista; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar el PDF.')),
        );
      }
    }
  }

  Future<void> _unirseConCodigo() async {
    final ctrl = TextEditingController();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        title: const Text('Unirme a simulacro',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(
              color: Colors.white,
              letterSpacing: 4,
              fontWeight: FontWeight.bold),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'Código de 6 caracteres',
            labelStyle: const TextStyle(color: Color(0xFF7C6AF7)),
            filled: true,
            fillColor: const Color(0xFF0F0F14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            counterStyle: const TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6AF7)),
            onPressed: () async {
              final codigo = ctrl.text.trim().toUpperCase();
              Navigator.pop(ctx);
              await _cargarSimulacroPorCodigo(codigo);
            },
            child: const Text('Entrar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarSimulacroPorCodigo(String codigo) async {
    final snap = await _db
        .collection('pdf_simulacros')
        .where('codigo', isEqualTo: codigo)
        .where('activo', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Código inválido o simulacro cerrado')));
      }
      return;
    }
    _iniciarSimulacro(snap.docs.first.id, snap.docs.first.data());
  }

  void _iniciarSimulacro(String id, Map<String, dynamic> data) {
    final preguntas = List<Map<String, dynamic>>.from(
        (data['preguntas'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)));
    setState(() {
      _simulacroId = id;
      _titulo = data['titulo'] as String? ?? 'Simulacro';
      _preguntas = preguntas;
      _respuestas = List.filled(preguntas.length, null);
      _preguntaActual = 0;
      _fase = _PdfFase.tomando;
    });
  }

  Future<void> _finalizar() async {
    int c = 0;
    for (int i = 0; i < _preguntas.length; i++) {
      final correcta =
          _preguntas[i]['correcta']?.toString().trim().toUpperCase() ?? '';
      final resp = _respuestas[i]?.trim().toUpperCase() ?? '';
      if (resp.startsWith(correcta)) c++;
    }
    _correctas = c;
    final pct = _preguntas.isNotEmpty
        ? (c / _preguntas.length * 100).round()
        : 0;

    try {
      await _db.collection('pdf_resultados').add({
        'simulacroId': _simulacroId,
        'titulo': _titulo,
        'userId': _user?.uid ?? '',
        'userName': _user?.displayName ?? 'Estudiante',
        'correctas': c,
        'total': _preguntas.length,
        'porcentaje': pct,
        'fechaFin': Timestamp.now(),
      });
    } catch (_) {}

    // Incrementar contador acumulativo de simulacros (para logro simulacros_10)
    final uid = _user?.uid;
    if (uid != null) {
      _db.collection('perfiles').doc(uid).set(
        {'simulacrosCompletados': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      // Actualizar ranking semanal
      final semana = _semanaActual();
      _db.collection('ranking_semanal').doc('${semana}_$uid').set({
        'semana': semana,
        'userId': uid,
        'userName': _user?.displayName ?? 'Estudiante',
        'simulacros': FieldValue.increment(1),
        'actualizadoEn': Timestamp.now(),
      }, SetOptions(merge: true));
    }

    if (mounted) setState(() => _fase = _PdfFase.resultado);
  }

  String _generarCodigo() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  String _semanaActual() {
    final hoy = DateTime.now();
    final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
    return '${lunes.year}-${lunes.month.toString().padLeft(2, '0')}-${lunes.day.toString().padLeft(2, '0')}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('PDF a Simulacro',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (_fase == _PdfFase.tomando || _fase == _PdfFase.resultado)
            TextButton(
              onPressed: () => setState(() {
                _fase = _PdfFase.lista;
                _preguntas = [];
                _respuestas = [];
              }),
              child: const Text('Salir',
                  style: TextStyle(color: Colors.white54)),
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
                  Text(_progreso,
                      style: const TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : _fase == _PdfFase.lista
              ? _buildLista()
              : _fase == _PdfFase.tomando
                  ? _buildExamen()
                  : _buildResultado(),
    );
  }

  // ── Lista ──────────────────────────────────────────────────────────────────

  Widget _buildLista() {
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
                  colors: [Color(0xFF2A1F5E), Color(0xFF1A3A2F)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Text('📄', style: TextStyle(fontSize: 32)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PDF a Simulacro',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text(
                          'Sube un examen en PDF y la IA lo convierte en test interactivo',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Docente: subir PDF
          const Text('PARA DOCENTES',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _subirPDF,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF7C6AF7).withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF7C6AF7).withValues(alpha: 0.1),
                      blurRadius: 12)
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.upload_file,
                      color: Color(0xFF7C6AF7), size: 40),
                  SizedBox(height: 10),
                  Text('Subir PDF de examen',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Máximo 5 MB · Requiere Premium ⭐',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Estudiante: unirse con código
          const Text('PARA ESTUDIANTES',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _unirseConCodigo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF5DE0C5).withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.vpn_key, color: Color(0xFF5DE0C5), size: 20),
                  SizedBox(width: 8),
                  Text('Ingresar con código de simulacro',
                      style: TextStyle(
                          color: Color(0xFF5DE0C5),
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Mis simulacros creados (docente)
          const Text('MIS SIMULACROS CREADOS',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('pdf_simulacros')
                .where('creadorId', isEqualTo: _user?.uid)
                .orderBy('creadoEn', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2A),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: Text('Aún no has creado simulacros desde PDF',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 13)),
                  ),
                );
              }
              return Column(
                children: snap.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return GestureDetector(
                    onTap: () => _iniciarSimulacro(doc.id, d),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['titulo'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                Text(
                                    '${d['totalPreguntas']} preguntas · Código: ${d['codigo']}',
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.play_arrow,
                              color: Color(0xFF7C6AF7)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Examen ─────────────────────────────────────────────────────────────────

  Widget _buildExamen() {
    if (_preguntaActual >= _preguntas.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finalizar());
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C6AF7)));
    }
    final p = _preguntas[_preguntaActual];
    final opciones = List<String>.from(p['opciones'] ?? []);
    final respActual = _respuestas[_preguntaActual];
    final progreso = (_preguntaActual + 1) / _preguntas.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(_titulo,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF7C6AF7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Text('${_preguntaActual + 1} / ${_preguntas.length}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2A),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: const Color(0xFF7C6AF7).withValues(alpha: 0.2)),
            ),
            child: Text(p['enunciado']?.toString() ?? '',
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, height: 1.5)),
          ),
          const SizedBox(height: 16),
          ...opciones.map((op) {
            final letra = op.isNotEmpty ? op.substring(0, 1) : '';
            final sel = respActual == op;
            return GestureDetector(
              onTap: () =>
                  setState(() => _respuestas[_preguntaActual] = op),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sel
                      ? const Color(0xFF7C6AF7).withValues(alpha: 0.15)
                      : const Color(0xFF1E1E2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel
                        ? const Color(0xFF7C6AF7)
                        : const Color(0xFF2E2E3E),
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF7C6AF7)
                            : const Color(0xFF0F0F14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(letra,
                            style: TextStyle(
                                color: sel ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        op.length > 2 ? op.substring(2).trim() : op,
                        style: TextStyle(
                            color: sel ? Colors.white : Colors.white70,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_preguntaActual > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _preguntaActual--),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Anterior',
                        style: TextStyle(color: Colors.white54)),
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
                            await _finalizar();
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
                        ? 'Siguiente'
                        : 'Finalizar',
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

  // ── Resultado ──────────────────────────────────────────────────────────────

  Widget _buildResultado() {
    final total = _preguntas.length;
    final pct = total > 0 ? (_correctas / total * 100).round() : 0;
    final color = pct >= 70
        ? const Color(0xFF5DE0C5)
        : pct >= 50
            ? const Color(0xFFF7A26A)
            : const Color(0xFFF7584A);
    final emoji = pct >= 70 ? '🎉' : pct >= 50 ? '👍' : '💪';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.2), const Color(0xFF0F0F14)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 8),
                Text(_titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 12),
                Text('$pct%',
                    style: TextStyle(
                        color: color,
                        fontSize: 56,
                        fontWeight: FontWeight.bold)),
                Text('$_correctas de $total correctas',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._preguntas.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final correctaLetra =
                p['correcta']?.toString().trim().toUpperCase() ?? '';
            final respLetra =
                _respuestas[i]?.trim().toUpperCase() ?? '';
            final esCorrecta = respLetra.startsWith(correctaLetra);
            final opciones = List<String>.from(p['opciones'] ?? []);
            final opCorrecta = opciones.firstWhere(
                (o) => o.toUpperCase().startsWith(correctaLetra),
                orElse: () => correctaLetra);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: esCorrecta
                        ? const Color(0xFF5DE0C5).withValues(alpha: 0.3)
                        : const Color(0xFFF7584A).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(esCorrecta ? Icons.check_circle : Icons.cancel,
                        color: esCorrecta
                            ? const Color(0xFF5DE0C5)
                            : const Color(0xFFF7584A),
                        size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('${i + 1}. ${p['enunciado']}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600))),
                  ]),
                  const SizedBox(height: 6),
                  if (!esCorrecta) ...[
                    Text('Tu resp: ${_respuestas[i] ?? 'Sin respuesta'}',
                        style: const TextStyle(
                            color: Color(0xFFF7584A), fontSize: 12)),
                    Text('Correcta: $opCorrecta',
                        style: const TextStyle(
                            color: Color(0xFF5DE0C5), fontSize: 12)),
                  ] else
                    Text('✓ ${_respuestas[i]}',
                        style: const TextStyle(
                            color: Color(0xFF5DE0C5), fontSize: 12)),
                  if ((p['explicacion'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text('💡 ${p['explicacion']}',
                        style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          // ── Botón compartir resultado ──────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final t = _preguntas.length;
                final p = t > 0 ? (_correctas / t * 100).round() : 0;
                CompartirService.mostrar(
                  context: context,
                  tarjeta: CompartirService.tarjetaResultado(
                    titulo: _titulo,
                    correctas: _correctas,
                    total: t,
                    porcentaje: p,
                    nombreUsuario:
                        _user?.displayName ?? 'Estudiante',
                  ),
                  texto:
                      '🎯 ¡Obtuve $_correctas/$t ($p%) en "$_titulo"!\n📚 @EstudiApp',
                );
              },
              icon: const Icon(Icons.share, color: Color(0xFF5DE0C5)),
              label: const Text(
                'Compartir resultado',
                style: TextStyle(
                    color: Color(0xFF5DE0C5),
                    fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF5DE0C5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() {
                _fase = _PdfFase.lista;
                _preguntas = [];
                _respuestas = [];
              }),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              label: const Text('Volver',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6AF7),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
