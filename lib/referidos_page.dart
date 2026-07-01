import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'services/referidos_service.dart';
import 'l10n_helper.dart';

class ReferidosPage extends StatefulWidget {
  const ReferidosPage({super.key});
  @override
  State<ReferidosPage> createState() => _ReferidosPageState();
}

class _ReferidosPageState extends State<ReferidosPage> {
  final _user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;

  String _codigo = '';
  bool _cargando = true;
  bool _codigoAplicado = false;
  List<Map<String, dynamic>> _historial = [];
  int _totalMonedas = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final results = await Future.wait([
        ReferidosService.generarOObtenerCodigo(),
        ReferidosService.obtenerHistorial(),
      ]);
      final codigo = results[0] as String;
      final historial = results[1] as List<Map<String, dynamic>>;

      bool yaAplico = false;
      if (_user != null) {
        final doc = await _db.collection('perfiles').doc(_user!.uid).get();
        yaAplico = doc.data()?['codigoReferidoUsado'] != null;
      }

      if (mounted) {
        setState(() {
          _codigo = codigo;
          _historial = historial;
          _totalMonedas = historial.fold<int>(
              0, (sum, e) => sum + (e['monedasReferidor'] as int? ?? 0));
          _codigoAplicado = yaAplico;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _copiar() async {
    if (_codigo.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _codigo));
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.l10n.refCodeCopied),
      backgroundColor: const Color(0xFF5DE0C5),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _compartir() async {
    if (_codigo.isEmpty) return;
    final texto = context.l10n.refShareText(_codigo);
    // sharePositionOrigin es requerido en iPad para anclar el popover;
    // en Android se ignora.
    final box = context.findRenderObject() as RenderBox?;
    try {
      await Share.share(
        texto,
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (_) {
      // Si no hay app para compartir (o el share falla), copiamos al
      // portapapeles como respaldo para que el botón nunca quede "muerto".
      await Clipboard.setData(ClipboardData(text: texto));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.refCodeCopied),
        backgroundColor: const Color(0xFF5DE0C5),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _mostrarDialogoAplicar() async {
    final l10n = context.l10n;
    final ctrl = TextEditingController();
    bool aplicando = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.refApplyTitle,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ctrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
                color: Colors.white,
                letterSpacing: 2,
                fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: l10n.refApplyHint,
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: const Color(0xFF0F0F14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF7C6AF7)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: aplicando ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancel,
                  style: const TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6AF7),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: aplicando
                  ? null
                  : () async {
                      setS(() => aplicando = true);
                      final resultado =
                          await ReferidosService.aplicarCodigo(ctrl.text);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      final msg = switch (resultado) {
                        'ok' => l10n.refApplyOk,
                        'ya_usado' => l10n.refApplyAlreadyUsed,
                        'invalido' => l10n.refApplyInvalid,
                        'propio' => l10n.refApplyOwn,
                        _ => l10n.refApplyError,
                      };
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(msg),
                          backgroundColor: resultado == 'ok'
                              ? const Color(0xFF5DE0C5)
                              : const Color(0xFF2A2A3E),
                          duration: const Duration(seconds: 3),
                        ));
                        if (resultado == 'ok') _cargar();
                      }
                    },
              child: aplicando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(l10n.refApplyBtn,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(l10n.refTitle,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C6AF7)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCodigoCard(l10n),
                  const SizedBox(height: 24),
                  _buildComoFunciona(l10n),
                  const SizedBox(height: 24),
                  if (!_codigoAplicado) ...[
                    _buildBotonAplicar(l10n),
                    const SizedBox(height: 24),
                  ],
                  _buildHistorial(l10n),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildCodigoCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1F5E), Color(0xFF1A3040)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF7C6AF7).withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            l10n.refMyCode,
            style: const TextStyle(
                color: Colors.white54, fontSize: 12, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            _codigo.isEmpty ? '...' : _codigo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _codigo.isEmpty ? null : _copiar,
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(l10n.refCopyCode),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _codigo.isEmpty ? null : _compartir,
                  icon: const Icon(Icons.share, size: 16),
                  label: Text(l10n.refShareCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6AF7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          if (_totalMonedas > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    l10n.refTotalCoins(_totalMonedas),
                    style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComoFunciona(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.refHowItWorks,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _paso('1️⃣', l10n.refStep1),
        const SizedBox(height: 8),
        _paso('2️⃣', l10n.refStep2),
        const SizedBox(height: 8),
        _paso('3️⃣', l10n.refStep3),
      ],
    );
  }

  Widget _paso(String emoji, String texto) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonAplicar(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _mostrarDialogoAplicar,
        icon: const Icon(Icons.card_giftcard, color: Color(0xFF5DE0C5)),
        label: Text(l10n.refApplyCode,
            style: const TextStyle(
                color: Color(0xFF5DE0C5), fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF5DE0C5)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildHistorial(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.refHistory,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        if (_historial.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text('👥', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 12),
                Text(l10n.refNoHistory,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 6),
                Text(l10n.refNoHistoryDesc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12, height: 1.5)),
              ],
            ),
          )
        else
          ..._historial.map((item) => _buildReferidoItem(item, l10n)),
      ],
    );
  }

  Widget _buildReferidoItem(Map<String, dynamic> item, AppLocalizations l10n) {
    final nombre = item['nombre'] as String? ?? 'Usuario';
    final fecha = (item['fecha'] as Timestamp?)?.toDate();
    final monedas = item['monedasReferidor'] as int? ?? 0;
    final fechaStr = fecha != null
        ? '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF5DE0C5).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF5DE0C5).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Center(child: Text('🎓', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre.split(' ').first,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                if (fechaStr.isNotEmpty)
                  Text(l10n.refFriendJoined(fechaStr),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 3),
                Text('+$monedas',
                    style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
