// Datei: lib/data/db/daos/tag_dao.dart
//
// ZWECK: Datenzugriffsobjekt für Tags und die entry_tags-Verknüpfungen.
// ABHÄNGIGKEITEN: database.g.dart (generiert).
// MUSTER: DAO.
// PHASE: 1 – Grundgerüst.

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tags.dart';

part 'tag_dao.g.dart';

/// DAO für Tags und die n:m-Verknüpfung zwischen Einträgen und Tags.
@DriftAccessor(tables: [Tags, EntryTags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  /// Sucht einen Tag anhand seines vollständigen hierarchischen Namens.
  /// Gibt null zurück, wenn der Tag nicht existiert.
  /// Wird vom Repository genutzt um Tags im Body zu finden oder neu anzulegen.
  Future<Tag?> getTagByName(String name) =>
      (select(tags)..where((t) => t.name.equals(name))).getSingleOrNull();

  /// Legt einen neuen Tag an. Gibt die interne SQLite-rowid zurück.
  Future<int> insertTag(TagsCompanion tag) => into(tags).insert(tag);

  /// Verknüpft einen Tag mit einem Eintrag.
  ///
  /// WARUM insertOnConflictUpdate statt insert?
  /// Falls derselbe Tag zweimal im Body steht (z. B. '#idee ... #idee'),
  /// parst TagParser zwar nur einmal (toSet()), aber beim nächsten
  /// Eintrag-Update würde ein normales insert eine Unique-Verletzung werfen.
  /// insertOnConflictUpdate ist idempotent und sicherer.
  Future<void> linkTagToEntry(String entryId, String tagId) =>
      into(entryTags).insertOnConflictUpdate(
        EntryTagsCompanion.insert(entryId: entryId, tagId: tagId),
      );

  /// Entfernt alle Tag-Verknüpfungen eines Eintrags.
  /// Wird beim Update eines Eintrags aufgerufen, BEVOR die neuen Tags
  /// aus dem aktualisierten Body geparst und neu verknüpft werden.
  /// So werden auch gelöschte Tags korrekt entfernt.
  Future<int> unlinkAllTagsFromEntry(String entryId) =>
      (delete(entryTags)..where((t) => t.entryId.equals(entryId))).go();

  /// Gibt alle Tags zurück, die einem Eintrag zugeordnet sind (One-Shot).
  /// Wird vom MarkdownExportService genutzt, um Tags in das Frontmatter zu schreiben.
  Future<List<Tag>> getTagsForEntry(String entryId) {
    final query = select(tags).join([
      innerJoin(entryTags, entryTags.tagId.equalsExp(tags.id)),
    ])
      ..where(entryTags.entryId.equals(entryId));
    return query.map((row) => row.readTable(tags)).get();
  }

  /// Beobachtet alle Tags als reaktiven Stream (für Tag-Verwaltung in Phase 6).
  Stream<List<Tag>> watchAllTags() => select(tags).watch();
}
