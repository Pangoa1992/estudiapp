import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/ia_service.dart';
import 'mixins/ia_limite_mixin.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MODELOS
// ══════════════════════════════════════════════════════════════════════════════

class PreguntaExamen {
  String tipo; // 'multiple' | 'vf' | 'desarrollo'
  String enunciado;
  List<String> opciones;
  String correcta;
  int puntaje;

  PreguntaExamen({
    this.tipo = 'multiple',
    this.enunciado = '',
    this.opciones = const ['', '', '', ''],
    this.correcta = 'A',
    this.puntaje = 1,
  });

  Map<String, dynamic> toMap() => {
        'tipo': tipo,
        'enunciado': enunciado,
        'opciones': opciones,
        'correcta': correcta,
        'puntaje': puntaje,
      };

  factory PreguntaExamen.fromMap(Map<String, dynamic> map) => PreguntaExamen(
        tipo: map['tipo'] ?? 'multiple',
        enunciado: map['enunciado'] ?? '',
        opciones: List<String>.from(map['opciones'] ?? ['', '', '', '']),
        correcta: map['correcta'] ?? 'A',
        puntaje: map['puntaje'] ?? 1,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// PÁGINA PRINCIPAL
// ══════════════════════════════════════════════════════════════════════════════

class AulaVirtualPage extends StatefulWidget {
  const AulaVirtualPage({super.key});
  @override
  State<AulaVirtualPage> createState() => _AulaVirtualPageState();
}

class _AulaVirtualPageState extends State<AulaVirtualPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        title: const Text('Aula Virtual 🏫',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: const Color(0xFF7C6AF7),
          labelColor: const Color(0xFF7C6AF7),
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: 'Docente'),
            Tab(icon: Icon(Icons.person), text: 'Estudiante'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          DocenteTab(user: _user, db: _db),
          EstudianteTab(user: _user, db: _db),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB DOCENTE
// ══════════════════════════════════════════════════════════════════════════════

class DocenteTab extends StatelessWidget {
  final User? user;
  final FirebaseFirestore db;

  const DocenteTab({super.key, required this.user, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7C6AF7),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CrearExamenPage(user: user, db: db)),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Crear examen', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('examenes_docentes')
            .where('creadorId', isEqualTo: user?.uid)
            .orderBy('creadoEn', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white38, size: 40),
                  const SizedBox(height: 12),
                  const Text('Error al cargar exámenes',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Verifica tu conexión',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF7C6AF7)));
          }
          final examenes = snap.data!.docs;
          if (examenes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📝', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Aún no has creado exámenes',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Usa el botón + para crear el primero',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: examenes.length,
            itemBuilder: (context, i) {
              final data = examenes[i].data() as Map<String, dynamic>;
              final examenId = examenes[i].id;
              final codigo = data['codigo'] ?? '------';
              final titulo = data['titulo'] ?? 'Sin título';
              final nPreguntas =
                  (data['preguntas'] as List?)?.length ?? 0;
              final activo = data['activo'] ?? true;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: activo
                        ? const Color(0xFF5DE0C5).withOpacity(0.3)
                        : Colors.white12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(titulo,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Switch(
                          value: activo,
                          activeThumbColor: const Color(0xFF5DE0C5),
                          onChanged: (v) => db
                              .collection('examenes_docentes')
                              .doc(examenId)
                              .update({'activo': v}),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('$nPreguntas preguntas',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 12),
                    // Código
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C6AF7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                const Color(0xFF7C6AF7).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.qr_code,
                              color: Color(0xFF7C6AF7), size: 16),
                          const SizedBox(width: 8),
                          Text('Código: $codigo',
                              style: const TextStyle(
                                  color: Color(0xFF7C6AF7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultadosExamenPage(
                                  examenId: examenId,
                                  titulo: titulo,
                                  db: db,
                                ),
                              ),
                            ),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF252535),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bar_chart,
                                      color: Color(0xFF4A90E2), size: 16),
                                  SizedBox(width: 6),
                                  Text('Ver resultados',
                                      style: TextStyle(
                                          color: Color(0xFF4A90E2),
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E2A),
                                title: const Text('¿Eliminar examen?',
                                    style: TextStyle(color: Colors.white)),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar',
                                          style: TextStyle(
                                              color: Colors.white38))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFF7584A)),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Eliminar',
                                        style:
                                            TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await db
                                  .collection('examenes_docentes')
                                  .doc(examenId)
                                  .delete();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7584A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: Color(0xFFF7584A), size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CREAR EXAMEN
// ══════════════════════════════════════════════════════════════════════════════

class CrearExamenPage extends StatefulWidget {
  final User? user;
  final FirebaseFirestore db;
  const CrearExamenPage({super.key, required this.user, required this.db});

  @override
  State<CrearExamenPage> createState() => _CrearExamenPageState();
}

class _CrearExamenPageState extends State<CrearExamenPage>
    with IaLimiteMixin<CrearExamenPage> {
  final _tituloCtrl = TextEditingController();
  final _temaIACtrl = TextEditingController();
  List<PreguntaExamen> _preguntas = [];
  bool _guardando = false;
  bool _generandoIA = false;

  @override
  void initState() {
    super.initState();
    initIaLimite();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _temaIACtrl.dispose();
    disposeIaLimite();
    super.dispose();
  }

  String _generarCodigo() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _guardarExamen() async {
    if (_tituloCtrl.text.trim().isEmpty || _preguntas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Agrega un título y al menos una pregunta'),
            backgroundColor: Color(0xFF1E1E2A)),
      );
      return;
    }
    setState(() => _guardando = true);
    final puntajeTotal =
        _preguntas.fold<int>(0, (s, p) => s + p.puntaje);
    await widget.db.collection('examenes_docentes').add({
      'titulo': _tituloCtrl.text.trim(),
      'creadorId': widget.user?.uid,
      'creadorNombre': widget.user?.displayName ?? 'Docente',
      'codigo': _generarCodigo(),
      'preguntas': _preguntas.map((p) => p.toMap()).toList(),
      'puntajeTotal': puntajeTotal,
      'activo': true,
      'creadoEn': Timestamp.now(),
    });
    if (mounted) Navigator.pop(context);
  }

  Future<void> _generarConIA() async {
    final tema = _temaIACtrl.text.trim();
    if (tema.isEmpty) return;
    if (!await verificarYConsumir()) return; // ── LÍMITE DIARIO
    setState(() => _generandoIA = true);

    final prompt = '''
Genera 5 preguntas de examen sobre "$tema" para estudiantes universitarios.
Incluye: 3 de opción múltiple (A, B, C, D), 2 de verdadero/falso.
Responde SOLO con JSON válido:
{
  "preguntas": [
    {"tipo": "multiple", "enunciado": "pregunta?", "opciones": ["A. op1", "B. op2", "C. op3", "D. op4"], "correcta": "A", "puntaje": 2},
    {"tipo": "vf", "enunciado": "afirmación", "opciones": ["V", "F"], "correcta": "V", "puntaje": 1}
  ]
}
Todo en español.
''';

    final json = await IAService.llamarJSON(prompt);
    if (json != null && json['preguntas'] != null && mounted) {
      final nuevas = List<Map<String, dynamic>>.from(json['preguntas'])
          .map((m) => PreguntaExamen.fromMap(m))
          .toList();
      setState(() {
        _preguntas.addAll(nuevas);
        _generandoIA = false;
      });
    } else {
      if (mounted) setState(() => _generandoIA = false);
    }
  }

  void _agregarPreguntaManual() {
    setState(() => _preguntas.add(PreguntaExamen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        title: const Text('Crear Examen',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _guardando ? null : _guardarExamen,
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF7C6AF7)))
                : const Text('Guardar',
                    style: TextStyle(
                        color: Color(0xFF7C6AF7), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _campo('Título del examen', _tituloCtrl,
                hint: 'Ej: Examen Parcial — Cálculo I'),
            const SizedBox(height: 16),

            // Generar con IA
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF7C6AF7).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Generar preguntas con IA',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _temaIACtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Ej: Álgebra lineal, Derecho civil',
                            hintStyle: TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Color(0xFF252535),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide.none),
                            contentPadding: EdgeInsets.all(10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _generandoIA ? null : _generarConIA,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C6AF7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _generandoIA
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_preguntas.length} preguntas',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                GestureDetector(
                  onTap: _agregarPreguntaManual,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C6AF7).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: Color(0xFF7C6AF7), size: 16),
                        SizedBox(width: 4),
                        Text('Agregar manual',
                            style: TextStyle(
                                color: Color(0xFF7C6AF7), fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(
              _preguntas.length,
              (i) => _PreguntaEditor(
                pregunta: _preguntas[i],
                numero: i + 1,
                onDelete: () => setState(() => _preguntas.removeAt(i)),
                onChanged: () => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl, {String hint = ''}) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFF7C6AF7)),
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1E1E2A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _PreguntaEditor extends StatefulWidget {
  final PreguntaExamen pregunta;
  final int numero;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  const _PreguntaEditor(
      {required this.pregunta,
      required this.numero,
      required this.onDelete,
      required this.onChanged});

  @override
  State<_PreguntaEditor> createState() => _PreguntaEditorState();
}

class _PreguntaEditorState extends State<_PreguntaEditor> {
  bool _expandido = true;

  @override
  Widget build(BuildContext context) {
    final p = widget.pregunta;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E3E)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expandido = !_expandido),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C6AF7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text('${widget.numero}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.enunciado.isNotEmpty ? p.enunciado : 'Sin enunciado',
                      style: TextStyle(
                          color: p.enunciado.isNotEmpty
                              ? Colors.white
                              : Colors.white38,
                          fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252535),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(p.tipo.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 9)),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: const Icon(Icons.close,
                        color: Colors.white24, size: 18),
                  ),
                ],
              ),
            ),
          ),
          if (_expandido) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo
                  Row(
                    children: [
                      _tipoBtn('multiple', 'Múltiple', p),
                      const SizedBox(width: 6),
                      _tipoBtn('vf', 'V / F', p),
                      const SizedBox(width: 6),
                      _tipoBtn('desarrollo', 'Desarrollo', p),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Enunciado
                  TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    controller: TextEditingController(text: p.enunciado)
                      ..selection = TextSelection.collapsed(
                          offset: p.enunciado.length),
                    maxLines: 3,
                    onChanged: (v) {
                      p.enunciado = v;
                      widget.onChanged();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Escribe la pregunta...',
                      hintStyle:
                          TextStyle(color: Colors.white38, fontSize: 13),
                      filled: true,
                      fillColor: Color(0xFF252535),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Opciones
                  if (p.tipo == 'multiple') ...[
                    const Text('Opciones:',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 4),
                    ...List.generate(p.opciones.length, (oi) {
                      final letra = ['A', 'B', 'C', 'D'][oi];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                p.correcta = letra;
                                widget.onChanged();
                                setState(() {});
                              },
                              child: Container(
                                width: 26,
                                height: 26,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: p.correcta == letra
                                      ? const Color(0xFF5DE0C5)
                                      : const Color(0xFF252535),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(letra,
                                      style: TextStyle(
                                          color: p.correcta == letra
                                              ? Colors.black
                                              : Colors.white54,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)),
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                                controller: TextEditingController(
                                    text: p.opciones[oi])
                                  ..selection = TextSelection.collapsed(
                                      offset: p.opciones[oi].length),
                                onChanged: (v) {
                                  p.opciones[oi] = v;
                                  widget.onChanged();
                                },
                                decoration: InputDecoration(
                                  hintText: 'Opción $letra',
                                  hintStyle: const TextStyle(
                                      color: Colors.white24, fontSize: 12),
                                  filled: true,
                                  fillColor: const Color(0xFF252535),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (p.tipo == 'vf') ...[
                    Row(
                      children: [
                        _vfBtn('V', p),
                        const SizedBox(width: 8),
                        _vfBtn('F', p),
                      ],
                    ),
                  ],
                  if (p.tipo == 'desarrollo')
                    const Text(
                        'Las respuestas de desarrollo requieren revisión manual.',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Puntaje:',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(width: 8),
                      ...List.generate(5, (pi) {
                        final val = pi + 1;
                        return GestureDetector(
                          onTap: () {
                            p.puntaje = val;
                            widget.onChanged();
                            setState(() {});
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: p.puntaje == val
                                  ? const Color(0xFF7C6AF7)
                                  : const Color(0xFF252535),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text('$val',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11)),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tipoBtn(String tipo, String label, PreguntaExamen p) {
    final sel = p.tipo == tipo;
    return GestureDetector(
      onTap: () {
        p.tipo = tipo;
        if (tipo == 'vf') {
          p.opciones = ['V', 'F'];
          p.correcta = 'V';
        } else if (tipo == 'multiple') {
          p.opciones = ['', '', '', ''];
          p.correcta = 'A';
        }
        widget.onChanged();
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: sel
              ? const Color(0xFF7C6AF7)
              : const Color(0xFF252535),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? Colors.white : Colors.white54, fontSize: 11)),
      ),
    );
  }

  Widget _vfBtn(String val, PreguntaExamen p) {
    final sel = p.correcta == val;
    return GestureDetector(
      onTap: () {
        p.correcta = val;
        widget.onChanged();
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: sel
              ? (val == 'V'
                  ? const Color(0xFF5DE0C5)
                  : const Color(0xFFF7584A))
              : const Color(0xFF252535),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(val == 'V' ? '✓ Verdadero' : '✗ Falso',
            style: TextStyle(
                color: sel ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// RESULTADOS DEL EXAMEN (vista docente)
// ══════════════════════════════════════════════════════════════════════════════

class ResultadosExamenPage extends StatelessWidget {
  final String examenId;
  final String titulo;
  final FirebaseFirestore db;

  const ResultadosExamenPage(
      {super.key,
      required this.examenId,
      required this.titulo,
      required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        title: Text(titulo,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('sesiones_examen')
            .where('examenId', isEqualTo: examenId)
            .where('completado', isEqualTo: true)
            .orderBy('puntuacion', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text('Error al cargar resultados',
                  style: TextStyle(color: Colors.white38)),
            );
          }
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF7C6AF7)));
          }
          final sesiones = snap.data!.docs;
          if (sesiones.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('⏳', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Aún no hay respuestas',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Comparte el código con tus estudiantes',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            );
          }

          double promedio = 0;
          for (final s in sesiones) {
            final data = s.data() as Map<String, dynamic>;
            final max = data['puntajeMaximo'] as int? ?? 1;
            final obt = data['puntuacion'] as int? ?? 0;
            promedio += max > 0 ? obt / max * 100 : 0;
          }
          promedio /= sesiones.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Resumen
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('Participantes', '${sesiones.length}',
                        const Color(0xFF7C6AF7)),
                    _stat('Promedio', '${promedio.toStringAsFixed(0)}%',
                        _colorPromedio(promedio)),
                    _stat('Aprobados',
                        '${sesiones.where((s) {
                          final d = s.data() as Map<String, dynamic>;
                          final max = d['puntajeMaximo'] as int? ?? 1;
                          final obt = d['puntuacion'] as int? ?? 0;
                          return max > 0 && obt / max >= 0.6;
                        }).length}',
                        const Color(0xFF5DE0C5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('RANKING',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 10),
              ...sesiones.asMap().entries.map((entry) {
                final i = entry.key;
                final data =
                    entry.value.data() as Map<String, dynamic>;
                final nombre =
                    data['estudianteNombre'] ?? 'Estudiante';
                final puntaje = data['puntuacion'] as int? ?? 0;
                final max = data['puntajeMaximo'] as int? ?? 1;
                final pct = max > 0 ? puntaje / max * 100 : 0.0;
                final medalla = i == 0
                    ? '🥇'
                    : i == 1
                        ? '🥈'
                        : i == 2
                            ? '🥉'
                            : '${i + 1}.';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: i < 3
                            ? const Color(0xFFFFD700).withOpacity(0.2)
                            : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 32,
                          child: Text(medalla,
                              style: const TextStyle(fontSize: 16))),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombre,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            Text('$puntaje / $max pts',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      Text('${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: _colorPromedio(pct.toDouble()),
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Color _colorPromedio(double p) {
    if (p >= 80) return const Color(0xFF5DE0C5);
    if (p >= 60) return const Color(0xFF4A90E2);
    if (p >= 40) return const Color(0xFFF7A26A);
    return const Color(0xFFF7584A);
  }

  Widget _stat(String label, String valor, Color color) {
    return Column(
      children: [
        Text(valor,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB ESTUDIANTE
// ══════════════════════════════════════════════════════════════════════════════

class EstudianteTab extends StatefulWidget {
  final User? user;
  final FirebaseFirestore db;
  const EstudianteTab({super.key, required this.user, required this.db});

  @override
  State<EstudianteTab> createState() => _EstudianteTabState();
}

class _EstudianteTabState extends State<EstudianteTab> {
  final _codigoCtrl = TextEditingController();
  bool _buscando = false;
  String _error = '';

  Future<void> _buscarExamen() async {
    final codigo = _codigoCtrl.text.trim().toUpperCase();
    if (codigo.length < 4) return;
    setState(() {
      _buscando = true;
      _error = '';
    });

    final snap = await widget.db
        .collection('examenes_docentes')
        .where('codigo', isEqualTo: codigo)
        .where('activo', isEqualTo: true)
        .limit(1)
        .get();

    if (!mounted) return;

    if (snap.docs.isEmpty) {
      setState(() {
        _error = 'Código no encontrado o examen inactivo.';
        _buscando = false;
      });
      return;
    }

    final doc = snap.docs.first;
    setState(() => _buscando = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TomarExamenPage(
          examenId: doc.id,
          data: doc.data(),
          user: widget.user,
          db: widget.db,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A40), Color(0xFF0F1A20)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Text('🎓', style: TextStyle(fontSize: 36)),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tomar un examen',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text('Ingresa el código que te dio tu docente',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _codigoCtrl,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4),
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: const InputDecoration(
              hintText: 'CÓDIGO',
              hintStyle: TextStyle(color: Colors.white24, fontSize: 20),
              counterText: '',
              filled: true,
              fillColor: Color(0xFF1E1E2A),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide:
                      BorderSide(color: Color(0xFF7C6AF7), width: 2)),
              contentPadding: EdgeInsets.symmetric(vertical: 20),
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_error, style: const TextStyle(color: Color(0xFFF7584A))),
          ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _buscando ? null : _buscarExamen,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7C6AF7), Color(0xFF5A4ED4)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _buscando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ingresar al examen',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('MIS RESULTADOS',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.db
                  .collection('sesiones_examen')
                  .where('estudianteId', isEqualTo: widget.user?.uid)
                  .where('completado', isEqualTo: true)
                  .orderBy('finalizadoEn', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                    child: Text('Error al cargar resultados',
                        style: TextStyle(color: Colors.white38)),
                  );
                }
                final sesiones = snap.data?.docs ?? [];
                if (sesiones.isEmpty) {
                  return const Center(
                    child: Text('Aún no has tomado ningún examen',
                        style: TextStyle(color: Colors.white38)),
                  );
                }
                return ListView.builder(
                  itemCount: sesiones.length,
                  itemBuilder: (context, i) {
                    final data =
                        sesiones[i].data() as Map<String, dynamic>;
                    final titulo =
                        data['examenTitulo'] ?? 'Examen';
                    final puntaje = data['puntuacion'] as int? ?? 0;
                    final max = data['puntajeMaximo'] as int? ?? 1;
                    final pct = max > 0 ? puntaje / max * 100 : 0.0;
                    final color = pct >= 80
                        ? const Color(0xFF5DE0C5)
                        : pct >= 60
                            ? const Color(0xFF4A90E2)
                            : pct >= 40
                                ? const Color(0xFFF7A26A)
                                : const Color(0xFFF7584A);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(titulo,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                                Text('$puntaje / $max puntos',
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('${pct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TOMAR EXAMEN (vista estudiante)
// ══════════════════════════════════════════════════════════════════════════════

class TomarExamenPage extends StatefulWidget {
  final String examenId;
  final Map<String, dynamic> data;
  final User? user;
  final FirebaseFirestore db;

  const TomarExamenPage(
      {super.key,
      required this.examenId,
      required this.data,
      required this.user,
      required this.db});

  @override
  State<TomarExamenPage> createState() => _TomarExamenPageState();
}

class _TomarExamenPageState extends State<TomarExamenPage> {
  late List<PreguntaExamen> _preguntas;
  late List<String?> _respuestas;
  int _actual = 0;
  bool _entregado = false;
  int _puntajeObtenido = 0;
  int _puntajeMax = 0;

  @override
  void initState() {
    super.initState();
    _preguntas = List<Map<String, dynamic>>.from(
            widget.data['preguntas'] ?? [])
        .map((m) => PreguntaExamen.fromMap(m))
        .toList();
    _respuestas = List.filled(_preguntas.length, null);
    _puntajeMax =
        _preguntas.fold<int>(0, (s, p) => s + p.puntaje);
  }

  void _responder(String respuesta) =>
      setState(() => _respuestas[_actual] = respuesta);

  Future<void> _entregar() async {
    int pts = 0;
    for (int i = 0; i < _preguntas.length; i++) {
      final p = _preguntas[i];
      final r = _respuestas[i];
      if (p.tipo != 'desarrollo' &&
          r != null &&
          r.toUpperCase().startsWith(p.correcta.toUpperCase())) {
        pts += p.puntaje;
      }
    }
    setState(() {
      _puntajeObtenido = pts;
      _entregado = true;
    });

    await widget.db.collection('sesiones_examen').add({
      'examenId': widget.examenId,
      'examenTitulo': widget.data['titulo'] ?? '',
      'estudianteId': widget.user?.uid,
      'estudianteNombre': widget.user?.displayName ?? 'Estudiante',
      'estudianteEmail': widget.user?.email ?? '',
      'respuestas': _respuestas,
      'puntuacion': pts,
      'puntajeMaximo': _puntajeMax,
      'completado': true,
      'finalizadoEn': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_entregado) return _buildResultado();

    final pregunta = _preguntas[_actual];
    final progreso = (_actual + 1) / _preguntas.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        title: Text(widget.data['titulo'] ?? 'Examen',
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E2A),
                  title: const Text('¿Entregar examen?',
                      style: TextStyle(color: Colors.white)),
                  content: Text(
                      'Respondiste ${_respuestas.where((r) => r != null).length} de ${_preguntas.length} preguntas.',
                      style: const TextStyle(color: Colors.white54)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar',
                            style: TextStyle(color: Colors.white38))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5DE0C5)),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Entregar',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              );
              if (ok == true) _entregar();
            },
            child: const Text('Entregar',
                style: TextStyle(
                    color: Color(0xFF5DE0C5),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progreso,
            backgroundColor: const Color(0xFF1E1E2A),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF7C6AF7)),
            minHeight: 3,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pregunta ${_actual + 1} de ${_preguntas.length}  ·  ${pregunta.puntaje} pts',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      pregunta.enunciado,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (pregunta.tipo == 'multiple')
                    ...pregunta.opciones.asMap().entries.map((e) {
                      final letra = ['A', 'B', 'C', 'D'][e.key];
                      final sel = _respuestas[_actual] == letra;
                      return GestureDetector(
                        onTap: () => _responder(letra),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFF7C6AF7).withOpacity(0.2)
                                : const Color(0xFF1E1E2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: sel
                                    ? const Color(0xFF7C6AF7)
                                    : const Color(0xFF2E2E3E),
                                width: sel ? 2 : 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: sel
                                      ? const Color(0xFF7C6AF7)
                                      : const Color(0xFF252535),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(letra,
                                      style: TextStyle(
                                          color: sel
                                              ? Colors.white
                                              : Colors.white54,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.value.length > 2
                                      ? e.value.substring(2).trim()
                                      : e.value,
                                  style: TextStyle(
                                      color: sel
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  if (pregunta.tipo == 'vf')
                    Row(
                      children: [
                        _vfBtn('V', '✓ Verdadero', const Color(0xFF5DE0C5)),
                        const SizedBox(width: 10),
                        _vfBtn('F', '✗ Falso', const Color(0xFFF7584A)),
                      ],
                    ),
                  if (pregunta.tipo == 'desarrollo') ...[
                    TextField(
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 5,
                      onChanged: (v) => _responder(v),
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu respuesta aquí...',
                        hintStyle:
                            TextStyle(color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: Color(0xFF1E1E2A),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_actual > 0)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _actual--),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('← Anterior',
                              style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                    ),
                  ),
                if (_actual > 0) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _actual < _preguntas.length - 1
                        ? () => setState(() => _actual++)
                        : _entregar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF7C6AF7), Color(0xFF5A4ED4)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _actual < _preguntas.length - 1
                              ? 'Siguiente →'
                              : 'Entregar examen',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vfBtn(String val, String label, Color color) {
    final sel = _respuestas[_actual] == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => _responder(val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: sel ? color.withOpacity(0.2) : const Color(0xFF1E1E2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: sel ? color : const Color(0xFF2E2E3E),
                width: sel ? 2 : 1),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: sel ? color : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
        ),
      ),
    );
  }

  Widget _buildResultado() {
    final pct = _puntajeMax > 0
        ? _puntajeObtenido / _puntajeMax * 100
        : 0.0;
    final color = pct >= 80
        ? const Color(0xFF5DE0C5)
        : pct >= 60
            ? const Color(0xFF4A90E2)
            : pct >= 40
                ? const Color(0xFFF7A26A)
                : const Color(0xFFF7584A);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(pct >= 80 ? '🎉' : pct >= 60 ? '👍' : '💪',
                  style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text('${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: color,
                      fontSize: 48,
                      fontWeight: FontWeight.bold)),
              Text('$_puntajeObtenido de $_puntajeMax puntos',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 16)),
              const SizedBox(height: 32),
              // Revisión pregunta por pregunta
              ...List.generate(_preguntas.length, (i) {
                final p = _preguntas[i];
                final r = _respuestas[i];
                final esCorrecta = p.tipo == 'desarrollo'
                    ? null
                    : r != null &&
                        r.toUpperCase().startsWith(p.correcta.toUpperCase());
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: esCorrecta == null
                            ? Colors.white12
                            : esCorrecta == true
                                ? const Color(0xFF5DE0C5).withOpacity(0.3)
                                : const Color(0xFFF7584A).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            esCorrecta == null
                                ? Icons.info_outline
                                : esCorrecta == true
                                    ? Icons.check_circle
                                    : Icons.cancel,
                            color: esCorrecta == null
                                ? Colors.white38
                                : esCorrecta == true
                                    ? const Color(0xFF5DE0C5)
                                    : const Color(0xFFF7584A),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('${i + 1}. ${p.enunciado}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      if (esCorrecta == false) ...[
                        const SizedBox(height: 4),
                        Text('Tu respuesta: $r',
                            style: const TextStyle(
                                color: Color(0xFFF7584A), fontSize: 12)),
                        Text('Correcta: ${p.correcta}',
                            style: const TextStyle(
                                color: Color(0xFF5DE0C5), fontSize: 12)),
                      ],
                      if (p.tipo == 'desarrollo')
                        const Text('Requiere revisión del docente',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7C6AF7), Color(0xFF5A4ED4)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('Volver',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
