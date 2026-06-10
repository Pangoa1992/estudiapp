import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/flashcard_srs_model.dart';
import 'services/srs_service.dart';
import 'srs_study_page.dart';

class SRSDecksPage extends StatefulWidget {
  const SRSDecksPage({super.key});

  @override
  State<SRSDecksPage> createState() => _SRSDecksPageState();
}

class _SRSDecksPageState extends State<SRSDecksPage> {
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  void _abrirAgregar() async {
    final cursosSnap = await _db
        .collection('cursos')
        .where('userId', isEqualTo: _user?.uid)
        .get();
    if (!mounted) return;
    _dialogoAgregar(cursosSnap.docs);
  }

  Future<void> _dialogoAgregar(List<QueryDocumentSnapshot> cursos) async {
    final preguntaCtrl = TextEditingController();
    final respuestaCtrl = TextEditingController();
    String? cursoId;
    String? cursoNombre;

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
              const Text('Nueva flashcard',
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
                  cursoNombre = (cursos
                      .firstWhere((c) => c.id == val)
                      .data() as Map<String, dynamic>)['nombre'];
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: preguntaCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: _deco('Pregunta'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: respuestaCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: _deco('Respuesta'),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  if (cursoId == null ||
                      preguntaCtrl.text.trim().isEmpty ||
                      respuestaCtrl.text.trim().isEmpty) return;
                  await SRSService.guardar(FlashcardSRS(
                    id: '',
                    pregunta: preguntaCtrl.text.trim(),
                    respuesta: respuestaCtrl.text.trim(),
                    cursoId: cursoId!,
                    cursoNombre: cursoNombre ?? '',
                    userId: _user?.uid ?? '',
                    proximaRevision: DateTime.now(),
                    creadoEn: DateTime.now(),
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
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF3D3D5E))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF7C6AF7))),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        title: const Text('Flashcards SRS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF7C6AF7)),
            onPressed: _abrirAgregar,
          ),
        ],
      ),
      body: StreamBuilder<List<FlashcardSRS>>(
        stream: SRSService.streamTodas(),
        builder: (context, snap) {
          final todas = snap.data ?? [];

          return StreamBuilder<List<FlashcardSRS>>(
            stream: SRSService.streamParaHoy(),
            builder: (context, snapHoy) {
              final paraHoy = snapHoy.data ?? [];

              // Agrupar por curso
              final porCurso = <String, _DatoMazo>{};
              for (final c in todas) {
                porCurso.putIfAbsent(
                    c.cursoId, () => _DatoMazo(nombre: c.cursoNombre));
                porCurso[c.cursoId]!.total++;
              }
              for (final c in paraHoy) {
                if (porCurso.containsKey(c.cursoId)) {
                  porCurso[c.cursoId]!.hoy++;
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner repaso del día
                    if (paraHoy.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () {
                          final mezcladas = [...paraHoy]..shuffle();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SRSStudyPage(
                                cards: mezcladas,
                                titulo: 'Repaso del día',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              Color(0xFF2A1F5E),
                              Color(0xFF1F3A4A)
                            ]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    const Color(0xFF7C6AF7).withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Text('🧠',
                                  style: TextStyle(fontSize: 36)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${paraHoy.length} tarjetas para hoy',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Text('Toca para empezar →',
                                        style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C6AF7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Estudiar',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Text('MIS MAZOS',
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
                              Text('🃏', style: TextStyle(fontSize: 40)),
                              SizedBox(height: 12),
                              Text('Aún no tienes flashcards',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text(
                                'Agrégalas con el + o pídele a la IA que genere flashcards\nen la sección "Estudiar con IA".',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...porCurso.entries.map((e) {
                        final cursoId = e.key;
                        final info = e.value;
                        return GestureDetector(
                          onTap: () async {
                            final cards =
                                await SRSService.obtenerParaHoyPorCurso(
                                    cursoId);
                            if (!context.mounted) return;
                            if (cards.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Sin tarjetas pendientes en este mazo ✅'),
                                  backgroundColor: Color(0xFF1E1E2A),
                                ),
                              );
                              return;
                            }
                            cards.shuffle();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SRSStudyPage(
                                  cards: cards,
                                  titulo: info.nombre,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: info.hoy > 0
                                    ? const Color(0xFF7C6AF7).withOpacity(0.4)
                                    : const Color(0xFF2E2E3E),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C6AF7)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.style,
                                      color: Color(0xFF7C6AF7), size: 22),
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
                                      Text('${info.total} tarjetas',
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (info.hoy > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C6AF7)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('${info.hoy} hoy',
                                        style: const TextStyle(
                                            color: Color(0xFF7C6AF7),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  )
                                else
                                  const Icon(Icons.check_circle_outline,
                                      color: Color(0xFF5DE0C5), size: 20),
                              ],
                            ),
                          ),
                        );
                      }),
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

class _DatoMazo {
  final String nombre;
  int total = 0;
  int hoy = 0;
  _DatoMazo({required this.nombre});
}
