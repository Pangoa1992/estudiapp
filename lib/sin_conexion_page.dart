import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SinConexionPage extends StatefulWidget {
  final Widget child;
  const SinConexionPage({super.key, required this.child});

  @override
  State<SinConexionPage> createState() => _SinConexionPageState();
}

class _SinConexionPageState extends State<SinConexionPage>
    with SingleTickerProviderStateMixin {
  bool _sinConexion = false;
  late AnimationController _animController;
  late Animation<double> _bannerAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bannerAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _verificarConexion();
    Connectivity().onConnectivityChanged.listen((results) {
      final sinInternet = results.every((r) => r == ConnectivityResult.none);
      if (mounted) {
        setState(() => _sinConexion = sinInternet);
        if (sinInternet) {
          _animController.forward();
        } else {
          _animController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _verificarConexion() async {
    final results = await Connectivity().checkConnectivity();
    final sinInternet = results.every((r) => r == ConnectivityResult.none);
    if (mounted) {
      setState(() => _sinConexion = sinInternet);
      if (sinInternet) _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Siempre muestra el contenido — Firestore usa caché offline automáticamente
    return Stack(
      children: [
        widget.child,
        // Banner de sin conexión (solo cuando no hay internet)
        if (_sinConexion)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizeTransition(
              sizeFactor: _bannerAnim,
              axisAlignment: -1,
              child: SafeArea(
                bottom: false,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF7A26A).withOpacity(0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('📡', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sin conexión — Modo offline',
                                style: TextStyle(
                                  color: Color(0xFFF7A26A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Mostrando datos del último acceso',
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _verificarConexion,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7A26A).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Reintentar',
                              style: TextStyle(
                                color: Color(0xFFF7A26A),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
