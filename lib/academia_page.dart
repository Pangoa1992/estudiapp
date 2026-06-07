import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Academia Page ────────────────────────────────────────────────────────────
class AcademiaPage extends StatefulWidget {
  const AcademiaPage({super.key});
  @override
  State<AcademiaPage> createState() => _AcademiaPageState();
}

class _AcademiaPageState extends State<AcademiaPage>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;
  TabController? _tab;
  bool _loading = true;

  // Docente state
  Map<String, dynamic>? _academia;
  String? _academiaId;

  // Alumno state
  List<Map<String, dynamic>> _misAcademias = [];

  bool get _esDocente => _academia != null;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _tab?.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final uid = _user?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final snap = await _db
          .collection('academias')
          .where('docenteId', isEqualTo: uid)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        _academiaId = snap.docs.first.id;
        _academia = snap.docs.first.data();
        _tab = TabController(length: 3, vsync: this);
      } else {
        try {
          final alumSnap = await _db
              .collectionGroup('miembros')
              .where('alumnoId', isEqualTo: uid)
              .get();
          for (final d in alumSnap.docs) {
            final acadId = d.reference.parent.parent?.id;
            if (acadId == null) continue;
            final acadDoc = await _db.collection('academias').doc(acadId).get();
            if (acadDoc.exists && acadDoc.data() != null) {
              _misAcademias.add({'id': acadId, ...acadDoc.data()!});
            }
          }
        } catch (_) {
          // collectionGroup requires a Firestore index — gracefully skip if missing
        }
      }
    } catch (_) {
      // Firestore permission or network error — show empty state
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Mi Academia',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: _esDocente && _tab != null
            ? TabBar(
                controller: _tab,
                indicatorColor: const Color(0xFF7C6AF7),
                labelColor: const Color(0xFF7C6AF7),
                unselectedLabelColor: Colors.white38,
                tabs: const [
                  Tab(text: 'Alumnos'),
                  Tab(text: 'Exámenes'),
                  Tab(text: 'Progreso'),
                ],
              )
            : null,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C6AF7)))
          : _esDocente
              ? TabBarView(
                  controller: _tab!,
                  children: [
                    _AlumnosTab(academiaId: _academiaId!),
                    _ExamenesTab(
                        academiaId: _academiaId!, academia: _academia!),
                    _ProgresoTab(academiaId: _academiaId!),
                  ],
                )
              : _buildVistaEstudiante(),
      floatingActionButton: !_esDocente
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF7C6AF7),
              onPressed: () async {
                await _mostrarDialogoUnirse();
                _loading = true;
                setState(() {});
                await _cargar();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label:
                  const Text('Unirme', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  // ── Vista inicial (sin academia de docente) ──────────────────────────────

  Widget _buildVistaEstudiante() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crear academia como docente
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF2A1F5E), Color(0xFF1A3A2F)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¿Eres docente?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Crea tu academia, agrega alumnos y gestiona exámenes',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _mostrarCrearAcademia();
                      _loading = true;
                      setState(() {});
                      await _cargar();
                    },
                    icon: const Icon(Icons.school, color: Colors.white),
                    label: const Text('Crear mi Academia',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6AF7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Academias donde es alumno
          if (_misAcademias.isNotEmpty) ...[
            const Text('MIS ACADEMIAS',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            ..._misAcademias.map((a) => _AcademiaCard(academia: a)),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Text('🏫', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 10),
                    Text('No estás en ninguna academia',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Usa el código que te dio tu docente',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────

  Future<void> _mostrarCrearAcademia() async {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Crear Academia',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nombreCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('Nombre de la academia', 'Ej: Academia de Matemáticas'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: _inputDeco('Descripción (opcional)', 'Ej: Para estudiantes de 5to año'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nombreCtrl.text.trim().isEmpty) return;
                  await _crearAcademia(
                      nombreCtrl.text.trim(), descCtrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6AF7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Crear',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _crearAcademia(String nombre, String descripcion) async {
    final user = _user;
    if (user == null) return;
    final codigo = _generarCodigo();
    final ref = await _db.collection('academias').add({
      'nombre': nombre,
      'descripcion': descripcion,
      'docenteId': user.uid,
      'docenteEmail': user.email ?? '',
      'docenteNombre': user.displayName ?? 'Docente',
      'codigo': codigo,
      'creadoEn': Timestamp.now(),
    });
    _academiaId = ref.id;
    _academia = {
      'nombre': nombre,
      'descripcion': descripcion,
      'docenteId': user.uid,
      'docenteEmail': user.email ?? '',
      'docenteNombre': user.displayName ?? 'Docente',
      'codigo': codigo,
    };
    _tab = TabController(length: 3, vsync: this);
  }

  Future<void> _mostrarDialogoUnirse() async {
    final codigoCtrl = TextEditingController();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        title: const Text('Unirme a una Academia',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: codigoCtrl,
          style: const TextStyle(
              color: Colors.white,
              letterSpacing: 4,
              fontWeight: FontWeight.bold),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          decoration: _inputDeco('Código de 6 caracteres', 'ABC123'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6AF7)),
            onPressed: () async {
              final codigo = codigoCtrl.text.trim().toUpperCase();
              if (codigo.length != 6) return;
              final ok = await _unirseAcademia(codigo);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok
                      ? '¡Te uniste a la academia!'
                      : 'Código inválido. Intenta de nuevo.'),
                  backgroundColor:
                      ok ? const Color(0xFF5DE0C5) : Colors.redAccent,
                ));
              }
            },
            child: const Text('Unirme',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool> _unirseAcademia(String codigo) async {
    final user = _user;
    if (user == null) return false;
    try {
      final snap = await _db
          .collection('academias')
          .where('codigo', isEqualTo: codigo)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return false;
      final acadId = snap.docs.first.id;
      await _db
          .collection('academias')
          .doc(acadId)
          .collection('miembros')
          .doc(user.uid)
          .set({
        'alumnoId': user.uid,
        'alumnoNombre': user.displayName ?? 'Estudiante',
        'alumnoEmail': user.email ?? '',
        'alumnoFoto': user.photoURL ?? '',
        'unidoEn': Timestamp.now(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  String _generarCodigo() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  InputDecoration _inputDeco(String label, String hint) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7C6AF7)),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF0F0F14),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        counterStyle: const TextStyle(color: Colors.white38),
      );
}

// ── Card para academia (vista alumno) ────────────────────────────────────────
class _AcademiaCard extends StatelessWidget {
  final Map<String, dynamic> academia;
  const _AcademiaCard({required this.academia});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7C6AF7).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C6AF7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text('🏫', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(academia['nombre'] ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text('Docente: ${academia['docenteNombre'] ?? ''}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          if ((academia['descripcion'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(academia['descripcion'],
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

// ── Alumnos Tab ──────────────────────────────────────────────────────────────
class _AlumnosTab extends StatefulWidget {
  final String academiaId;
  const _AlumnosTab({required this.academiaId});
  @override
  State<_AlumnosTab> createState() => _AlumnosTabState();
}

class _AlumnosTabState extends State<_AlumnosTab> {
  final _db = FirebaseFirestore.instance;

  Future<void> _copiarCodigo(String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Código copiado al portapapeles'),
        backgroundColor: Color(0xFF7C6AF7),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('academias').doc(widget.academiaId).snapshots(),
      builder: (context, acadSnap) {
        final acadData = acadSnap.data?.data() as Map<String, dynamic>?;
        final codigo = acadData?['codigo'] as String? ?? '';
        return Column(
          children: [
            // Código de acceso
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF2A1F5E), Color(0xFF1A2A3E)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text('Código de acceso para alumnos',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(codigo,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8)),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _copiarCodigo(codigo),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C6AF7).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.copy,
                              color: Color(0xFF7C6AF7), size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Lista de alumnos
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('academias')
                    .doc(widget.academiaId)
                    .collection('miembros')
                    .orderBy('unidoEn')
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('👩‍🎓', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('Aún no hay alumnos inscritos',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 14)),
                          SizedBox(height: 4),
                          Text('Comparte el código con tus estudiantes',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: snap.data!.docs.length,
                    itemBuilder: (context, i) {
                      final d =
                          snap.data!.docs[i].data() as Map<String, dynamic>;
                      final nombre = d['alumnoNombre'] as String? ?? 'Alumno';
                      final email = d['alumnoEmail'] as String? ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF7C6AF7),
                              child: Text(
                                nombre.isNotEmpty
                                    ? nombre[0].toUpperCase()
                                    : 'A',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nombre,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  Text(email,
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Exámenes Tab ─────────────────────────────────────────────────────────────
class _ExamenesTab extends StatelessWidget {
  final String academiaId;
  final Map<String, dynamic> academia;
  const _ExamenesTab(
      {required this.academiaId, required this.academia});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _CrearExamenAcademiaPage(
                    academiaId: academiaId,
                    academiaNombre: academia['nombre'] ?? 'Academia',
                  ),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Crear nuevo examen',
                  style:
                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6AF7),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: db
                .collection('examenes_docentes')
                .where('academiaId', isEqualTo: academiaId)
                .where('creadorId', isEqualTo: user?.uid)
                .orderBy('creadoEn', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Aún no has creado exámenes para esta academia',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, i) {
                  final d =
                      snap.data!.docs[i].data() as Map<String, dynamic>;
                  final codigo = d['codigo'] as String? ?? '';
                  final preguntas =
                      (d['preguntas'] as List?)?.length ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF7C6AF7).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d['titulo'] ?? 'Examen',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('$preguntas preguntas · Código: $codigo',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: d['activo'] == true
                                ? const Color(0xFF5DE0C5).withValues(alpha: 0.15)
                                : Colors.white12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            d['activo'] == true ? 'Activo' : 'Cerrado',
                            style: TextStyle(
                              color: d['activo'] == true
                                  ? const Color(0xFF5DE0C5)
                                  : Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Crear Examen (academia) ───────────────────────────────────────────────────
class _CrearExamenAcademiaPage extends StatefulWidget {
  final String academiaId;
  final String academiaNombre;
  const _CrearExamenAcademiaPage(
      {required this.academiaId, required this.academiaNombre});
  @override
  State<_CrearExamenAcademiaPage> createState() =>
      _CrearExamenAcademiaPageState();
}

class _CrearExamenAcademiaPageState extends State<_CrearExamenAcademiaPage> {
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;
  final _tituloCtrl = TextEditingController();
  bool _guardando = false;
  final List<_PreguntaSimple> _preguntas = [];

  Future<void> _guardar() async {
    if (_tituloCtrl.text.trim().isEmpty || _preguntas.isEmpty) return;
    setState(() => _guardando = true);
    final codigo = _genCodigo();
    final prData = _preguntas
        .map((p) => {
              'tipo': p.tipo,
              'enunciado': p.enunciado,
              'opciones': p.opciones,
              'correcta': p.correcta,
              'puntaje': p.puntaje,
            })
        .toList();
    final total =
        _preguntas.fold<int>(0, (sum, p) => sum + p.puntaje);
    await _db.collection('examenes_docentes').add({
      'titulo': _tituloCtrl.text.trim(),
      'creadorId': _user?.uid,
      'creadorNombre': _user?.displayName ?? 'Docente',
      'academiaId': widget.academiaId,
      'academiaNombre': widget.academiaNombre,
      'codigo': codigo,
      'preguntas': prData,
      'puntajeTotal': total,
      'activo': true,
      'creadoEn': Timestamp.now(),
    });
    if (mounted) Navigator.pop(context);
  }

  String _genCodigo() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Crear Examen',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Guardar',
                    style: TextStyle(color: Color(0xFF7C6AF7))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _tituloCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Título del examen',
                labelStyle: const TextStyle(color: Color(0xFF7C6AF7)),
                filled: true,
                fillColor: const Color(0xFF1E1E2A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            ..._preguntas.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
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
                          Text('${i + 1}. ${p.enunciado}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                          Text(
                              p.tipo == 'mc'
                                  ? 'Múltiple: ${p.correcta}'
                                  : 'V/F: ${p.correcta}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white38, size: 18),
                      onPressed: () => setState(() => _preguntas.removeAt(i)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _mostrarAgregarPregunta,
              icon: const Icon(Icons.add, color: Color(0xFF7C6AF7)),
              label: const Text('Agregar pregunta',
                  style: TextStyle(color: Color(0xFF7C6AF7))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF7C6AF7)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarAgregarPregunta() async {
    final enCtrl = TextEditingController();
    String tipo = 'mc';
    final opCtrls = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];
    String correcta = 'A';
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nueva Pregunta',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // Tipo
                Row(
                  children: [
                    _chipTipo(ctx, setM, 'mc', 'Opción múltiple', tipo,
                        (v) => setM(() => tipo = v)),
                    const SizedBox(width: 8),
                    _chipTipo(ctx, setM, 'vf', 'Verdadero/Falso', tipo,
                        (v) => setM(() => tipo = v)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: enCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: _inputDeco('Enunciado de la pregunta', ''),
                ),
                const SizedBox(height: 12),
                if (tipo == 'mc') ...[
                  for (int i = 0; i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: opCtrls[i],
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco(
                            'Opción ${['A', 'B', 'C', 'D'][i]}', ''),
                      ),
                    ),
                  const Text('Respuesta correcta:',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['A', 'B', 'C', 'D']
                        .map((l) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setM(() => correcta = l),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: correcta == l
                                        ? const Color(0xFF7C6AF7)
                                        : const Color(0xFF0F0F14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(l,
                                        style: TextStyle(
                                            color: correcta == l
                                                ? Colors.white
                                                : Colors.white38,
                                            fontWeight:
                                                FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ] else ...[
                  const Text('Respuesta correcta:',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['Verdadero', 'Falso']
                        .map((l) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setM(() => correcta = l),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: correcta == l
                                        ? const Color(0xFF7C6AF7)
                                        : const Color(0xFF0F0F14),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(l,
                                      style: TextStyle(
                                          color: correcta == l
                                              ? Colors.white
                                              : Colors.white38)),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (enCtrl.text.trim().isEmpty) return;
                      final opciones = tipo == 'mc'
                          ? opCtrls.map((c) => c.text.trim()).toList()
                          : ['Verdadero', 'Falso'];
                      setState(() => _preguntas.add(_PreguntaSimple(
                            tipo: tipo,
                            enunciado: enCtrl.text.trim(),
                            opciones: opciones,
                            correcta: correcta,
                            puntaje: 1,
                          )));
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6AF7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Agregar',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipTipo(BuildContext ctx, StateSetter setM, String val,
      String label, String current, Function(String) onTap) {
    final sel = current == val;
    return GestureDetector(
      onTap: () => onTap(val),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF7C6AF7) : const Color(0xFF0F0F14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? Colors.white : Colors.white54,
                fontSize: 12)),
      ),
    );
  }

  InputDecoration _inputDeco(String label, String hint) => InputDecoration(
        labelText: label.isEmpty ? null : label,
        labelStyle: const TextStyle(color: Color(0xFF7C6AF7)),
        hintText: hint.isEmpty ? null : hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF0F0F14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      );
}

class _PreguntaSimple {
  final String tipo;
  final String enunciado;
  final List<String> opciones;
  final String correcta;
  final int puntaje;
  const _PreguntaSimple({
    required this.tipo,
    required this.enunciado,
    required this.opciones,
    required this.correcta,
    required this.puntaje,
  });
}

// ── Progreso Tab ─────────────────────────────────────────────────────────────
class _ProgresoTab extends StatelessWidget {
  final String academiaId;
  const _ProgresoTab({required this.academiaId});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('academias')
          .doc(academiaId)
          .collection('miembros')
          .orderBy('unidoEn')
          .snapshots(),
      builder: (context, alumSnap) {
        if (!alumSnap.hasData || alumSnap.data!.docs.isEmpty) {
          return const Center(
            child: Text('No hay alumnos inscritos aún',
                style: TextStyle(color: Colors.white38)),
          );
        }
        final alumnos = alumSnap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alumnos.length,
          itemBuilder: (context, i) {
            final a = alumnos[i].data() as Map<String, dynamic>;
            final alumId = a['alumnoId'] as String? ?? '';
            final nombre = a['alumnoNombre'] as String? ?? 'Alumno';
            return StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('sesiones_examen')
                  .where('estudianteId', isEqualTo: alumId)
                  .where('completado', isEqualTo: true)
                  .get()
                  .asStream(),
              builder: (context, sesSnap) {
                int totalExamenes = 0;
                double promedio = 0;
                if (sesSnap.hasData && sesSnap.data!.docs.isNotEmpty) {
                  totalExamenes = sesSnap.data!.docs.length;
                  final sumas = sesSnap.data!.docs.fold<double>(0, (sum, d) {
                    final data = d.data() as Map<String, dynamic>;
                    final pts = (data['puntuacion'] as num?)?.toDouble() ?? 0;
                    final max =
                        (data['puntajeMaximo'] as num?)?.toDouble() ?? 1;
                    return sum + (pts / max * 100);
                  });
                  promedio = sumas / totalExamenes;
                }
                final color = promedio >= 70
                    ? const Color(0xFF5DE0C5)
                    : promedio >= 50
                        ? const Color(0xFFF7A26A)
                        : promedio > 0
                            ? const Color(0xFFF7584A)
                            : Colors.white38;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF7C6AF7),
                        child: Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : 'A',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombre,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            Text('$totalExamenes exámenes completados',
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      ),
                      if (totalExamenes > 0)
                        Column(
                          children: [
                            Text('${promedio.round()}%',
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Text('promedio',
                                style: TextStyle(
                                    color: color.withValues(alpha: 0.7),
                                    fontSize: 10)),
                          ],
                        )
                      else
                        const Text('Sin datos',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
