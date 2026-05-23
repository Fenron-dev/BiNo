// Datei: lib/data/db/daos/container_dao.dart
//
// ZWECK: Datenzugriffsobjekt für Container (Projekte, Bereiche, Hub-Tabs)
//        und die Entry-Container-Verknüpfung.
// ABHÄNGIGKEITEN: database.g.dart (generiert).
// MUSTER: DAO.
// PHASE: 1 – Stub. Phase 4: vollständige CRUD-Operationen.

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/containers.dart';

part 'container_dao.g.dart';

/// DAO für Container und die n:m-Verknüpfung zwischen Einträgen und Containern.
///
/// WARUM kein Join über entries?
/// Das @DriftAccessor enthält nur Containers und EntryContainers, da der Drift-
/// Code-Generator für die entries-Tabelle nicht re-generiert werden soll.
/// Die Einträge eines Containers werden über attachedDatabase abgerufen.
@DriftAccessor(tables: [Containers, EntryContainers])
class ContainerDao extends DatabaseAccessor<AppDatabase>
    with _$ContainerDaoMixin {
  ContainerDao(super.db);

  // ── Lesen ─────────────────────────────────────────────────────────────────

  /// Gibt einen Container anhand seiner ID zurück (für Pre-Fill im Edit-Formular).
  Future<Container?> getContainerById(String id) =>
      (select(containers)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Gibt alle nicht-archivierten Container zurück, gefiltert nach 'kind'.
  Future<List<Container>> getContainersByKind(String kind) =>
      (select(containers)
            ..where((t) => t.kind.equals(kind) & t.archived.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// Beobachtet alle nicht-archivierten Container eines bestimmten Typs.
  Stream<List<Container>> watchContainersByKind(String kind) =>
      (select(containers)
            ..where((t) => t.kind.equals(kind) & t.archived.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  /// Beobachtet Einträge eines Containers.
  ///
  /// WARUM asyncMap statt direkter Join?
  /// Die entries-Tabelle ist nicht im @DriftAccessor dieser DAO – ein direkter
  /// Join würde Code-Regenerierung erfordern. asyncMap liest Eintrags-IDs aus
  /// entry_containers und lädt die Entries separat über attachedDatabase.
  Stream<List<Entry>> watchEntriesForContainer(String containerId) =>
      (select(entryContainers)
            ..where((t) => t.containerId.equals(containerId)))
          .watch()
          .asyncMap((links) async {
        final ids = links.map((l) => l.entryId).toList();
        if (ids.isEmpty) return <Entry>[];
        return (attachedDatabase.select(attachedDatabase.entries)
              ..where((t) => t.id.isIn(ids))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
      });

  /// Beobachtet alle Container, denen ein Eintrag zugewiesen ist.
  Stream<List<Container>> watchContainersForEntry(String entryId) {
    final query = (select(containers).join([
      innerJoin(
        entryContainers,
        entryContainers.containerId.equalsExp(containers.id),
      ),
    ]))
      ..where(entryContainers.entryId.equals(entryId))
      ..where(containers.archived.equals(false));
    return query.map((row) => row.readTable(containers)).watch();
  }

  /// Beobachtet die Anzahl der Einträge in einem Container reaktiv.
  Stream<int> watchEntryCountForContainer(String containerId) =>
      (select(entryContainers)
            ..where((t) => t.containerId.equals(containerId)))
          .watch()
          .map((rows) => rows.length);

  // ── Schreiben ─────────────────────────────────────────────────────────────

  /// Legt einen neuen Container an.
  Future<int> insertContainer(ContainersCompanion container) =>
      into(containers).insert(container);

  /// Aktualisiert Name, Beschreibung, Icon und Farbe eines Containers.
  Future<void> updateContainer({
    required String id,
    required String name,
    String? description,
    required String icon,
    required String color,
  }) =>
      (update(containers)..where((t) => t.id.equals(id))).write(
        ContainersCompanion(
          name: Value(name),
          description: Value(description),
          icon: Value(icon),
          color: Value(color),
        ),
      );

  /// Archiviert einen Container (Soft-Delete).
  Future<void> archiveContainer(String id) =>
      (update(containers)..where((t) => t.id.equals(id)))
          .write(const ContainersCompanion(archived: Value(true)));

  // ── Eintrag-Zuweisung ─────────────────────────────────────────────────────

  /// Weist einen Eintrag einem Container zu (idempotent).
  Future<void> assignEntry(String entryId, String containerId) =>
      into(entryContainers).insert(
        EntryContainersCompanion.insert(
          entryId: entryId,
          containerId: containerId,
        ),
        mode: InsertMode.insertOrIgnore,
      );

  /// Entfernt die Zuweisung eines Eintrags aus einem Container.
  Future<void> removeEntry(String entryId, String containerId) =>
      (delete(entryContainers)
            ..where(
              (t) =>
                  t.entryId.equals(entryId) &
                  t.containerId.equals(containerId),
            ))
          .go();
}
