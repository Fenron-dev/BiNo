// Datei: lib/data/db/tables/templates.dart
//
// ZWECK: Vorlagen für Einträge. Ein Template bündelt PropertyDefinitions und
//        Standardwerte – der Nutzer wählt beim Erfassen ein Template aus,
//        das die Properties vorausfüllt.
// PHASE: 3 – Templates und Properties.

import 'package:drift/drift.dart';

/// Vorlage mit vordefinierten Properties und Standardwerten.
///
/// BEISPIEL: Template 'Buchnotiz'
///   propertyIds:    ["prop-author", "prop-rating", "prop-genre"]
///   defaultValues:  {"prop-rating": "0", "prop-genre": "\"Sachbuch\""}
///
/// Der Nutzer wählt beim Capture 'Buchnotiz' → die drei Property-Felder
/// erscheinen im Edit-Panel, Rating und Genre sind vorausgefüllt.
class Templates extends Table {
  TextColumn get id => text()();

  TextColumn get workspaceId =>
      text().withDefault(const Constant('default'))();

  /// Anzeigename, z. B. 'Buchnotiz', 'Meeting', 'Idee'.
  TextColumn get name => text()();

  /// Emoji oder Material-Icon-Name.
  TextColumn get icon => text().withDefault(const Constant('📋'))();

  TextColumn get description => text().nullable()();

  /// Geordnetes JSON-Array von PropertyDefinition-IDs, die zu diesem
  /// Template gehören. Reihenfolge bestimmt die Anzeige-Reihenfolge.
  /// Beispiel: '["prop-abc","prop-def"]'
  TextColumn get propertyIds =>
      text().withDefault(const Constant('[]'))();

  /// JSON-Objekt: propertyId → vorausgefüllter Wert (JSON-kodiert).
  /// Leere Map wenn keine Standardwerte. Beispiel:
  /// '{"prop-rating":"0","prop-genre":"\"Sachbuch\""}'
  TextColumn get defaultValues =>
      text().withDefault(const Constant('{}'))();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  @override
  Set<Column> get primaryKey => {id};
}
