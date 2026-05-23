// Datei: lib/data/db/tables/tags.dart
//
// ZWECK: Definiert die Tags-Tabelle und die Junction-Tabelle entry_tags.
// ABHÄNGIGKEITEN: Nur drift.
// PHASE: 1 – Grundgerüst

import 'package:drift/drift.dart';

/// Tags mit hierarchischer Struktur via '/'-Trenner (Obsidian-Style).
///
/// WARUM wird der vollständige Pfad als name gespeichert?
/// 'buch/sachbuch/psychologie' ist die Quelle der Wahrheit für Anzeige und
/// FTS5-Indexierung. parent_id dient nur der Baum-Navigation (Phase 4).
/// So vermeiden wir JOIN-Ketten nur um den Anzeigenamen zu rekonstruieren.
class Tags extends Table {
  /// UUID-Primärschlüssel.
  TextColumn get id => text()();

  /// Vollständiger hierarchischer Tag-Name, z. B. 'buch/sachbuch/psychologie'.
  TextColumn get name => text()();

  /// Referenz auf den Eltern-Tag. Null = Root-Tag.
  /// Keine Drift-FK-Referenz hier, da Drift DSL-FKs das Schema verkomplizieren.
  /// Die Integrität wird im Repository via _findOrCreateTag sichergestellt.
  TextColumn get parentId => text().nullable()();

  /// Hex-Farbe, z. B. '#FF5733'. Null = Theme-Standard.
  TextColumn get color => text().nullable()();

  /// Material-Icon-Name oder eigener Bezeichner. Null = Standard-Tag-Icon.
  TextColumn get icon => text().nullable()();

  /// Workspace-Zugehörigkeit.
  TextColumn get workspaceId =>
      text().withDefault(const Constant('default'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Junction-Tabelle zwischen Einträgen und Tags (n:m-Beziehung).
///
/// WARUM kein Surrogatschlüssel (Auto-Increment-ID)?
/// Das Paar (entryId, tagId) ist natürlicher PK und garantiert Eindeutigkeit.
/// Ein zusätzlicher ID-Wert wäre redundant und würde keinen Mehrwert bieten.
class EntryTags extends Table {
  /// Referenz auf entries.id
  TextColumn get entryId => text()();

  /// Referenz auf tags.id
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {entryId, tagId};
}
