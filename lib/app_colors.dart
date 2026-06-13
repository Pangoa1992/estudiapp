import 'package:flutter/material.dart';

/// Colores de acento globales de la app.
class AppC {
  static const purple = Color(0xFF7C6AF7);
  static const purpleDark = Color(0xFF5A4ED4);
  static const teal = Color(0xFF5DE0C5);
  static const orange = Color(0xFFF7A26A);
  static const red = Color(0xFFF7584A);
  static const gold = Color(0xFFFFD700);
  static const blue = Color(0xFF4A90E2);

  static const streakGradient = LinearGradient(
    colors: [Color(0xFF2A1F5E), Color(0xFF1F3A35)],
  );

  static const purpleGradient = LinearGradient(
    colors: [Color(0xFF7C6AF7), Color(0xFF5A4ED4)],
  );

  static const tealGradient = LinearGradient(
    colors: [Color(0xFF5DE0C5), Color(0xFF3BB8A0)],
  );
}

/// Colores semánticos según el tema activo (oscuro / claro).
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgPrimary => isDark ? const Color(0xFF0F0F14) : const Color(0xFFF0F0F8);
  Color get bgCard => isDark ? const Color(0xFF1E1E2A) : Colors.white;
  Color get bgCard2 => isDark ? const Color(0xFF252535) : const Color(0xFFF8F8FF);

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1A1A2E);
  Color get textSecondary => isDark ? Colors.white54 : const Color(0xFF6B6B8A);
  Color get textTertiary => isDark ? Colors.white30 : const Color(0xFFAAAAAA);

  Color get borderPrimary => isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE0E0F0);
  Color get borderSecondary => isDark ? const Color(0xFF252535) : const Color(0xFFEEEEFF);

  Color get iconColor => isDark ? Colors.white70 : const Color(0xFF4A4A6A);

  // ── Sombras ──────────────────────────────────────────────────────────────

  /// Sombra suave para cards normales.
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppC.purple.withOpacity(isDark ? 0.08 : 0.13),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Sombra prominente para cards destacadas (racha, CTA principal).
  List<BoxShadow> get cardShadowStrong => [
        BoxShadow(
          color: AppC.purple.withOpacity(isDark ? 0.18 : 0.25),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.30 : 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // ── Gradiente de fondo ────────────────────────────────────────────────────

  Gradient get bgGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF0F0F14), const Color(0xFF14101E)]
            : [const Color(0xFFF0F0F8), const Color(0xFFE8E8FA)],
      );
}
