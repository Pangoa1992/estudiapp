/// Configuración central de Unity Ads (reemplazó a Meta Audience Network en
/// v1.9.7, jul 2026).
///
/// Solo se integra Android. El Game ID viene de Unity Dashboard → Project
/// Settings. Los placement IDs son los que Unity crea por defecto al dar de
/// alta un proyecto; si en el dashboard los renombraste, actualízalos aquí.
class UnityAdsConfig {
  UnityAdsConfig._();

  /// Game ID de Android (Unity Dashboard).
  static const String gameId = '800104533';

  /// Banner en el home (main.dart, bottomNavigationBar).
  static const String banner = 'Banner_Android';

  /// Intersticial en ia_page.dart (cada 3 usos).
  static const String interstitial = 'Interstitial_Android';

  /// Video recompensado (+3 búsquedas en ia_page.dart / ia_limite_mixin.dart,
  /// +2 al terminar un simulacro). Mismo placement en todos los usos; el monto
  /// de la recompensa lo controla la app, no el anuncio.
  static const String rewarded = 'Rewarded_Android';
}
