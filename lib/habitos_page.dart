import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'historial_page.dart';
import 'notificaciones_service.dart';
import 'cache_service.dart';
import 'l10n_helper.dart';

class HabitosPage extends StatefulWidget {
  const HabitosPage({super.key});

  @override
  State<HabitosPage> createState() => _HabitosPageState();
}

class _HabitosPageState extends State<HabitosPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;
  StreamSubscription? _cacheSub;

  List<Map<String, dynamic>> _iconos(AppLocalizations l10n) => [
    {'icon': Icons.book, 'label': l10n.iconStudy},
    {'icon': Icons.water_drop, 'label': l10n.iconWater},
    {'icon': Icons.directions_run, 'label': l10n.iconExercise},
    {'icon': Icons.edit_note, 'label': l10n.iconNotes},
    {'icon': Icons.bed, 'label': l10n.iconSleep},
    {'icon': Icons.restaurant, 'label': l10n.iconEat},
    {'icon': Icons.music_note, 'label': l10n.iconMusic},
    {'icon': Icons.self_improvement, 'label': l10n.iconMeditation},
  ];

  List<String> _frecuencias(AppLocalizations l10n) =>
      [l10n.freqDaily, l10n.freqMon, l10n.freqTue, l10n.freqWed, l10n.freqThu, l10n.freqFri, l10n.freqSat, l10n.freqSun];

  @override
  void initState() {
    super.initState();
    NotificacionesService.inicializar();
    _cacheSub = _db
        .collection('habitos')
        .where('userId', isEqualTo: user!.uid)
        .snapshots()
        .listen((snap) {
      CacheService.guardarHabitos(snap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList());
    }, onError: (e) {
      // Un error de snapshot sin onError se reenvía a la zona → crash fatal.
      debugPrint('[Habitos] snapshots error: $e');
    });
  }

  @override
  void dispose() {
    _cacheSub?.cancel();
    super.dispose();
  }

  void _marcarHabito(DocumentSnapshot doc, Map<String, dynamic> data) {
    final nuevoDone = !(data['done'] ?? false);
    _db.collection('habitos').doc(doc.id).update({'done': nuevoDone});
    if (nuevoDone) {
      final ahora = DateTime.now();
      _db.collection('historial_habitos').add({
        'userId': user!.uid,
        'habitoId': doc.id,
        'nombre': data['nombre'],
        'dia': ahora.day,
        'mes': '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}',
        'fecha': Timestamp.fromDate(ahora),
      });
    }
  }

  void _mostrarFormulario({Map<String, dynamic>? habito, String? docId}) {
    final l10n = context.l10n;
    final nombreController = TextEditingController(text: habito?['nombre'] ?? '');
    final horaController = TextEditingController(text: habito?['hora'] ?? '');
    int iconoSeleccionado = habito?['icono'] ?? 0;
    final frecuencias = _frecuencias(l10n);
    String frecuenciaSeleccionada = habito?['frecuencia'] ?? frecuencias[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(habito == null ? l10n.newHabit : l10n.editHabit,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: l10n.habitName,
                  labelStyle: const TextStyle(color: Color(0xFF7C6AF7)),
                  filled: true,
                  fillColor: const Color(0xFF0F0F14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

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
                        horaController.text.isEmpty ? l10n.selectTime : horaController.text,
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
              Text(l10n.frequency, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: frecuencias.map((f) {
                  final selected = frecuenciaSeleccionada == f;
                  return GestureDetector(
                    onTap: () => setModalState(() => frecuenciaSeleccionada = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF7C6AF7) : const Color(0xFF0F0F14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(f, style: TextStyle(
                        color: selected ? Colors.white : Colors.white54,
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(l10n.iconPickerLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _iconos(l10n).asMap().entries.map((entry) {
                  final selected = iconoSeleccionado == entry.key;
                  return GestureDetector(
                    onTap: () => setModalState(() => iconoSeleccionado = entry.key),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF7C6AF7) : const Color(0xFF0F0F14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(entry.value['icon'] as IconData, color: Colors.white, size: 22),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nombreController.text.isEmpty) return;
                    final data = {
                      'nombre': nombreController.text,
                      'hora': horaController.text,
                      'icono': iconoSeleccionado,
                      'frecuencia': frecuenciaSeleccionada,
                      'done': false,
                      'userId': user!.uid,
                    };
                    if (docId != null) {
                      await _db.collection('habitos').doc(docId).update(data);
                    } else {
                      await _db.collection('habitos').add(data);
                    }
                    if (horaController.text.isNotEmpty) {
                      await NotificacionesService.programarNotificacionHabito(
                        id: (docId ?? nombreController.text).hashCode.abs(),
                        nombre: nombreController.text,
                        hora: horaController.text,
                      );
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6AF7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(habito == null ? l10n.addHabitBtn : l10n.saveChanges,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final iconos = _iconos(l10n);
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        title: Text(l10n.myHabits, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Color(0xFF7C6AF7)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorialPage())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        backgroundColor: const Color(0xFF7C6AF7),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('habitos')
            .where('userId', isEqualTo: user!.uid)
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
                  const Icon(Icons.check_circle_outline, color: Colors.white24, size: 60),
                  const SizedBox(height: 12),
                  Text(l10n.noHabits, style: const TextStyle(color: Colors.white38)),
                  Text(l10n.tapPlusToAdd, style: const TextStyle(color: Colors.white24, fontSize: 12)),
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
              final iconoIndex = data['icono'] ?? 0;
              final icono = iconos[iconoIndex < iconos.length ? iconoIndex : 0]['icon'] as IconData;
              final frecuencia = data['frecuencia'] ?? l10n.freqDaily;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: data['done'] == true ? const Color(0xFF14201E) : const Color(0xFF1E1E2A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: data['done'] == true
                        ? const Color(0xFF5DE0C5).withOpacity(0.5)
                        : const Color(0xFF2E2E3E),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: const Color(0xFF1A1A40), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icono, color: const Color(0xFF7C6AF7), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['nombre'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          Row(
                            children: [
                              Text(data['hora'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              if (data['hora']?.isNotEmpty == true) const Text(' · ', style: TextStyle(color: Colors.white24, fontSize: 11)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C6AF7).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(frecuencia, style: const TextStyle(color: Color(0xFF7C6AF7), fontSize: 10)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _marcarHabito(doc, data),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: data['done'] == true ? const Color(0xFF5DE0C5) : Colors.transparent,
                        child: data['done'] == true
                            ? const Icon(Icons.check, size: 14, color: Color(0xFF0A1A17))
                            : Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24))),
                      ),
                    ),
                    PopupMenuButton(
                      iconColor: Colors.white38,
                      color: const Color(0xFF1E1E2A),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          child: Text(l10n.edit, style: const TextStyle(color: Colors.white)),
                          onTap: () => Future.delayed(Duration.zero,
                              () => _mostrarFormulario(habito: data, docId: doc.id)),
                        ),
                        PopupMenuItem(
                          child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
                          onTap: () {
                            NotificacionesService.cancelarNotificacion(doc.id.hashCode.abs());
                            _db.collection('habitos').doc(doc.id).delete();
                          },
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
