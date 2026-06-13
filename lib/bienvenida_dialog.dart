import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n_helper.dart';

class BienvenidaDialog {
  static Future<void> mostrarSiCorresponde({
    required BuildContext context,
    required String nombre,
    required int racha,
    required int escudos,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final hoy = DateTime.now();
    final key = 'bienvenida_${hoy.year}_${hoy.month}_${hoy.day}';
    if (prefs.getBool(key) == true) return;
    await prefs.setBool(key, true);
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _BienvenidaContent(nombre: nombre, racha: racha, escudos: escudos),
    );
  }
}

String _emoji(int racha) {
  if (racha >= 30) return '👑';
  if (racha >= 7)  return '🔥';
  if (racha >= 1)  return '⚡';
  return '📚';
}

class _BienvenidaContent extends StatelessWidget {
  final String nombre;
  final int racha;
  final int escudos;

  const _BienvenidaContent({
    required this.nombre,
    required this.racha,
    required this.escudos,
  });

  String _fraseMotivacional(AppLocalizations l10n) {
    if (racha >= 100) return l10n.mot100(racha);
    if (racha >= 30)  return l10n.mot30(racha);
    if (racha >= 14)  return l10n.mot14;
    if (racha >= 7)   return l10n.mot7;
    if (racha >= 3)   return l10n.mot3;
    if (racha >= 1)   return l10n.mot1;
    return l10n.mot0;
  }

  String _saludo(AppLocalizations l10n) {
    final h = DateTime.now().hour;
    if (h < 12) return l10n.greetingMorning;
    if (h < 18) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tieneEscudo = escudos > 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1E2A), Color(0xFF2A1F5E)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_emoji(racha), style: const TextStyle(fontSize: 54)),
            const SizedBox(height: 10),
            Text(_saludo(l10n), style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              nombre,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF7C6AF7).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.3)),
              ),
              child: Text(
                _fraseMotivacional(l10n),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.45),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Pill(label: '🔥 ${l10n.streakDays(racha)}', color: const Color(0xFFF7A26A)),
                const SizedBox(width: 10),
                _Pill(
                  label: tieneEscudo ? '🛡️ ${l10n.shieldReady}' : '🛡️ ${l10n.shieldEmpty}',
                  color: tieneEscudo ? const Color(0xFF5DE0C5) : Colors.white30,
                ),
              ],
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C6AF7), Color(0xFF5A4ED4)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  l10n.welcomeStudy,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
