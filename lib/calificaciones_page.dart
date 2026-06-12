import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/calificacion_model.dart';
import 'services/gpa_service.dart';

class CalificacionesPage extends StatefulWidget {
  const CalificacionesPage({super.key});

  @override
  State<CalificacionesPage> createState() => _CalificacionesPageState();
}

class _CalificacionesPageState extends State<CalificacionesPage> {
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;
  EscalaNotas _escala = EscalaNotas.escala20;
  String? _cursoFiltro;

  @override
  void initState() {
    super.initState();
    GpaService.getEscala().then((e) => setState(() => _escala = e));
  }

  void _cambiarEscala() async {
    final nueva = await showDialog<EscalaNotas>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sistema de calificación',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: EscalaNotas.values.map((e) {
            return ListTile(
              title: Text(e.nombre,
                  style: TextStyle(
                      color: e == _escala
                          ? const Color(0xFF7C6AF7)
                          : Colors.white70,
                      fontSize: 13)),
              trailing: e == _escala
                  ? const Icon(Icons.check, color: Color(0xFF7C6AF7))
                  : null,
              onTap: () => Navigator.pop(context, e),
            );
          }).toList(),
        ),
      ),
    );
    if (nueva != null) {
      await GpaService.setEscala(nueva);
      setState(() => _escala = nueva);
    }
  }

  void _agregarNota() async {
    final uid = _user?.uid;
    if (uid == null) return;
    try {
      final cursosSnap = await _db
          .collection('cursos')
          .where('userId', isEqualTo: uid)
          .get();
      if (!mounted) return;
      if (cursosSnap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primero agrega un curso en "Mis cursos"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      _dialogoAgregar(cursosSnap.docs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar cursos: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _dialogoAgregar(List<QueryDocumentSnapshot> cursos) async {
    final notaCtrl = TextEditingController();
    final pesoCtrl = TextEditingController(text: '100');
    final descCtrl = TextEditingController();
    String? cursoId;
    String? cursoNombre;
    String tipo = 'Examen';

    const tipos = ['Examen', 'Práctica', 'Proyecto', 'Tarea', 'Participación'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Agregar nota',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: cursoId,
                dropdownColor: const Color(0xFF252535),
                style: const TextStyle(color: Colors.white),
                decoration: _deco('Curso'),
                items: cursos.map((c) {
                  final d = c.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                      value: c.id, child: Text(d['nombre'] ?? ''));
                }).toList(),
                onChanged: (val) => setS(() {
                  cursoId = val;
                  cursoNombre = (cursos.firstWhere((c) => c.id == val).data()
                      as Map<String, dynamic>)['nombre'];
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: notaCtrl,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: _deco('Nota (max ${_escala.maximo.toStringAsFixed(0)})'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: pesoCtrl,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: _deco('Peso (%)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: tipo,
                dropdownColor: const Color(0xFF252535),
                style: const TextStyle(color: Colors.white),
                decoration: _deco('Tipo de evaluación'),
                items: tipos
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setS(() => tipo = val ?? tipo),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _deco('Descripción (opcional)'),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final nota = double.tryParse(notaCtrl.text);
                  final peso = double.tryParse(pesoCtrl.text) ?? 100;
                  if (cursoId == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Selecciona un curso'),
                      behavior: SnackBarBehavior.floating,
                    ));
                    return;
                  }
                  if (nota == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Ingresa una nota válida'),
                      behavior: SnackBarBehavior.floating,
                    ));
                    return;
                  }
                  await GpaService.agregar(Calificacion(
                    id: '',
                    cursoId: cursoId!,
                    cursoNombre: cursoNombre ?? '',
                    tipo: tipo,
                    nota: nota.clamp(0, _escala.maximo),
                    peso: peso.clamp(0, 100),
                    fecha: DateTime.now(),
                    userId: _user?.uid ?? '',
                    descripcion: descCtrl.text.trim(),
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7C6AF7), Color(0xFF5A4ED4)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Guardar',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF252535),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF3D3D5E))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF7C6AF7))),
      );

  Color _colorNota(double nota) {
    final p = nota / _escala.maximo;
    if (p >= 0.85) return const Color(0xFF5DE0C5);
    if (p >= 0.70) return const Color(0xFF4A90E2);
    if (p >= _escala.aprobacion / _escala.maximo) return const Color(0xFFF7A26A);
    return const Color(0xFFF7584A);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        title: const Text('Mis Notas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white70),
            onPressed: _cambiarEscala,
            tooltip: 'Cambiar escala',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF7C6AF7)),
            onPressed: _agregarNota,
          ),
        ],
      ),
      body: StreamBuilder<List<Calificacion>>(
        stream: GpaService.streamTodas(),
        builder: (context, snap) {
          final todas = snap.data ?? [];

          // Agrupar por curso
          final porCurso = <String, _DatoCurso>{};
          for (final c in todas) {
            porCurso.putIfAbsent(
                c.cursoId, () => _DatoCurso(nombre: c.cursoNombre));
            porCurso[c.cursoId]!.calificaciones.add(c);
          }

          final promedioGeneral = todas.isEmpty
              ? 0.0
              : GpaService.calcularPonderado(todas);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumen general
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1A1A40), Color(0xFF0F1A30)]),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: const Color(0xFF7C6AF7).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Promedio general',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              promedioGeneral.toStringAsFixed(2),
                              style: TextStyle(
                                  color: _colorNota(promedioGeneral),
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Escala: ${_escala.nombre.trim()}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _colorNota(promedioGeneral)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _colorNota(promedioGeneral)
                                      .withOpacity(0.4)),
                            ),
                            child: Text(
                              _escala.letra(promedioGeneral),
                              style: TextStyle(
                                  color: _colorNota(promedioGeneral),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _cambiarEscala,
                            child: const Text('Cambiar escala',
                                style: TextStyle(
                                    color: Color(0xFF7C6AF7), fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('POR CURSO',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const SizedBox(height: 12),

                if (porCurso.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Text('📊', style: TextStyle(fontSize: 40)),
                          SizedBox(height: 12),
                          Text('Aún no tienes notas registradas',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Agrega tus calificaciones con el botón +',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else
                  ...porCurso.entries.map((e) {
                    final cursoId = e.key;
                    final info = e.value;
                    final promedio =
                        GpaService.calcularPonderado(info.calificaciones);
                    final estaExpandido =
                        _cursoFiltro == cursoId;

                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            _cursoFiltro =
                                estaExpandido ? null : cursoId;
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: estaExpandido
                                    ? _colorNota(promedio).withOpacity(0.5)
                                    : const Color(0xFF2E2E3E),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _colorNota(promedio).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _escala.letra(promedio),
                                      style: TextStyle(
                                          color: _colorNota(promedio),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(info.nombre,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                          '${info.calificaciones.length} evaluaciones',
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text(
                                  promedio.toStringAsFixed(1),
                                  style: TextStyle(
                                      color: _colorNota(promedio),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  estaExpandido
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.white38,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (estaExpandido) ...[
                          ...info.calificaciones.map((cal) => Container(
                                margin: const EdgeInsets.only(
                                    left: 12, bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252535),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C6AF7)
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(cal.tipo,
                                          style: const TextStyle(
                                              color: Color(0xFF7C6AF7),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cal.descripcion.isNotEmpty
                                                ? cal.descripcion
                                                : cal.tipo,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13),
                                          ),
                                          Text('Peso: ${cal.peso.toStringAsFixed(0)}%',
                                              style: const TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      cal.nota.toStringAsFixed(1),
                                      style: TextStyle(
                                          color: _colorNota(cal.nota),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () =>
                                          GpaService.eliminar(cal.id),
                                      child: const Icon(Icons.close,
                                          color: Colors.white24, size: 16),
                                    ),
                                  ],
                                ),
                              )),
                          _buildCalculadoraMeta(info.calificaciones, cursoId),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalculadoraMeta(
      List<Calificacion> calificaciones, String cursoId) {
    final pesoActual =
        calificaciones.fold<double>(0, (s, c) => s + c.peso);
    final pesoRestante = (100 - pesoActual).clamp(0, 100);
    if (pesoRestante <= 0) return const SizedBox();

    final metaAprobacion = _escala.aprobacion;
    final necesaria = GpaService.calcularNecesaria(
      actuales: calificaciones,
      meta: metaAprobacion,
      pesoRestante: pesoRestante.toDouble(),
      escala: _escala,
    );

    return Container(
      margin: const EdgeInsets.only(left: 12, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined,
              color: Color(0xFF7C6AF7), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Para aprobar (${metaAprobacion.toStringAsFixed(0)}+) necesitas '
              '${necesaria.toStringAsFixed(1)} en el ${pesoRestante.toStringAsFixed(0)}% restante',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatoCurso {
  final String nombre;
  final List<Calificacion> calificaciones = [];
  _DatoCurso({required this.nombre});
}
