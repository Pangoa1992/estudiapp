import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/premium_service.dart';
import 'premium_page.dart';

// ── Grupo de Estudio Virtual ─────────────────────────────────────────────────
class GrupoEstudioPage extends StatefulWidget {
  const GrupoEstudioPage({super.key});
  @override
  State<GrupoEstudioPage> createState() => _GrupoEstudioPageState();
}

class _GrupoEstudioPageState extends State<GrupoEstudioPage> {
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Grupos de Estudio',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _buildLista(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7C6AF7),
        onPressed: _crearOUnirse,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Crear / Unirme', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildLista() {
    final uid = _user?.uid ?? '';
    if (uid.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👥', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text('Sin grupos de estudio aún',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Crea uno o únete con un código',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('grupos_estudio')
          .where('miembrosIds', arrayContains: uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, color: Colors.white38, size: 40),
                const SizedBox(height: 12),
                const Text('Error al cargar grupos',
                    style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Reintentar',
                      style: TextStyle(color: Color(0xFF7C6AF7))),
                ),
              ],
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C6AF7)));
        }
        final docs = List.of(snap.data!.docs)
          ..sort((a, b) {
            final ad = a.data() as Map<String, dynamic>?;
            final bd = b.data() as Map<String, dynamic>?;
            final ta = (ad?['creadoEn'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final tb = (bd?['creadoEn'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return tb.compareTo(ta);
          });
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👥', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 16),
                const Text('Sin grupos de estudio aún',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 6),
                const Text('Crea uno o únete con un código',
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _crearOUnirse,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Crear / Unirme',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6AF7),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final activos = _contarActivos(d['miembros'] as List? ?? []);
            return GestureDetector(
              onTap: () async {
                final isPremium = await PremiumService.isPremium();
                if (!isPremium && mounted) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PremiumPage()));
                  return;
                }
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SalaEstudioPage(
                        grupoId: docs[i].id,
                        grupo: d,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: activos > 0
                          ? const Color(0xFF5DE0C5).withValues(alpha: 0.3)
                          : Colors.white12),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C6AF7).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                              child: Text('📚',
                                  style: TextStyle(fontSize: 22))),
                        ),
                        if (activos > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFF5DE0C5),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['nombre'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                            activos > 0
                                ? '$activos estudiando ahora · ${d['tema'] ?? ''}'
                                : d['tema'] ?? '',
                            style: TextStyle(
                              color: activos > 0
                                  ? const Color(0xFF5DE0C5)
                                  : Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: Colors.white38, size: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _contarActivos(List miembros) {
    final ahora = DateTime.now();
    return miembros.where((m) {
      final ultima = (m['ultimaActividad'] as Timestamp?)?.toDate();
      if (ultima == null) return false;
      return ahora.difference(ultima).inMinutes < 5;
    }).length;
  }

  Future<void> _crearOUnirse() async {
    final isPremium = await PremiumService.isPremium();
    if (!isPremium && mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PremiumPage()));
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Qué deseas hacer?',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _accionBtn(ctx, '➕ Crear un grupo nuevo', const Color(0xFF7C6AF7),
                _mostrarCrear),
            const SizedBox(height: 10),
            _accionBtn(ctx, '🔗 Unirme con código', const Color(0xFF5DE0C5),
                _mostrarUnirse),
          ],
        ),
      ),
    );
  }

  Widget _accionBtn(
      BuildContext ctx, String label, Color color, VoidCallback accion) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        accion();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
      ),
    );
  }

  Future<void> _mostrarCrear() async {
    final nombreCtrl = TextEditingController();
    final temaCtrl = TextEditingController();
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
            const Text('Crear Grupo de Estudio',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextField(
              controller: nombreCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('Nombre del grupo', 'Ej: Cálculo II - Tardes'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: temaCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco(
                  'Tema de estudio actual', 'Ej: Derivadas, Química orgánica…'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nombreCtrl.text.trim().isEmpty) return;
                  await _crearGrupo(
                      nombreCtrl.text.trim(), temaCtrl.text.trim());
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

  Future<void> _crearGrupo(String nombre, String tema) async {
    final user = _user;
    if (user == null) return;
    final codigo = _genCodigo();
    final miembro = {
      'userId': user.uid,
      'nombre': user.displayName ?? 'Estudiante',
      'fotoUrl': user.photoURL ?? '',
      'ultimaActividad': Timestamp.now(),
      'temaActual': tema,
    };
    await _db.collection('grupos_estudio').add({
      'nombre': nombre,
      'tema': tema,
      'creadorId': user.uid,
      'codigo': codigo,
      'creadoEn': Timestamp.now(),
      'miembros': [miembro],
      'miembrosIds': [user.uid],
    });
  }

  Future<void> _mostrarUnirse() async {
    final ctrl = TextEditingController();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        title: const Text('Unirme a un grupo',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
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
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6AF7)),
            onPressed: () async {
              final codigo = ctrl.text.trim().toUpperCase();
              Navigator.pop(ctx);
              await _unirse(codigo);
            },
            child: const Text('Unirme',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _unirse(String codigo) async {
    final user = _user;
    if (user == null) return;
    final snap = await _db
        .collection('grupos_estudio')
        .where('codigo', isEqualTo: codigo)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Código inválido')));
      }
      return;
    }
    final doc = snap.docs.first;
    final miembrosIds =
        List<String>.from((doc.data()['miembrosIds'] as List?) ?? []);
    if (miembrosIds.contains(user.uid)) {
      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    SalaEstudioPage(grupoId: doc.id, grupo: doc.data())));
      }
      return;
    }
    final miembro = {
      'userId': user.uid,
      'nombre': user.displayName ?? 'Estudiante',
      'fotoUrl': user.photoURL ?? '',
      'ultimaActividad': Timestamp.now(),
      'temaActual': '',
    };
    await _db.collection('grupos_estudio').doc(doc.id).update({
      'miembros': FieldValue.arrayUnion([miembro]),
      'miembrosIds': FieldValue.arrayUnion([user.uid]),
    });
    if (mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  SalaEstudioPage(grupoId: doc.id, grupo: doc.data())));
    }
  }

  String _genCodigo() {
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        counterStyle: const TextStyle(color: Colors.white38),
      );
}

