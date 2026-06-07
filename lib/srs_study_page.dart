import 'dart:math';
import 'package:flutter/material.dart';
import 'models/flashcard_srs_model.dart';
import 'services/srs_service.dart';

class SRSStudyPage extends StatefulWidget {
  final List<FlashcardSRS> cards;
  final String titulo;

  const SRSStudyPage({super.key, required this.cards, required this.titulo});

  @override
  State<SRSStudyPage> createState() => _SRSStudyPageState();
}

class _SRSStudyPageState extends State<SRSStudyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _mostrandoRespuesta = false;
  int _indice = 0;
  int _correctas = 0;
  bool _terminado = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _anim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _voltear() {
    if (_mostrandoRespuesta) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() => _mostrandoRespuesta = !_mostrandoRespuesta);
  }

  Future<void> _calificar(int calidad) async {
    await SRSService.registrarRespuesta(widget.cards[_indice], calidad);
    if (calidad >= 2) _correctas++;

    if (_indice < widget.cards.length - 1) {
      await _ctrl.reverse();
      setState(() {
        _indice++;
        _mostrandoRespuesta = false;
      });
    } else {
      setState(() => _terminado = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_terminado) return _buildResultados();

    final card = widget.cards[_indice];
    final progreso = _indice / widget.cards.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        title: Text(widget.titulo,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('${_indice + 1}/${widget.cards.length}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ),
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
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _voltear,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) {
                    final isBack = _anim.value >= 0.5;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(pi * _anim.value),
                      child: isBack
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: _cardBack(card),
                            )
                          : _cardFront(card),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _mostrandoRespuesta
                ? _botonesCalificar()
                : _botonVoltear(),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _cardFront(FlashcardSRS card) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C6AF7).withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz_outlined, color: Color(0xFF7C6AF7), size: 34),
          const SizedBox(height: 18),
          const Text('PREGUNTA',
              style: TextStyle(
                  color: Color(0xFF7C6AF7),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              card.pregunta,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.4),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Toca para ver la respuesta',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _cardBack(FlashcardSRS card) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5DE0C5).withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5DE0C5).withOpacity(0.06),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFF5DE0C5), size: 34),
          const SizedBox(height: 18),
          const Text('RESPUESTA',
              style: TextStyle(
                  color: Color(0xFF5DE0C5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              card.respuesta,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonVoltear() {
    return Padding(
      key: const ValueKey('voltear'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _voltear,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF7C6AF7), Color(0xFF5A4ED4)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flip, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Ver respuesta',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonesCalificar() {
    return Padding(
      key: const ValueKey('calificar'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('¿Qué tan bien la sabías?',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              _btnCal('😟', 'Olvidé', const Color(0xFFF7584A), 0),
              const SizedBox(width: 8),
              _btnCal('😅', 'Difícil', const Color(0xFFF7A26A), 1),
              const SizedBox(width: 8),
              _btnCal('🙂', 'Regular', const Color(0xFF4A90E2), 2),
              const SizedBox(width: 8),
              _btnCal('😄', 'Fácil', const Color(0xFF5DE0C5), 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btnCal(String emoji, String label, Color color, int calidad) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _calificar(calidad),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultados() {
    final total = widget.cards.length;
    final pct = total == 0 ? 0 : (_correctas / total * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pct >= 80 ? '🎉' : pct >= 50 ? '💪' : '📚',
                style: const TextStyle(fontSize: 72),
              ),
              const SizedBox(height: 20),
              const Text('¡Sesión completada!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('$_correctas de $total correctas ($pct%)',
                  style: const TextStyle(color: Colors.white54, fontSize: 16)),
              const SizedBox(height: 40),
              _stat('Total revisadas', '$total', const Color(0xFF7C6AF7)),
              const SizedBox(height: 10),
              _stat('Correctas', '$_correctas', const Color(0xFF5DE0C5)),
              const SizedBox(height: 10),
              _stat('Para repasar pronto', '${total - _correctas}',
                  const Color(0xFFF7A26A)),
              const SizedBox(height: 40),
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
                            fontSize: 15,
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

  Widget _stat(String label, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(valor,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
