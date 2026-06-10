import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/bienestar_model.dart';
import 'services/bienestar_service.dart';

class BienestarPage extends StatefulWidget {
  const BienestarPage({super.key});

  @override
  State<BienestarPage> createState() => _BienestarPageState();
}

class _BienestarPageState extends State<BienestarPage> {
  final _user = FirebaseAuth.instance.currentUser;
  bool _cargando = true;
  RegistroBienestar? _registroHoy;

  // Check-in temporal
  int _animo = 3;
  int _estres = 3;
  double _horas = 4;
  bool _descansoBien = true;

  @override
  void initState() {
    super.initState();
    _cargarHoy();
  }

  Future<void> _cargarHoy() async {
    try {
      final r = await BienestarService.registroDeHoy();
      if (mounted) {
        setState(() {
          _registroHoy = r;
          if (r != null) {
            _animo = r.estadoAnimo;
            _estres = r.nivelEstres;
            _horas = r.horasEstudio;
            _descansoBien = r.descansoBien;
          }
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    final registro = RegistroBienestar(
      id: '',
      userId: _user?.uid ?? '',
      fecha: DateTime.now(),
      estadoAnimo: _animo,
      nivelEstres: _estres,
      horasEstudio: _horas,
      descansoBien: _descansoBien,
    );
    await BienestarService.guardar(registro);
    await _cargarHoy();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Check-in guardado! 💚'),
          backgroundColor: Color(0xFF1E1E2A),
        ),
      );
    }
  }

  Color _colorRiesgo(int riesgo) {
    if (riesgo < 25) return const Color(0xFF5DE0C5);
    if (riesgo < 50) return const Color(0xFF4A90E2);
    if (riesgo < 75) return const Color(0xFFF7A26A);
    return const Color(0xFFF7584A);
  }

  String _emojiAnimo(int v) {
    const e = ['😞', '😟', '😐', '🙂', '😄'];
    return e[(v - 1).clamp(0, 4)];
  }

  String _emojiEstres(int v) {
    const e = ['😌', '🙂', '😐', '😰', '🤯'];
    return e[(v - 1).clamp(0, 4)];
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F14),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF7C6AF7))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        title: const Text('Mi Bienestar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<RegistroBienestar>>(
        stream: BienestarService.stream7Dias(),
        builder: (context, snap) {
          final registros = snap.data ?? [];
          final riesgo = BienestarService.calcularRiesgoBurnout(registros);
          final nivel = BienestarService.nivelRiesgo(riesgo);
          final recos = BienestarService.recomendaciones(riesgo, registros);
          final colorR = _colorRiesgo(riesgo);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medidor de burnout
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorR.withOpacity(0.15),
                        const Color(0xFF0F0F14),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colorR.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Riesgo de Burnout',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorR.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: colorR.withOpacity(0.4)),
                            ),
                            child: Text(nivel,
                                style: TextStyle(
                                    color: colorR,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF252535),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: riesgo / 100,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  const Color(0xFF5DE0C5),
                                  colorR,
                                ]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$riesgo / 100',
                              style: TextStyle(
                                  color: colorR,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const Text('Basado en últimos 7 días',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Recomendaciones
                const Text('RECOMENDACIONES',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const SizedBox(height: 10),
                ...recos.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡',
                              style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(r,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.4)),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),

                // Check-in del día
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF5DE0C5).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Check-in de hoy',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          if (_registroHoy != null)
                            const Text('✅ Registrado',
                                style: TextStyle(
                                    color: Color(0xFF5DE0C5), fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Estado de ánimo
                      Text(
                        'Estado de ánimo ${_emojiAnimo(_animo)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _animo = i + 1),
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: _animo == i + 1
                                      ? const Color(0xFF7C6AF7)
                                          .withOpacity(0.3)
                                      : const Color(0xFF252535),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _animo == i + 1
                                        ? const Color(0xFF7C6AF7)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  _emojiAnimo(i + 1),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Nivel de estrés
                      Text(
                        'Nivel de estrés ${_emojiEstres(_estres)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _estres = i + 1),
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: _estres == i + 1
                                      ? const Color(0xFFF7584A)
                                          .withOpacity(0.2)
                                      : const Color(0xFF252535),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _estres == i + 1
                                        ? const Color(0xFFF7584A)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  _emojiEstres(i + 1),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Horas de estudio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Horas de estudio hoy',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          Text('${_horas.toStringAsFixed(0)}h',
                              style: const TextStyle(
                                  color: Color(0xFF7C6AF7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ],
                      ),
                      Slider(
                        value: _horas,
                        min: 0,
                        max: 14,
                        divisions: 14,
                        activeColor: const Color(0xFF7C6AF7),
                        inactiveColor: const Color(0xFF252535),
                        onChanged: (v) => setState(() => _horas = v),
                      ),
                      const SizedBox(height: 10),

                      // Descanso
                      GestureDetector(
                        onTap: () =>
                            setState(() => _descansoBien = !_descansoBien),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _descansoBien
                                ? const Color(0xFF5DE0C5).withOpacity(0.1)
                                : const Color(0xFF252535),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _descansoBien
                                    ? const Color(0xFF5DE0C5).withOpacity(0.4)
                                    : const Color(0xFF3D3D5E)),
                          ),
                          child: Row(
                            children: [
                              Text(_descansoBien ? '😴' : '🥱',
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _descansoBien
                                      ? 'Dormí bien anoche'
                                      : 'No descansé bien',
                                  style: TextStyle(
                                      color: _descansoBien
                                          ? const Color(0xFF5DE0C5)
                                          : Colors.white54,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Icon(
                                _descansoBien
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: _descansoBien
                                    ? const Color(0xFF5DE0C5)
                                    : Colors.white38,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      GestureDetector(
                        onTap: _guardar,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF5DE0C5),
                                  Color(0xFF3AA890)
                                ]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('Guardar check-in',
                                style: TextStyle(
                                    color: Color(0xFF0A1A17),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Historial 7 días
                if (registros.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('ÚLTIMOS 7 DÍAS',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  const SizedBox(height: 12),
                  ...registros.map((r) {
                    final rb = r.puntajeBurnout;
                    final cr = _colorRiesgo(rb);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(_emojiAnimo(r.estadoAnimo),
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${r.fecha.day}/${r.fecha.month}  ·  ${r.horasEstudio.toStringAsFixed(0)}h estudio',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                                Text(
                                  'Estrés: ${_emojiEstres(r.nivelEstres)}  ·  ${r.descansoBien ? "Descansé bien" : "Mal sueño"}',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cr.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$rb',
                                style: TextStyle(
                                    color: cr,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
