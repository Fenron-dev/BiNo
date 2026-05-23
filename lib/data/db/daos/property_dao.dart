// Datei: lib/data/db/daos/property_dao.dart
//
// ZWECK: Datenzugriffsobjekt für PropertyDefinitions und EntryProperties.
//        Kapselt alle CRUD-Operationen für das EAV-Property-System.
// ABHÄNGIGKEITEN: database.g.dart (generiert durch build_runner).
// MUSTER: DAO – trennt SQL-Logik von Geschäftslogik.
// PHASE: 3 – Properties und Templates.

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/property_definitions.dart';

part 'property_dao.g.dart';

/// DAO für das EAV-Property-System.
///
/// WARUM eigener DAO statt Erweiterung von EntryDao?
/// Properties und Definitionen sind konzeptuell unabhängig von Einträgen.
/// Ein eigener DAO erlaubt gezielte Tests und klare Verantwortlichkeiten.
@DriftAccessor(tables: [PropertyDefinitions, EntryProperties])
class PropertyDao extends DatabaseAccessor<AppDatabase>
    with _$PropertyDaoMixin {
  PropertyDao(super.db);

  // ── PropertyDefinitions ───────────────────────────────────────────────────

  /// Beobachtet alle Definitionen eines Workspace reaktiv (nach sortOrder).
  Stream<List<PropertyDefinition>> watchDefinitionsForWorkspace(
    String workspaceId,
  ) =>
      (select(propertyDefinitions)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.sortOrder),
              (t) => OrderingTerm(expression: t.name),
            ]))
          .watch();

  /// Legt eine neue Property-Definition an.
  Future<void> insertDefinition(PropertyDefinitionsCompanion def) =>
      into(propertyDefinitions).insert(def);

  /// Löscht eine Definition (Werte in entry_properties bleiben als Waisen –
  /// werden beim nächsten Eintrag-Löschen oder Migrations-Cleanup entfernt).
  Future<void> deleteDefinition(String id) =>
      (delete(propertyDefinitions)..where((t) => t.id.equals(id))).go();

  // ── EntryProperties ───────────────────────────────────────────────────────

  /// Beobachtet alle gesetzten Property-Werte für einen Eintrag reaktiv.
  Stream<List<EntryProperty>> watchPropertiesForEntry(String entryId) =>
      (select(entryProperties)
            ..where((t) => t.entryId.equals(entryId)))
          .watch();

  /// Sucht einen einzelnen gesetzten Wert (entryId + propertyId).
  Future<EntryProperty?> findPropertyValue(
    String entryId,
    String propertyId,
  ) =>
      (select(entryProperties)
            ..where(
              (t) =>
                  t.entryId.equals(entryId) & t.propertyId.equals(propertyId),
            ))
          .getSingleOrNull();

  /// Findet eine Definition anhand ihres Namens in einem Workspace.
  Future<PropertyDefinition?> findDefinitionByName(
    String workspaceId,
    String name,
  ) =>
      (select(propertyDefinitions)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.name.equals(name),
            ))
          .getSingleOrNull();

  /// Legt einen neuen Property-Wert an.
  Future<void> insertProperty(EntryPropertiesCompanion prop) =>
      into(entryProperties).insert(prop);

  /// Aktualisiert den JSON-Wert einer vorhandenen Property.
  Future<void> updateProperty(String id, String? value) =>
      (update(entryProperties)..where((t) => t.id.equals(id)))
          .write(EntryPropertiesCompanion(value: Value(value)));

  /// Löscht einen einzelnen gesetzten Wert.
  Future<void> deleteProperty(String id) =>
      (delete(entryProperties)..where((t) => t.id.equals(id))).go();

  /// Löscht alle Property-Werte eines Eintrags (z. B. beim Eintrag-Löschen).
  Future<void> deleteAllForEntry(String entryId) =>
      (delete(entryProperties)..where((t) => t.entryId.equals(entryId))).go();
}
