// Datei: lib/data/db/daos/entry_dao.dart
//
// ZWECK: Datenzugriffsobjekt für Einträge. Kapselt alle SQL-Queries rund
//        um die entries-Tabelle und hält SQL-Logik aus dem Repository fern.
// ABHÄNGIGKEITEN: database.g.dart (generiert durch build_runner).
// MUSTER: DAO – trennt SQL-Logik von Geschäftslogik (Repository).
// PHASE: 1 – Grundgerüst. Phase 2+ fügt Attachment-Cascade hinzu.

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/entries.dart';

// Der `part`-Direktive verweist auf die von drift_dev generierte Datei,
// die den _$EntryDaoMixin mit allen Tabellen-Accessoren enthält.
part 'entry_dao.g.dart';

/// DAO für CRUD-Operationen auf der entries-Tabelle.
///
/// WARUM @DriftAccessor statt direkte DB-Zugriffe im Repository?
/// DAOs sind testbar ohne das gesamte Repository. Außerdem generiert drift_dev
/// aus @DriftAccessor typsichere Query-Methoden, die SQL-Injektionen strukturell
/// ausschließen.
@DriftAccessor(tables: [Entries])
class EntryDao extends DatabaseAccessor<AppDatabase> with _$EntryDaoMixin {
  EntryDao(super.db);

  /// Beobachtet alle Einträge als reaktiven Stream.
  ///
  /// Sortierung: Angepinnte Einträge zuerst (DESC), dann chronologisch
  /// aufsteigend. Der FeedScreen nutzt ListView(reverse: true), sodass
  /// der neueste Eintrag am Bildschirmende erscheint (WhatsApp-Stil).
  ///
  /// WARUM ascending statt descending sortieren?
  /// Mit reverse:true zeigt ListView Index 0 unten. Das bedeutet:
  /// Der erste Eintrag der Liste erscheint GANZ UNTEN. Chronologisch
  /// aufsteigend = älteste zuerst in der Liste = älteste unten = neueste oben.
  /// FALSCH! Wir wollen neueste unten.
  /// Lösung: aufsteigend sortieren (älteste als Index 0, neueste als letzter
  /// Index) + reverse:true dreht die Anzeige um → neueste erscheint unten.
  Stream<List<Entry>> watchAllEntries(String workspaceId) {
    return (select(entries)
          ..where((t) => t.workspaceId.equals(workspaceId))
          ..orderBy([
            // Angepinnte Einträge erscheinen oben (true > false → DESC).
            (t) => OrderingTerm(
                  expression: t.pinned,
                  mode: OrderingMode.desc,
                ),
            // Innerhalb jeder Gruppe chronologisch aufsteigend.
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  /// Fügt einen neuen Eintrag ein. Gibt die interne SQLite-rowid zurück.
  Future<int> insertEntry(EntriesCompanion entry) =>
      into(entries).insert(entry);

  /// Ersetzt einen Eintrag vollständig (alle Felder). Gibt true zurück wenn
  /// der Eintrag existierte und ersetzt wurde.
  Future<bool> updateEntry(EntriesCompanion entry) =>
      update(entries).replace(entry);

  /// Löscht den Eintrag mit der gegebenen UUID. Gibt die Anzahl gelöschter
  /// Zeilen zurück (0 wenn nicht gefunden, 1 wenn gelöscht).
  Future<int> deleteEntry(String id) =>
      (delete(entries)..where((t) => t.id.equals(id))).go();

  /// Gibt den Eintrag mit der gegebenen UUID zurück, oder null wenn nicht gefunden.
  Future<Entry?> getEntryById(String id) =>
      (select(entries)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Durchsucht Einträge via SQLite LIKE (Teilstring-Suche).
  ///
  /// WARUM LIKE statt FTS5?
  /// FTS5 matcht nur Wortanfänge ("Zom*" findet "Zombie", aber "omb" nicht).
  /// LIKE '%omb%' findet Teilstrings an beliebiger Position – nutzerfreundlicher.
  /// LOWER() auf beiden Seiten macht die Suche case-insensitiv ohne Collation.
  Future<List<Entry>> searchEntries(String query) async {
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();
    // Sonderzeichen in LIKE-Mustern escapen: \ → \\, % → \%, _ → \_
    final escaped = q
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
    final pattern = '%$escaped%';

    try {
      final ids = await customSelect(
        "SELECT id FROM entries "
        "WHERE LOWER(body) LIKE ? ESCAPE '\\' "
        "   OR LOWER(COALESCE(title,'')) LIKE ? ESCAPE '\\'",
        variables: [Variable.withString(pattern), Variable.withString(pattern)],
        readsFrom: {entries},
      ).map((row) => row.read<String>('id')).get();

      if (ids.isEmpty) return [];

      return (select(entries)
            ..where((t) => t.id.isIn(ids))
            ..orderBy([
              (t) => OrderingTerm(expression: t.pinned, mode: OrderingMode.desc),
              (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
            ]))
          .get();
    } catch (_) {
      return [];
    }
  }

  /// Schaltet den Pinned-Status eines Eintrags um.
  Future<void> togglePin(String id) async {
    final entry = await getEntryById(id);
    if (entry == null) return;
    await (update(entries)..where((t) => t.id.equals(id))).write(
      EntriesCompanion(
        pinned: Value(!entry.pinned),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
