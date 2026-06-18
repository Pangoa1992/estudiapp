import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const _androidName = 'RachaWidgetProvider';

  static Future<void> actualizar({
    required int racha,
    required List<String> habitosHoy,
    int misionesPendientes = 0,
  }) async {
    try {
      final habStr = habitosHoy.isEmpty
          ? 'Sin habitos hoy'
          : habitosHoy.take(5).join('\n');
      await HomeWidget.saveWidgetData<String>('racha', racha.toString());
      await HomeWidget.saveWidgetData<String>('habitos_hoy', habStr);
      await HomeWidget.saveWidgetData<String>(
          'misiones_pendientes', misionesPendientes.toString());
      await HomeWidget.updateWidget(androidName: _androidName);
    } catch (_) {}
  }
}
