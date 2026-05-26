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

  /// Beobachtet alle Tags mit der Anzahl verknüpfter Einträge.
  Stream<List<TagWithCount>> watchTagsWithCounts() {
    const sql = '''
      SELECT t.id, t.name, t.color, t.icon, t.parent_id, t.workspace_id,
             COUNT(et.entry_id) AS entry_count
      FROM tags t
      LEFT JOIN entry_tags et ON et.tag_id = t.id
      GROUP BY t.id
      ORDER BY t.name
    ''';
    return customSelect(sql, readsFrom: {tags, entryTags})
        .watch()
        .map((rows) => rows.map((row) {
              final tag = Tag(
                id: row.read<String>('id'),
                name: row.read<String>('name'),
                color: row.readNullable<String>('color'),
                icon: row.readNullable<String>('icon'),
                parentId: row.readNullable<String>('parent_id'),
                workspaceId: row.read<String>('workspace_id'),
              );
              return TagWithCount(tag: tag, count: row.read<int>('entry_count'));
            }).toList());
  }

  /// Benennt einen Tag um (nur den Tabellen-Eintrag; Body-Texte bleiben unverändert).
  Future<void> renameTag(String id, String newName) =>
      (update(tags)..where((t) => t.id.equals(id))).write(
        TagsCompanion(name: Value(newName)),
      );

  /// Löscht einen Tag und alle seine entry_tags-Verknüpfungen.
  Future<void> deleteTagAndLinks(String id) async {
    await (delete(entryTags)..where((t) => t.tagId.equals(id))).go();
    await (delete(tags)..where((t) => t.id.equals(id))).go();
  }
}

/// Tag mit Anzahl verknüpfter Einträge (für die Tag-Verwaltung in Settings).
class TagWithCount {
  final Tag tag;
  final int count;

  const TagWithCount({required this.tag, required this.count});
}
