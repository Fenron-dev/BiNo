// Datei: lib/core/constants.dart
//
// ZWECK: App-weite Konstanten, die an mehreren Stellen genutzt werden.
//        Zentralisierung verhindert Magic Strings/Numbers im Code.
// ABHÄNGIGKEITEN: Keine.
// PHASE: 1 – Grundgerüst.

/// App-weite Konstanten.
abstract class AppConstants {
  /// Name der SQLite-Datenbankdatei (ohne Pfad).
  static const String dbName = 'bino_notes';

  /// Maximale Anzahl angepinnter Einträge im Feed (UI-Begrenzung).
  static const int maxPinnedEntries = 5;

  /// Maximale Anzahl sichtbarer Hub-Tabs in der Bottom-Navigation.
  /// Weitere Tabs landen im "Mehr"-Menü (Phase 4).
  static const int maxVisibleHubTabs = 4;

  /// App-Name für UI-Anzeigen und Benachrichtigungen.
  static const String appName = 'BiNo';

  /// Vollständiger App-Name.
  static const String appNameFull = 'BiNo – Bit Notes';
}

/// Routen-Pfade für go_router.
/// WARUM Konstanten statt direkte Strings?
/// Tipp-Fehler in Routen führen zu Laufzeit-Fehlern, die schwer zu debuggen sind.
/// Konstanten werden vom Compiler geprüft.
abstract class AppRoutes {
  static const String feed = '/feed';
  static const String projects = '/projects';
  static const String areas = '/areas';

  static const String settings = '/settings';

  // Phase 3+:
  // static const String entryDetail = '/entry/:id';
  // static const String search = '/search';
}
