import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'horario_page.dart';

class CursosPage extends StatefulWidget {
  const CursosPage({super.key});
  @override
  State<CursosPage> createState() => _CursosPageState();
}

class _CursosPageState extends State<CursosPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;
  final _nombreCtrl = TextEditingController();
  final _profesorCtrl = TextEditingController();
  final _horaCtrl = TextEditingController();
  final _apuntesCtrl = TextEditingController();
  bool _modoHorario = false;
  int _colorSeleccionado = 0xFF7C6AF7;
  final List<int> _colores = [
    0xFF7C6AF7, 0xFF5DE0C5, 0xFFF7A26A,
    0xFFF7584A, 0xFF4AC8F7, 0xFFF74AB8
  ];
  final List<String> _diasSemana = ['L', 'M', 'X', 'J', 'V', 'S'];
  List<String> _diasSeleccionados = [];

  void _mostrarFormulario({Map<String, dynamic>? curso, String? docId}) {
    _nombreCtrl.text = curso?['nombre'] ?? '';
    _profesorCtrl.text = curso?['profesor'] ?? '';
    _horaCtrl.text = curso?['hora'] ?? '';
    _apuntesCtrl.text = curso?['apuntes'] ?? '';
    _colorSeleccionado = curso?['color'] ?? 0xFF7C6AF7;
    _diasSeleccionados = List<String>.from(curso?['dias'] ?? []);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(curso == null ? 'Nuevo curso' : 'Editar curso',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _nombreCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Nombre del curso'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _profesorCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Profesor (opcional)'),
              ),
              const SizedBox(height: 10),
              // ── Selector de hora con reloj ──
              GestureDetector(
                onTap: () async {
                  final tiempo = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: (context, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Color(0xFF7C6AF7),
                          surface: Color(0xFF1E1E2A),
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (tiempo != null) {
                    final h = tiempo.hourOfPeriod == 0 ? 12 : tiempo.hourOfPeriod;
                    final m = tiempo.minute.toString().padLeft(2, '0');
                    final p = tiempo.period == DayPeriod.am ? 'AM' : 'PM';
                    setModalState(() => _horaCtrl.text = '$h:$m $p');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.access_time, color: Color(0xFF7C6AF7), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _horaCtrl.text.isEmpty ? 'Seleccionar hora' : _horaCtrl.text,
                      style: TextStyle(
                        color: _horaCtrl.text.isEmpty ? Colors.white38 : Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _apuntesCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: _inputDecoration('Apuntes del curso (opcional)'),
              ),
              const SizedBox(height: 14),
              const Text('Días de clase', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: _diasSemana.map((dia) {
                  final seleccionado = _diasSeleccionados.contains(dia);
                  return GestureDetector(
                    onTap: () => setModalState(() {
                      if (seleccionado) {
                        _diasSeleccionados.remove(dia);
                      } else {
                        _diasSeleccionados.add(dia);
                      }
                    }),
                    child: Container(
                      width: 36, height: 36,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: seleccionado ? const Color(0xFF7C6AF7) : const Color(0xFF0F0F14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(dia, style: TextStyle(
                          color: seleccionado ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.bold, fontSize: 12,
                        )),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text('Color', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: _colores.map((c) => GestureDetector(
                  onTap: () => setModalState(() => _colorSeleccionado = c),
                  child: Container(
                    width: 30, height: 30,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _colorSeleccionado == c ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_nombreCtrl.text.isEmpty) return;
                    final data = {
                      'nombre': _nombreCtrl.text,
                      'profesor': _profesorCtrl.text.isEmpty ? 'Sin profesor' : _profesorCtrl.text,
                      'hora': _horaCtrl.text,
                      'color': _colorSeleccionado,
                      'dias': _diasSeleccionados,
                      'apuntes': _apuntesCtrl.text,
                      'userId': user!.uid,
                    };
                    if (docId != null) {
                      await _db.collection('cursos').doc(docId).update(data);
                    } else {
                      await _db.collection('cursos').add(data);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6AF7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(curso == null ? 'Guardar curso' : 'Actualizar curso',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleCurso(Map<String, dynamic> curso, String docId) {
    final color = Color(curso['color'] ?? 0xFF7C6AF7);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 8, backgroundColor: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(curso['nombre'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${curso['profesor'] ?? ''} · ${List<String>.from(curso['dias'] ?? []).join(', ')} · ${curso['hora'] ?? ''}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 16),

              // Apuntes
              if ((curso['apuntes'] ?? '').isNotEmpty) ...[
                const Text('APUNTES', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Text(curso['apuntes'], style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                ),
                const SizedBox(height: 16),
              ],

              // Promedio de notas
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('examenes')
                    .where('userId', isEqualTo: user!.uid)
                    .where('curso', isEqualTo: curso['nombre'])
                    .where('completado', isEqualTo: true)
                    .snapshots(),
                builder: (context, exSnap) {
                  final completados = exSnap.data?.docs ?? [];
                  final conNota = completados.where((d) => (d.data() as Map)['nota'] != null).toList();
                  if (conNota.isEmpty) return const SizedBox();
                  final suma = conNota.fold<int>(0, (s, d) => s + ((d.data() as Map)['nota'] as int));
                  final promedio = suma / conNota.length;
                  final aprobado = promedio >= 11;
                  final promedioColor = aprobado ? const Color(0xFF5DE0C5) : const Color(0xFFF7584A);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: promedioColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: promedioColor.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Text(aprobado ? '🎓' : '📊', style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Promedio: ${promedio.toStringAsFixed(1)}/20',
                            style: TextStyle(color: promedioColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${conNota.length} examen${conNota.length > 1 ? 'es' : ''} evaluado${conNota.length > 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ]),
                    ]),
                  );
                },
              ),

              // Examenes del curso
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Exámenes', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  GestureDetector(
                    onTap: () => _agregarExamenParaCurso(curso['nombre'] ?? ''),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: Color(0xFF7C6AF7), size: 16),
                        Text('Agregar', style: TextStyle(color: Color(0xFF7C6AF7), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('examenes')
                    .where('userId', isEqualTo: user!.uid)
                    .where('curso', isEqualTo: curso['nombre'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF0F0F14), borderRadius: BorderRadius.circular(10)),
                      child: const Text('No hay exámenes para este curso', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    );
                  }
                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final fecha = (data['fecha'] as Timestamp).toDate();
                      final dias = fecha.difference(DateTime.now()).inDays;
                      final exColor = dias <= 1 ? const Color(0xFFF7584A) : dias <= 4 ? const Color(0xFFF7A26A) : const Color(0xFF5DE0C5);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF0F0F14), borderRadius: BorderRadius.circular(10), border: Border.all(color: exColor.withOpacity(0.3))),
                        child: Row(
                          children: [
                            Expanded(child: Text(data['curso'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13))),
                            Text(dias <= 0 ? 'Hoy' : '$dias días', style: TextStyle(color: exColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Habitos del curso
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hábitos relacionados', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  GestureDetector(
                    onTap: () => _agregarHabitoParaCurso(curso['nombre'] ?? ''),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: Color(0xFF7C6AF7), size: 16),
                        Text('Agregar', style: TextStyle(color: Color(0xFF7C6AF7), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('habitos')
                    .where('userId', isEqualTo: user!.uid)
                    .where('curso', isEqualTo: curso['nombre'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF0F0F14), borderRadius: BorderRadius.circular(10)),
                      child: const Text('No hay hábitos para este curso', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    );
                  }
                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: data['done'] == true ? const Color(0xFF14201E) : const Color(0xFF0F0F14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: data['done'] == true ? const Color(0xFF5DE0C5).withOpacity(0.3) : Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(data['nombre'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13))),
                            Text(data['hora'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            if (data['done'] == true) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle, color: Color(0xFF5DE0C5), size: 16),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _agregarExamenParaCurso(String nombreCurso) {
    Navigator.pop(context);
    final cursoCtrl = TextEditingController(text: nombreCurso);
    DateTime fechaSeleccionada = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Agregar examen', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: cursoCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Nombre del curso'),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: fechaSeleccionada,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (fecha != null) setModalState(() => fechaSeleccionada = fecha);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF0F0F14), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF7C6AF7), size: 18),
                      const SizedBox(width: 8),
                      Text('${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _db.collection('examenes').add({
                      'curso': cursoCtrl.text,
                      'fecha': Timestamp.fromDate(fechaSeleccionada),
                      'completado': false,
                      'notas': '',
                      'userId': user!.uid,
                    });
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6AF7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Agregar examen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _agregarHabitoParaCurso(String nombreCurso) {
    Navigator.pop(context);
    final nombreCtrl = TextEditingController();
    final horaCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hábito para $nombreCurso', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nombreCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Ej: Estudiar $nombreCurso'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: horaCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Hora (ej: 6:00 PM)'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nombreCtrl.text.isEmpty) return;
                  await _db.collection('habitos').add({
                    'nombre': nombreCtrl.text,
                    'hora': horaCtrl.text,
                    'icono': 0,
                    'frecuencia': 'Diario',
                    'done': false,
                    'curso': nombreCurso,
                    'userId': user!.uid,
                  });
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6AF7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Agregar hábito', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38),
    filled: true,
    fillColor: const Color(0xFF13131C),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        title: const Text('Mis cursos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _modoHorario ? Icons.list_alt : Icons.calendar_view_week,
              color: const Color(0xFF7C6AF7),
            ),
            tooltip: _modoHorario ? 'Ver lista' : 'Ver horario',
            onPressed: () => setState(() => _modoHorario = !_modoHorario),
          ),
          TextButton.icon(
            onPressed: () => _mostrarFormulario(),
            icon: const Icon(Icons.add, color: Color(0xFF7C6AF7)),
            label: const Text('Agregar', style: TextStyle(color: Color(0xFF7C6AF7), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _modoHorario
          ? const HorarioWidget()
          : StreamBuilder<QuerySnapshot>(
        stream: _db.collection('cursos').where('userId', isEqualTo: user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF7C6AF7)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book_outlined, color: Colors.white24, size: 60),
                  const SizedBox(height: 12),
                  const Text('No tienes cursos aún', style: TextStyle(color: Colors.white38)),
                  const Text('Toca Agregar para empezar', style: TextStyle(color: Colors.white24, fontSize: 12)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _mostrarFormulario(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6AF7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Agregar curso'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              final doc = snapshot.data!.docs[i];
              final c = doc.data() as Map<String, dynamic>;
              final color = Color(c['color'] ?? 0xFF7C6AF7);
              final dias = List<String>.from(c['dias'] ?? []);

              return GestureDetector(
                onTap: () => _mostrarDetalleCurso(c, doc.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 6, backgroundColor: color),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['nombre'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text(
                              '${c['profesor'] ?? ''} · ${dias.join(', ')} · ${c['hora'] ?? ''}',
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white24),
                      PopupMenuButton(
                        iconColor: Colors.white38,
                        color: const Color(0xFF1E1E2A),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            child: const Text('Editar', style: TextStyle(color: Colors.white)),
                            onTap: () => Future.delayed(Duration.zero, () => _mostrarFormulario(curso: c, docId: doc.id)),
                          ),
                          PopupMenuItem(
                            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                            onTap: () => _db.collection('cursos').doc(doc.id).delete(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}