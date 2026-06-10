import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/monedas_service.dart';
import 'tema_service.dart';

class TiendaPage extends StatefulWidget {
  const TiendaPage({super.key});
  @override
  State<TiendaPage> createState() => _TiendaPageState();
}

class _TiendaPageState extends State<TiendaPage> {
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;
  bool _comprando = false;

  Future<void> _comprar({
    required int precio,
    required String titulo,
    required Future<void> Function() accion,
  }) async {
    if (_comprando) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Comprar $titulo?',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪙', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text('$precio monedas',
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _comprando = true);
    try {
      final ok = await MonedasService.gastar(precio);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🪙 Monedas insuficientes'),
            backgroundColor: Color(0xFFF7584A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      await accion();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $titulo activado'),
          backgroundColor: const Color(0xFF5DE0C5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _comprando = false);
    }
  }

  Future<void> _accionEscudo() async {
    if (_user == null) return;
    await _db.collection('perfiles').doc(_user!.uid).update(
      {'escudos': FieldValue.increment(1)},
    );
  }

  Future<void> _accionBoostRacha() async {
    if (_user == null) return;
    final hasta = DateTime.now().add(const Duration(hours: 24));
    await _db.collection('perfiles').doc(_user!.uid).update(
      {'boost_racha_hasta': Timestamp.fromDate(hasta)},
    );
  }

  Future<void> _accionTemaOscuro() async {
    if (_user == null) return;
    await _db.collection('perfiles').doc(_user!.uid).update(
      {'tema_oscuro_desbloqueado': true},
    );
    await TemaService.setModo(ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Tienda',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (_user != null)
            StreamBuilder<DocumentSnapshot>(
              stream: _db.collection('perfiles').doc(_user!.uid).snapshots(),
              builder: (context, snap) {
                final monedas =
                    ((snap.data?.data() as Map?)?['monedas'] as num? ?? 0).toInt();
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.5)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Text('🪙', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text('$monedas',
                            style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ]),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final items = [
      _TiendaItem(
        emoji: '🛡️',
        titulo: 'Escudo Extra',
        descripcion: 'Protege tu racha un día adicional sin perderla',
        precio: MonedasService.precioEscudo,
        onTap: () => _comprar(
          precio: MonedasService.precioEscudo,
          titulo: 'Escudo Extra',
          accion: _accionEscudo,
        ),
      ),
      _TiendaItem(
        emoji: '🚀',
        titulo: 'Boost de Racha x2',
        descripcion: 'Duplica las monedas de racha diaria durante 24 horas',
        precio: MonedasService.precioBoostRacha,
        onTap: () => _comprar(
          precio: MonedasService.precioBoostRacha,
          titulo: 'Boost de Racha x2',
          accion: _accionBoostRacha,
        ),
      ),
      _TiendaItem(
        emoji: '🌙',
        titulo: 'Tema Oscuro Premium',
        descripcion: 'Activa el tema oscuro especial de la app',
        precio: MonedasService.precioTemaOscuro,
        onTap: () => _comprar(
          precio: MonedasService.precioTemaOscuro,
          titulo: 'Tema Oscuro Premium',
          accion: _accionTemaOscuro,
        ),
      ),
    ];

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Canjea tus monedas por recompensas exclusivas',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildComoGanarInfo(),
            const SizedBox(height: 20),
            ...items.map(_buildItem),
          ],
        ),
        if (_comprando)
          const ColoredBox(
            color: Colors.black54,
            child: Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
          ),
      ],
    );
  }

  Widget _buildComoGanarInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Cómo ganar 🪙?',
              style: TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._ganancias.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Text(g.$1,
                      style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(g.$2,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                ]),
              )),
        ],
      ),
    );
  }

  static const _ganancias = [
    ('+10', 'Completar sesión Pomodoro'),
    ('+20', 'Completar un simulacro'),
    ('+50', 'Sacar puntaje perfecto en simulacro'),
    ('+15', 'Mantener racha diaria'),
    ('+5', 'Usar herramienta de IA'),
    ('+10~200', 'Recompensa diaria al abrir la app'),
  ];

  Widget _buildItem(_TiendaItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFFFD700).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 38)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.titulo,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(item.descripcion,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: item.onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🪙 ${item.precio}',
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const Text('Canjear',
                      style: TextStyle(color: Colors.black87, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TiendaItem {
  final String emoji;
  final String titulo;
  final String descripcion;
  final int precio;
  final VoidCallback onTap;
  const _TiendaItem({
    required this.emoji,
    required this.titulo,
    required this.descripcion,
    required this.precio,
    required this.onTap,
  });
}
