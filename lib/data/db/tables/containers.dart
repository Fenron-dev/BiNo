// Datei: lib/data/db/tables/containers.dart
//
// ZWECK: Definiert die generische Container-Tabelle (Projekte, Bereiche, Hub-Tabs)
//        und die Junction-Tabelle entry_containers.
// ABHÄNGIGKEITEN: Nur drift.
// PHASE: 1 – Deklaration; CRUD-UI folgt in Phase 4.

import 'package:drift/drift.dart';

// WARUM eine generische Container-Tabelle statt separate Projekte/Bereiche/Hubs?
// Alle drei sind semantisch dasselbe: ein benannter Behälter mit Icon, Farbe
// und einer Menge verknüpfter Einträge. Das Feld 'kind' unterscheidet sie.
// Das vermeidet drei identische Tabellen und vereinfacht Queries (z. B.
// "alle Container eines Nutzers" ist ein einziger SELECT).

// ACHTUNG: 'Container' ist kein reserviertes Dart-Keyword, aber dart:ui exportiert
// eine Container-Klasse. Um Namenskonflikte zu vermeiden, heißt die Klasse 'Containers'.

/// Generische Container-Tabelle für Projekte, Bereiche und Hub-Tabs.
class Containers extends Table {
  /// UUID-Primärschlüssel.
  TextColumn get id => text()();

  /// Art des Containers:
  /// - 'project': zeitlich begrenztes Vorhaben
  /// - 'area':    dauerhafter Lebensbereich (Arbeit, Hobby, ...)
  /// - 'hub':     dynamischer Filter-Tab (Phase 4), verknüpft mit filter_json
  TextColumn get kind => text()();

  TextColumn get name => text()();

  TextColumn get description => text().nullable()();

  /// Material-Icon-Name als String, z. B. 'folder' oder 'book'.
  /// Pflichtfeld – jeder Container braucht eine visuelle Identität.
  TextColumn get icon => text().withDefault(const Constant('folder'))();

  /// Hex-Akzentfarbe, z. B. '#6750A4'. Pflichtfeld für die Karten-Darstellung.
  TextColumn get color => text().withDefault(const Constant('#6750A4'))();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  /// WARUM 'archived' statt Löschen?
  /// Archivierte Container werden in der UI ausgeblendet, aber verknüpfte
  /// Einträge behalten ihre Container-Zuweisungen. Das verhindert verwaiste
  /// Einträge und ermöglicht Restore.
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  /// JSON-Filter-Definition für Hub-Tabs (Phase 4).
  /// Null für 'project' und 'area'. Bei 'hub': JSON gemäß FilterDefinition-Schema.
  TextColumn get filterJson => text().nullable()();

  // ── Phase 3: Workspace + Smart-Filter (MediaShelf-Muster) ─────────────────

  /// Workspace-Zugehörigkeit.
  TextColumn get workspaceId =>
      text().withDefault(const Constant('default'))();

  /// Hierarchie: Null = Root-Container. Ermöglicht verschachtelte Bereiche.
  TextColumn get parentId => text().nullable()();

  /// Sortierreihenfolge innerhalb desselben Eltern-Containers.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Smart-Filter: Einträge werden dynamisch per JSON-Regel gesammelt
  /// statt manuell zugewiesen. Äquivalent zu MediaShelf's Smart Collections.
  BoolColumn get isSmartFilter =>
      boolean().withDefault(const Constant(false))();

  /// JSON-Regelset für Smart-Filter (isSmartFilter = true).
  /// Format: {"logic":"AND","rules":[{"field":"type","op":"=","value":"link"}]}
  TextColumn get smartFilterQuery => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Junction-Tabelle zwischen Einträgen und Containern (n:m).
class EntryContainers extends Table {
  TextColumn get entryId => text()();
  TextColumn get containerId => text()();

  @override
  Set<Column> get primaryKey => {entryId, containerId};
}
