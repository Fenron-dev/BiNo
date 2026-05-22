// Datei: lib/data/db/daos/container_dao.dart
//
// ZWECK: Datenzugriffsobjekt für Container (Projekte, Bereiche, Hub-Tabs).
// ABHÄNGIGKEITEN: database.g.dart (generiert).
// MUSTER: DAO.
// PHASE: 1 – Stub für die Datenbank-Deklaration. CRUD-Operationen folgen in Phase 4.

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/containers.dart';

part 'container_dao.g.dart';

/// DAO für Container und die n:m-Verknüpfung zwischen Einträgen und Containern.
///
/// WARUM bereits in Phase 1 anlegen?
/// database.dart referenziert ContainerDao in der @DriftDatabase-Annotation.
/// Ohne diese Datei schlägt die build_runner-Generierung fehl.
/// Die Methoden sind bewusst minimal – der volle Umfang kommt in Phase 4.
@DriftAccessor(tables: [Containers, EntryContainers])
class ContainerDao extends DatabaseAccessor<AppDatabase>
    with _$ContainerDaoMixin {
  ContainerDao(super.db);

  /// Gibt alle nicht-archivierten Container zurück, gefiltert nach 'kind'.
  ///
  /// [kind] – 'project', 'area' oder 'hub'.
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

  /// Legt einen neuen Container an.
  Future<int> insertContainer(ContainersCompanion container) =>
      into(containers).insert(container);
}
