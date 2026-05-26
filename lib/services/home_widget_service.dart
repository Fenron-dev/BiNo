// Datei: lib/services/home_widget_service.dart
//
// ZWECK: Aktualisiert das Android Homescreen-Widget mit dem letzten Eintrag.
// ABHÄNGIGKEITEN: home_widget, intl.
// MUSTER: Service – zustandslos, alle Methoden statisch.
// PHASE: 6 – Homescreen-Widget.

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class HomeWidgetService {
  // qualifiedAndroidName = vollständiger Klassenname inkl. Package-Prefix.
  static const _androidProviderName =
      'dev.fenron.bino_bit_notes.BiNoWidgetProvider';

  /// Speichert den letzten Eintrag und aktualisiert alle Widget-Instanzen.
  ///
  /// [body] wird auf 120 Zeichen gekürzt, damit der Text im Widget-Layout
  /// in maxLines: 3 sauber dargestellt wird.
  /// [createdAt] wird als lokaler Zeitstempel formatiert.
  static Future<void> update({
    required String body,
    required DateTime createdAt,
  }) async {
    final preview = body.length > 120 ? '${body.substring(0, 120)}…' : body;
    final timestamp = DateFormat('dd.MM.yyyy, HH:mm', 'de_DE')
        .format(createdAt.toLocal());

    await HomeWidget.saveWidgetData<String>('widget_last_body', preview);
    await HomeWidget.saveWidgetData<String>('widget_last_timestamp', timestamp);
    await HomeWidget.updateWidget(qualifiedAndroidName: _androidProviderName);
  }

  /// Setzt das Widget auf den Leer-Zustand (kein Eintrag vorhanden).
  static Future<void> clear() async {
    await HomeWidget.saveWidgetData<String>(
        'widget_last_body', 'Tippe auf ＋ Notiz um loszulegen');
    await HomeWidget.saveWidgetData<String>('widget_last_timestamp', '');
    await HomeWidget.updateWidget(qualifiedAndroidName: _androidProviderName);
  }
}
