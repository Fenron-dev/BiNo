// Datei: lib/data/db/tables/workspaces.dart
//
// ZWECK: Definiert die Workspaces-Tabelle. Ein Workspace ist ein vollständig
//        isolierter Datenbereich innerhalb derselben SQLite-DB – alle anderen
//        Tabellen referenzieren workspace_id. Standardmäßig existiert ein
//        Workspace ('default'), weitere können in Phase 4 angelegt werden.
// PHASE: 2 – Schema-Migration; UI-Verwaltung folgt in Phase 4.

import 'package:drift/drift.dart';

/// Oberste Organisationsebene: isolierter Datenbereich für alle Einträge,
/// Tags, Container und Properties.
class Workspaces extends Table {
  /// UUID-Primärschlüssel.
  TextColumn get id => text()();

  /// Anzeigename, z. B. 'Privat' oder 'Arbeit'.
  TextColumn get name => text()();

  /// Emoji oder Material-Icon-Name für die Workspace-Auswahl-UI.
  TextColumn get icon => text().withDefault(const Constant('📁'))();

  /// Hex-Akzentfarbe, z. B. '#6750A4'.
  TextColumn get color => text().withDefault(const Constant('#6750A4'))();

  /// Genau ein Workspace trägt isDefault = true: der beim Start geöffnete.
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  @override
  Set<Column> get primaryKey => {id};
}
