import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colors.dart';

class PerfilesAcademicosPage extends StatefulWidget {
  const PerfilesAcademicosPage({super.key});

  @override
  State<PerfilesAcademicosPage> createState() => _PerfilesAcademicosPageState();
}

class _PerfilesAcademicosPageState extends State<PerfilesAcademicosPage> {
  final _user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;

  // Colección top-level, igual que habitos/examenes, para evitar problemas de
  // reglas de seguridad en subcolecciones.
  Query get _ciclosQuery => _db
      .collection('ciclos_academicos')
      .where('userId', isEqualTo: _user!.uid);

  Future<void> _activarPerfil(
      String cicloId, List<QueryDocumentSnapshot> todos) async {
    final batch = _db.batch();
    for (final doc in todos) {
      batch.update(doc.reference, {'activo': doc.id == cicloId});
    }
    await batch.commit();
  }

  Future<void> _eliminarPerfil(
      String cicloId, bool eraActivo, List<QueryDocumentSnapshot> todos) async {
    await _db.collection('ciclos_academicos').doc(cicloId).delete();
    if (eraActivo && todos.length > 1) {
      final siguiente = todos.firstWhere((d) => d.id != cicloId);
      await siguiente.reference.update({'activo': true});
    }
  }

  void _abrirFormulario({QueryDocumentSnapshot? editando}) {
    final nombreCtrl = TextEditingController(
        text: editando != null
            ? (editando.data() as Map)['nombre'] ?? ''
            : '');
    final carreraCtrl = TextEditingController(
        text: editando != null
            ? (editando.data() as Map)['carrera'] ?? ''
            : '');
    final universidadCtrl = TextEditingController(
        text: editando != null
            ? (editando.data() as Map)['universidad'] ?? ''
            : '');
    int cicloNum = editando != null
        ? ((editando.data() as Map)['numeroCiclo'] ?? 1) as int
        : 1;
    int anioVal = editando != null
        ? ((editando.data() as Map)['ano'] ?? DateTime.now().year) as int
        : DateTime.now().year;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                editando == null ? 'Nuevo perfil académico' : 'Editar perfil',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _campo(nombreCtrl, 'Nombre del ciclo', 'Ej: Ciclo 2025-I',
                  Icons.label_outline),
              const SizedBox(height: 12),
              _campo(carreraCtrl, 'Carrera', 'Ej: Ingeniería de Sistemas',
                  Icons.school_outlined),
              const SizedBox(height: 12),
              _campo(universidadCtrl, 'Universidad', 'Ej: UNI',
                  Icons.account_balance_outlined),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ciclo #',
                            style: TextStyle(
                                color: context.textSecondary, fontSize: 12)),
                        const SizedBox(height: 6),
                        _selectorNum(
                            cicloNum, 1, 12, (v) => setSheet(() => cicloNum = v)),
                      ]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Año',
                            style: TextStyle(
                                color: context.textSecondary, fontSize: 12)),
                        const SizedBox(height: 6),
                        _selectorNum(anioVal, 2020, 2030,
                            (v) => setSheet(() => anioVal = v)),
                      ]),
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppC.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _guardar(
                    sheetCtx: sheetCtx,
                    editando: editando,
                    nombre: nombreCtrl.text.trim(),
                    carrera: carreraCtrl.text.trim(),
                    universidad: universidadCtrl.text.trim(),
                    cicloNum: cicloNum,
                    anioVal: anioVal,
                  ),
                  child: Text(
                      editando == null ? 'Crear perfil' : 'Guardar cambios',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardar({
    required BuildContext sheetCtx,
    required QueryDocumentSnapshot? editando,
    required String nombre,
    required String carrera,
    required String universidad,
    required int cicloNum,
    required int anioVal,
  }) async {
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del ciclo es obligatorio')),
      );
      return;
    }

    try {
      final Map<String, dynamic> data = {
        'userId': _user!.uid,
        'nombre': nombre,
        'carrera': carrera,
        'universidad': universidad,
        'numeroCiclo': cicloNum,
        'ano': anioVal,
        'creadoEn': FieldValue.serverTimestamp(),
      };

      if (editando != null) {
        await editando.reference.update(data);
      } else {
        final existentes = await _ciclosQuery.get();
        data['activo'] = existentes.docs.isEmpty;
        await _db.collection('ciclos_academicos').add(data);
      }

      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppC.red,
          ),
        );
      }
    }
  }

  Widget _campo(TextEditingController ctrl, String label, String hint,
      IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderPrimary),
      ),
      child: TextField(
        controller: ctrl,
        style: TextStyle(color: context.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppC.purple, size: 18),
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: context.textSecondary, fontSize: 13),
          hintStyle: TextStyle(color: context.textTertiary, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _selectorNum(
      int valor, int min, int max, ValueChanged<int> onChange) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderPrimary),
      ),
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.remove, color: context.textSecondary, size: 18),
          onPressed: valor > min ? () => onChange(valor - 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        Expanded(
          child: Text(
            '$valor',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.textPrimary, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add, color: context.textSecondary, size: 18),
          onPressed: valor < max ? () => onChange(valor + 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ]),
    );
  }

  void _confirmarEliminar(String cicloId, String nombre, bool eraActivo,
      List<QueryDocumentSnapshot> todos) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Eliminar perfil?',
            style: TextStyle(
                color: context.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Se eliminará "$nombre". Esta acción no se puede deshacer.',
          style: TextStyle(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppC.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _eliminarPerfil(cicloId, eraActivo, todos);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error al eliminar: $e'),
                        backgroundColor: AppC.red),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        elevation: 0,
        title: Text('Perfiles académicos',
            style: TextStyle(
                color: context.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.textPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: AppC.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo ciclo',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ciclosQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppC.purple));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: ${snapshot.error}\n\nVerifica que tienes conexión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textSecondary),
                ),
              ),
            );
          }

          // Ordenar cliente: por creadoEn ascendente
          final docs = List<QueryDocumentSnapshot>.from(
              snapshot.data?.docs ?? <QueryDocumentSnapshot>[]);
          docs.sort((a, b) {
            final ta = (a.data() as Map)['creadoEn'];
            final tb = (b.data() as Map)['creadoEn'];
            if (ta == null) return 1;
            if (tb == null) return -1;
            return (ta as Comparable).compareTo(tb);
          });

          if (docs.isEmpty) return _buildVacio();

          final activo = docs
              .where((d) => (d.data() as Map)['activo'] == true)
              .firstOrNull;
          final inactivos =
              docs.where((d) => (d.data() as Map)['activo'] != true).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activo != null) ...[
                  _buildEncabezadoSeccion('PERFIL ACTIVO'),
                  const SizedBox(height: 10),
                  _buildTarjetaActiva(activo, docs),
                  const SizedBox(height: 24),
                ],
                if (inactivos.isNotEmpty) ...[
                  _buildEncabezadoSeccion('OTROS CICLOS'),
                  const SizedBox(height: 10),
                  ...inactivos.map((doc) => _buildTarjetaInactiva(doc, docs)),
                ],
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEncabezadoSeccion(String label) {
    return Text(
      label,
      style: TextStyle(
        color: context.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTarjetaActiva(
      QueryDocumentSnapshot doc, List<QueryDocumentSnapshot> todos) {
    final data = doc.data() as Map<String, dynamic>;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D2FA0), Color(0xFF5A4ED4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppC.purple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text('Activo',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            const Spacer(),
            _menuOpciones(doc, true, todos),
          ]),
          const SizedBox(height: 14),
          Text(
            data['nombre'] ?? 'Sin nombre',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if ((data['carrera'] ?? '').isNotEmpty)
            Row(children: [
              const Icon(Icons.school, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(data['carrera'],
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ),
            ]),
          const SizedBox(height: 4),
          if ((data['universidad'] ?? '').isNotEmpty)
            Row(children: [
              const Icon(Icons.account_balance,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(data['universidad'],
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          const SizedBox(height: 12),
          Row(children: [
            _chip('Ciclo ${data['numeroCiclo'] ?? '—'}',
                Icons.format_list_numbered),
            const SizedBox(width: 8),
            _chip('${data['ano'] ?? DateTime.now().year}',
                Icons.calendar_today),
          ]),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 11)),
      ]),
    );
  }

  Widget _buildTarjetaInactiva(
      QueryDocumentSnapshot doc, List<QueryDocumentSnapshot> todos) {
    final data = doc.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderPrimary),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppC.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              const Icon(Icons.school_outlined, color: AppC.purple, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['nombre'] ?? 'Sin nombre',
                  style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if ((data['carrera'] ?? '').isNotEmpty)
                      data['carrera'] as String,
                    'Ciclo ${data['numeroCiclo'] ?? '—'} · ${data['ano'] ?? ''}',
                  ].join(' · '),
                  style:
                      TextStyle(color: context.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
        ),
        GestureDetector(
          onTap: () => _activarPerfil(doc.id, todos),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppC.purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppC.purple.withOpacity(0.4)),
            ),
            child: const Text('Activar',
                style: TextStyle(
                    color: AppC.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 4),
        _menuOpciones(doc, false, todos),
      ]),
    );
  }

  Widget _menuOpciones(QueryDocumentSnapshot doc, bool eraActivo,
      List<QueryDocumentSnapshot> todos) {
    final data = doc.data() as Map<String, dynamic>;
    return PopupMenuButton<String>(
      color: context.bgCard,
      icon: Icon(Icons.more_vert,
          color: eraActivo ? Colors.white54 : context.textTertiary, size: 20),
      onSelected: (val) {
        if (val == 'editar') _abrirFormulario(editando: doc);
        if (val == 'eliminar') {
          _confirmarEliminar(
              doc.id, data['nombre'] ?? 'este perfil', eraActivo, todos);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'editar',
          child: Row(children: [
            Icon(Icons.edit_outlined, color: context.textPrimary, size: 18),
            const SizedBox(width: 10),
            Text('Editar', style: TextStyle(color: context.textPrimary)),
          ]),
        ),
        PopupMenuItem(
          value: 'eliminar',
          child: Row(children: [
            const Icon(Icons.delete_outline, color: AppC.red, size: 18),
            const SizedBox(width: 10),
            const Text('Eliminar', style: TextStyle(color: AppC.red)),
          ]),
        ),
      ],
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppC.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_outlined,
                  color: AppC.purple, size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin perfiles académicos',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea un perfil para cada ciclo o semestre y organiza mejor tu vida universitaria.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add),
              label: const Text('Crear primer perfil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppC.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