// ── Sala de Estudio ──────────────────────────────────────────────────────────
class SalaEstudioPage extends StatefulWidget {
  final String grupoId;
  final Map<String, dynamic> grupo;
  const SalaEstudioPage({super.key, required this.grupoId, required this.grupo});
  @override
  State<SalaEstudioPage> createState() => _SalaEstudioPageState();
}

class _SalaEstudioPageState extends State<SalaEstudioPage> {
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _heartbeat;

  @override
  void initState() {
    super.initState();
    _registrarEntrada();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) => _latido());
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrarEntrada() async {
    if (_user == null) return;
    await _actualizarMiembro({'ultimaActividad': Timestamp.now()});
  }

  Future<void> _latido() async {
    if (_user == null) return;
    await _actualizarMiembro({'ultimaActividad': Timestamp.now()});
  }

  Future<void> _actualizarMiembro(Map<String, dynamic> campos) async {
    final uid = _user?.uid;
    if (uid == null) return;
    final doc = await _db.collection('grupos_estudio').doc(widget.grupoId).get();
    final miembros =
        List<Map<String, dynamic>>.from((doc.data()?['miembros'] as List? ?? [])
            .map((m) => Map<String, dynamic>.from(m as Map)));
    final idx = miembros.indexWhere((m) => m['userId'] == uid);
    if (idx != -1) {
      miembros[idx].addAll(campos);
      await _db
          .collection('grupos_estudio')
          .doc(widget.grupoId)
          .update({'miembros': miembros});
    }
  }

  Future<void> _enviarMensaje() async {
    final texto = _chatCtrl.text.trim();
    final user = _user;
    if (texto.isEmpty || user == null) return;
    _chatCtrl.clear();
    await _latido();
    await _db
        .collection('grupos_estudio')
        .doc(widget.grupoId)
        .collection('mensajes')
        .add({
      'userId': user.uid,
      'userName': user.displayName ?? 'Estudiante',
      'texto': texto,
      'timestamp': Timestamp.now(),
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.grupo['nombre'] ?? 'Sala',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Miembros activos
          _buildMiembros(),
          const Divider(color: Colors.white12, height: 1),

          // Chat
          Expanded(child: _buildChat()),

          // Input
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMiembros() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('grupos_estudio').doc(widget.grupoId).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final miembros =
            List<Map<String, dynamic>>.from((data?['miembros'] as List? ?? [])
                .map((m) => Map<String, dynamic>.from(m as Map)));
        final ahora = DateTime.now();
        miembros.sort((a, b) {
          final ta =
              (a['ultimaActividad'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final tb =
              (b['ultimaActividad'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return tb.compareTo(ta);
        });

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF1E1E2A),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.grupo['tema'] ?? 'Estudiando'}',
                  style: const TextStyle(
                      color: Color(0xFF7C6AF7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 62,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: miembros.length,
                  itemBuilder: (context, i) {
                    final m = miembros[i];
                    final ultima =
                        (m['ultimaActividad'] as Timestamp?)?.toDate();
                    final activo = ultima != null &&
                        ahora.difference(ultima).inMinutes < 5;
                    final nombre =
                        (m['nombre'] as String? ?? 'U').split(' ').first;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: activo
                                    ? const Color(0xFF7C6AF7)
                                    : Colors.white24,
                                child: Text(
                                  nombre.isNotEmpty
                                      ? nombre[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                      color: activo
                                          ? Colors.white
                                          : Colors.white38,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ),
                              if (activo)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5DE0C5),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: const Color(0xFF1E1E2A),
                                          width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nombre.length > 8
                                ? '${nombre.substring(0, 7)}…'
                                : nombre,
                            style: TextStyle(
                                color: activo
                                    ? Colors.white70
                                    : Colors.white24,
                                fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChat() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('grupos_estudio')
          .doc(widget.grupoId)
          .collection('mensajes')
          .orderBy('timestamp')
          .limit(100)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('💬', style: TextStyle(fontSize: 40)),
                SizedBox(height: 8),
                Text('Sé el primero en escribir',
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
          }
        });
        return ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            final d = snap.data!.docs[i].data() as Map<String, dynamic>;
            final esPropio = d['userId'] == _user?.uid;
            final nombre = d['userName'] as String? ?? 'Usuario';
            final texto = d['texto'] as String? ?? '';
            return Align(
              alignment:
                  esPropio ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75),
                child: Column(
                  crossAxisAlignment: esPropio
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!esPropio)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 2),
                        child: Text(nombre.split(' ').first,
                            style: const TextStyle(
                                color: Color(0xFF7C6AF7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: esPropio
                            ? const Color(0xFF7C6AF7)
                            : const Color(0xFF1E1E2A),
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: esPropio
                              ? const Radius.circular(4)
                              : const Radius.circular(16),
                          bottomLeft: esPropio
                              ? const Radius.circular(16)
                              : const Radius.circular(4),
                        ),
                      ),
                      child: Text(texto,
                          style: TextStyle(
                              color: esPropio ? Colors.white : Colors.white70,
                              fontSize: 14,
                              height: 1.4)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2A),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Escribe algo para el grupo…',
                hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 13),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: const Color(0xFF0F0F14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _enviarMensaje(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _enviarMensaje,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7C6AF7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
