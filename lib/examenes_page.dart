import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notificaciones_service.dart';
import 'cache_service.dart';
import 'calendar_sync_service.dart';

class ExamenesPage extends StatefulWidget {
  const ExamenesPage({super.key});

  @override
  State<ExamenesPage> createState() => _ExamenesPageState();
}

class _ExamenesPageState extends State<ExamenesPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;
  bool _mostrarCompletados = false;
  bool _sincronizando = false;
  StreamSubscription? _cacheSub;

  @override
  void initState() {
    super.initState();
    NotificacionesService.inicializar();
    _cacheSub = _db
        .collection('examenes')
        .where('userId', isEqualTo: user!.uid)
        .snapshots()
        .listen((snap) {
      CacheService.guardarExamenes(snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        if (data['fecha'] is Timestamp) {
          data['fecha'] = (data['fecha'] as Timestamp).millisecondsSinceEpoch;
        }
        return data;
      }).toList());
    });
  }

  @override
  void dispose() {
    _cacheSub?.cancel();
    super.dispose();
  }

  Future<void> _sincronizarConCalendar() async {
    setState(() => _sincronizando = true);
    int exportados = 0;
    try {
      final snap = await _db
          .collection('examenes')
          .where('userId', isEqualTo: user!.uid)
          .where('completado', isEqualTo: false)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final fechaRaw = data['fecha'];
        if (fechaRaw == null) continue;
        final fecha = (fechaRaw as Timestamp).toDate();
        if (fecha.isBefore(DateTime.now())) continue;
        final ok = await CalendarSyncService.exportarExamen(
          curso: data['curso'] ?? '',
          fecha: fecha,
          hora: data['hora'] ?? '',
          notas: data['notas'] ?? '',
        );
        if (ok) exportados++;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exportados > 0
                ? '$exportados examen(es) exportado(s) a Google Calendar'
                : 'No se exportaron examenes (verifica permisos o si hay proximos)',
          ),
          backgroundColor:
              exportados > 0 ? const Color(0xFF5DE0C5) : const Color(0xFFF7584A),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al conectar con Google Calendar'),
          backgroundColor: Color(0xFFF7584A),
        ),
      );
    } finally {
      if (mounted) setState(() => _sincronizando = false);
    }
  }

  void _mostrarFormulario({Map<String, dynamic>? examen, String? docId}) {
    final cursoController = TextEditingController(text: examen?['curso'] ?? '');
    final notasController = TextEditingController(text: examen?['notas'] ?? '');
    final horaController = TextEditingController(text: examen?['hora'] ?? '');
    DateTime fechaSeleccionada = examen != null
        ? (examen['fecha'] as Timestamp).toDate()
        : DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(examen == null ? 'Nuevo examen' : 'Editar examen',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: cursoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nombre del curso',
                    labelStyle: const TextStyle(color: Color(0xFF7C6AF7)),
                    filled: true,
                    fillColor: const Color(0xFF0F0F14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: fechaSeleccionada,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
                        Text(
                          '${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // ── SELECTOR DE HORA CON RELOJ ──
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
                      final hora = tiempo.hourOfPeriod == 0 ? 12 : tiempo.hourOfPeriod;
                      final minuto = tiempo.minute.toString().padLeft(2, '0');
                      final periodo = tiempo.period == DayPeriod.am ? 'AM' : 'PM';
                      horaController.text = '$hora:$minuto $periodo';
                      setModalState(() {});
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Color(0xFF7C6AF7), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          horaController.text.isEmpty ? 'Seleccionar hora del examen' : horaController.text,
                          style: TextStyle(
                            color: horaController.text.isEmpty ? Colors.white38 : Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notasController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Notas del examen (temas, apuntes...)',
                    labelStyle: const TextStyle(color: Color(0xFF7C6AF7)),
                    filled: true,
                    fillColor: const Color(0xFF0F0F14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C6AF7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.notifications_active, color: Color(0xFF7C6AF7), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recibirás alertas 2 días antes, 1 día antes y el mismo día del examen',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (cursoController.text.isEmpty) return;
                      final data = {
                        'curso': cursoController.text,
                        'fecha': Timestamp.fromDate(fechaSeleccionada),
                        'hora': horaController.text,
                        'notas': notasController.text,
                        'completado': examen?['completado'] ?? false,
                        'userId': user!.uid,
                      };
                      String examenId;
                      if (docId != null) {
                        await _db.collection('examenes').doc(docId).update(data);
                        examenId = docId;
                      } else {
                        final ref = await _db.collection('examenes').add(data);
                        examenId = ref.id;
                      }
                      // Programar notificaciones
                      await NotificacionesService.programarNotificacionesExamen(
                        id: examenId.hashCode.abs(),
                        curso: cursoController.text,
                        fecha: fechaSeleccionada,
                        hora: horaController.text.isNotEmpty ? horaController.text : '08:00 AM',
                      );
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6AF7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(examen == null ? 'Agregar examen' : 'Guardar cambios',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoNota(String docId, String nombreCurso) {
    double nota = 0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final int notaInt = nota.round();
          final aprobado = notaInt >= 11;
          final col = aprobado ? const Color(0xFF5DE0C5) : const Color(0xFFF7584A);
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('¡Examen completado! 🎓',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(nombreCurso,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$notaInt',
                  style: TextStyle(
                      color: col, fontSize: 56, fontWeight: FontWeight.bold)),
              Text('/ 20',
                  style: const TextStyle(color: Colors.white38, fontSize: 16)),
              const SizedBox(height: 4),
              Text(aprobado ? '¡Aprobado! 🎉' : 'No aprobado 💪',
                  style: TextStyle(
                      color: col, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: col,
                  thumbColor: col,
                  inactiveTrackColor: Colors.white12,
                  overlayColor: col.withOpacity(0.2),
                ),
                child: Slider(
                  value: nota,
                  min: 0,
                  max: 20,
                  divisions: 20,
                  label: '$notaInt',
                  onChanged: (v) => setDialogState(() => nota = v),
                ),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                onPressed: () {
                  _db.collection('examenes').doc(docId).update({
                    'completado': true,
                    'nota': nota.round(),
                  });
                  NotificacionesService.cancelarNotificacion(docId.hashCode.abs());
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6AF7)),
                child: const Text('Guardar',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarNotas(Map<String, dynamic> data, String docId) {
    final completado = data['completado'] == true;
    final nota = data['nota'] as int?;
    final aprobado = nota != null ? nota >= 11 : null;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['curso'] ?? '',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            if (data['hora']?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time,
                    color: Color(0xFF7C6AF7), size: 14),
                const SizedBox(width: 4),
                Text(data['hora'],
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
              ]),
            ],
            // Nota si completado
            if (completado && nota != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (aprobado!
                          ? const Color(0xFF5DE0C5)
                          : const Color(0xFFF7584A))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: (aprobado
                              ? const Color(0xFF5DE0C5)
                              : const Color(0xFFF7584A))
                          .withOpacity(0.3)),
                ),
                child: Row(children: [
                  Text(aprobado ? '🎉' : '💪',
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nota: $nota / 20',
                            style: TextStyle(
                                color: aprobado
                                    ? const Color(0xFF5DE0C5)
                                    : const Color(0xFFF7584A),
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(aprobado ? '¡Aprobado!' : 'No aprobado',
                            style: TextStyle(
                                color: aprobado
                                    ? const Color(0xFF5DE0C5)
                                    : const Color(0xFFF7584A),
                                fontSize: 12)),
                      ]),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            const Text('Notas:',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFF0F0F14),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(
                data['notas']?.isNotEmpty == true ? data['notas'] : 'Sin notas',
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            if (!completado)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _mostrarDialogoNota(docId, data['curso'] ?? '');
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text('Marcar como completado',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5DE0C5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        title: const Text('Mis examenes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _sincronizando
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Color(0xFF7C6AF7), strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.calendar_month, color: Color(0xFF5DE0C5)),
                  tooltip: 'Exportar a Google Calendar',
                  onPressed: _sincronizarConCalendar,
                ),
          TextButton(
            onPressed: () => setState(() => _mostrarCompletados = !_mostrarCompletados),
            child: Text(
              _mostrarCompletados ? 'Proximos' : 'Completados',
              style: const TextStyle(color: Color(0xFF7C6AF7), fontSize: 12),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        backgroundColor: const Color(0xFF7C6AF7),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('examenes')
            .where('userId', isEqualTo: user!.uid)
            .where('completado', isEqualTo: _mostrarCompletados)
            .orderBy('fecha')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF7C6AF7)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _mostrarCompletados ? Icons.check_circle_outline : Icons.school_outlined,
                    color: Colors.white24, size: 60,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _mostrarCompletados ? 'No hay examenes completados' : 'No tienes examenes proximos',
                    style: const TextStyle(color: Colors.white38),
                  ),
                  if (!_mostrarCompletados)
                    const Text('Toca + para agregar uno', style: TextStyle(color: Colors.white24, fontSize: 12)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              final doc = snapshot.data!.docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final fecha = (data['fecha'] as Timestamp).toDate();
              final hoy = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
              final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
              final dias = soloFecha.difference(hoy).inDays;
              final completado = data['completado'] == true;
              final color = completado
                  ? const Color(0xFF5DE0C5)
                  : dias <= 1
                      ? const Color(0xFFF7584A)
                      : dias <= 4
                          ? const Color(0xFFF7A26A)
                          : const Color(0xFF5DE0C5);
              final tieneNotas = data['notas']?.isNotEmpty == true;

              return GestureDetector(
                onTap: () => _mostrarNotas(data, doc.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 4, backgroundColor: color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    data['curso'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (tieneNotas) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.note, color: Color(0xFF7C6AF7), size: 14),
                                ],
                              ],
                            ),
                            Text(
                              '${fecha.day}/${fecha.month}/${fecha.year}${data['hora']?.isNotEmpty == true ? ' · ${data['hora']}' : ''}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      completado
                          ? data['nota'] != null
                              ? Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text(
                                    '${data['nota']}/20',
                                    style: TextStyle(
                                      color: (data['nota'] as int) >= 11
                                          ? const Color(0xFF5DE0C5)
                                          : const Color(0xFFF7584A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    (data['nota'] as int) >= 11 ? 'Aprobado' : 'No aprobado',
                                    style: TextStyle(
                                      color: (data['nota'] as int) >= 11
                                          ? const Color(0xFF5DE0C5)
                                          : const Color(0xFFF7584A),
                                      fontSize: 9,
                                    ),
                                  ),
                                ])
                              : const Icon(Icons.check_circle, color: Color(0xFF5DE0C5), size: 20)
                          : Text(
                              dias <= 0 ? 'Hoy' : dias == 1 ? 'Mañana' : '$dias dias',
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                      const SizedBox(width: 8),
                      PopupMenuButton(
                        iconColor: Colors.white38,
                        color: const Color(0xFF1E1E2A),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            child: const Text('Editar', style: TextStyle(color: Colors.white)),
                            onTap: () => Future.delayed(Duration.zero,
                                () => _mostrarFormulario(examen: data, docId: doc.id)),
                          ),
                          PopupMenuItem(
                            child: const Row(children: [
                              Icon(Icons.calendar_month, color: Color(0xFF5DE0C5), size: 16),
                              SizedBox(width: 8),
                              Text('Exportar a Calendar', style: TextStyle(color: Color(0xFF5DE0C5))),
                            ]),
                            onTap: () => Future.delayed(Duration.zero, () async {
                              final ok = await CalendarSyncService.exportarExamen(
                                curso: data['curso'] ?? '',
                                fecha: fecha,
                                hora: data['hora'] ?? '',
                                notas: data['notas'] ?? '',
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? 'Examen exportado a Google Calendar'
                                      : 'Error al exportar a Google Calendar'),
                                  backgroundColor: ok
                                      ? const Color(0xFF5DE0C5)
                                      : const Color(0xFFF7584A),
                                ),
                              );
                            }),
                          ),
                          if (!completado)
                            PopupMenuItem(
                              child: const Text('Marcar completado', style: TextStyle(color: Color(0xFF5DE0C5))),
                              onTap: () => Future.delayed(
                                Duration.zero,
                                () => _mostrarDialogoNota(doc.id, data['curso'] ?? ''),
                              ),
                            ),
                          PopupMenuItem(
                            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                            onTap: () {
                              NotificacionesService.cancelarNotificacion(doc.id.hashCode.abs());
                              _db.collection('examenes').doc(doc.id).delete();
                            },
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