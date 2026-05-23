// Datei: lib/data/db/tables/property_definitions.dart
//
// ZWECK: EAV-Schema für benutzerdefinierte Eigenschaften (wie Obsidian-Properties).
//        PropertyDefinitions beschreiben Art und Name eines Feldes; EntryProperties
//        speichern die konkreten Werte pro Eintrag.
// PHASE: 3 – Properties und Templates.

import 'package:drift/drift.dart';

/// Alle unterstützten Property-Typen.
///
/// WARUM als Dart-Enum statt TEXT-Constraint in SQLite?
/// Dart-Enum gibt Typ-Sicherheit im Code und verhindert Tippfehler.
/// Der gespeicherte String ist der Enum-Name (z. B. 'tags', 'link').
enum PropertyFieldType {
  /// Einfacher Text
  text,

  /// Ganzzahl oder Dezimalzahl
  number,

  /// Datum (ohne Uhrzeit)
  date,

  /// Ja/Nein-Schalter
  boolean,

  /// Externe URL
  url,

  /// Liste freier Tag-Strings – KEIN Bezug zu #hashtags im Body.
  /// Nur für dieses Property-Feld gedacht (wie Obsidian-Tags-Property).
  tags,

  /// Interner Link (andere Eintrag-UUID) oder externer Link (URL).
  /// Gespeichert als JSON: {"type":"internal","id":"uuid"} oder
  ///                       {"type":"external","url":"https://..."}
  link,

  /// Einfachauswahl aus vordefinierten Optionen (options-Feld)
  select,

  /// Mehrfachauswahl aus vordefinierten Optionen (options-Feld)
  multiselect,

  /// 0–5 Sterne-Bewertung
  rating,
}

/// Definition eines benutzerdefinierten Property-Feldes.
///
/// WARUM EAV (Entity-Attribute-Value) statt feste Spalten?
/// Der Nutzer soll eigene Felder definieren können (Obsidian-Style).
/// Feste Spalten wären nur für bekannte, unveränderliche Felder sinnvoll.
/// EAV erlaubt beliebige Felder ohne Schema-Migrationen.
class PropertyDefinitions extends Table {
  TextColumn get id => text()();

  /// Workspace-Zugehörigkeit.
  TextColumn get workspaceId =>
      text().withDefault(const Constant('default'))();

  /// Anzeigename des Feldes, z. B. 'Quelle', 'Status', 'Bewertung'.
  TextColumn get name => text()();

  /// Gespeicherter PropertyFieldType-Enum-Name.
  TextColumn get fieldType => text()();

  /// JSON-Array mit Auswahloptionen für select/multiselect und
  /// Vorschlagsliste für tags. Null bei anderen Typen.
  /// Beispiel: '["Entwurf","Aktiv","Fertig"]'
  TextColumn get options => text().nullable()();

  /// Reihenfolge in der Properties-Anzeige und im Edit-Panel.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Null = workspace-globale Definition (in allen Einträgen nutzbar).
  /// Gesetzt = gehört zu einem Template, erscheint beim Template-Auswählen.
  TextColumn get templateId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Konkrete Property-Werte für einen Eintrag.
class EntryProperties extends Table {
  TextColumn get id => text()();

  /// Zugehöriger Eintrag.
  TextColumn get entryId => text()();

  /// Die Feld-Definition (Name, Typ, Optionen).
  TextColumn get propertyId => text()();

  /// Wert als JSON-kodierter String:
  /// - text/url       → "\"mein Text\""
  /// - number         → "42" oder "3.14"
  /// - date           → "\"2025-12-31\""
  /// - boolean        → "true" / "false"
  /// - tags           → "[\"flutter\",\"dart\"]"
  /// - link (intern)  → "{\"type\":\"internal\",\"id\":\"uuid\"}"
  /// - link (extern)  → "{\"type\":\"external\",\"url\":\"https://...\"}"
  /// - select         → "\"Aktiv\""
  /// - multiselect    → "[\"A\",\"B\"]"
  /// - rating         → "3"
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
