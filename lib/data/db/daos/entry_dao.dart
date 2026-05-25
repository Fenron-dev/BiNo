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
import '../../../domain/filters/filter_definition.dart';

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

  /// Beobachtet einen einzelnen Eintrag reaktiv.
  ///
  /// Gibt null zurück, wenn der Eintrag nicht existiert oder gelöscht wurde.
  /// Wird in der Detailansicht genutzt, damit Änderungen (Edit, Pin) sofort
  /// reflektiert werden, ohne den Provider manuell zu invalidieren.
  Stream<Entry?> watchEntryById(String id) =>
      (select(entries)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Aktualisiert die editierbaren Felder eines Eintrags.
  ///
  /// WARUM nur Titel, Body, Notizen und updatedAt?
  /// Typ, Status, Pin und Anhänge haben eigene Methoden mit spezifischer Logik.
  /// Schmale Updates reduzieren das Risiko, versehentlich andere Felder
  /// zu überschreiben.
  Future<void> updateEntryFields({
    required String id,
    String? title,
    required String body,
    String? notes,
    required DateTime updatedAt,
  }) =>
      (update(entries)..where((t) => t.id.equals(id))).write(
        EntriesCompanion(
          title: Value(title),
          body: Value(body),
          notes: Value(notes),
          updatedAt: Value(updatedAt),
        ),
      );

  /// Gibt alle Einträge zurück, die einen nicht-leeren Titel haben.
  /// Wird im Wikilink-Picker verwendet, damit der Nutzer per Titel verlinken kann.
  Future<List<Entry>> getEntriesWithTitles(String workspaceId) =>
      (select(entries)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.title.isNotNull() &
                  t.title.isNotValue(''),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.title)]))
          .get();

  /// Gibt alle Einträge zurück, deren createdAt im Zeitfenster [start, end) liegt.
  /// Wird vom onThisDayProvider genutzt, um Einträge vom gleichen Datum
  /// in vergangenen Jahren zu laden.
  Future<List<Entry>> getEntriesForDateRange(DateTime start, DateTime end) =>
      (select(entries)
            ..where(
              (t) =>
                  t.createdAt.isBiggerOrEqualValue(start) &
                  t.createdAt.isSmallerThanValue(end),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .get();

  /// Beobachtet Einträge, die der gegebenen Hub-Filter-Definition entsprechen.
  ///
  /// Kombiniert dynamisch WHERE-Bedingungen für Typ, Status und Tag-Filter.
  /// Bei gesetzten tagsAny wird ein JOIN auf entry_tags + tags ausgeführt;
  /// DISTINCT verhindert doppelte Einträge wenn ein Eintrag mehrere der
  /// gesuchten Tags hat.
  Stream<List<Entry>> watchEntriesForFilter(
    FilterDefinition filter,
    String workspaceId,
  ) {
    final db = attachedDatabase;

    final conditions = <String>[];
    final vars = <Variable>[];

    String fromClause = 'entries e';

    if (filter.tagsAny.isNotEmpty) {
      fromClause =
          'entries e JOIN entry_tags et ON et.entry_id = e.id JOIN tags t ON t.id = et.tag_id';
      final ph = List.filled(filter.tagsAny.length, '?').join(', ');
      conditions.add('t.name IN ($ph)');
      vars.addAll(filter.tagsAny.map(Variable.withString));
    }

    conditions.add('e.workspace_id = ?');
    vars.add(Variable.withString(workspaceId));

    if (filter.typeIn.isNotEmpty) {
      final ph = List.filled(filter.typeIn.length, '?').join(', ');
      conditions.add('e.type IN ($ph)');
      vars.addAll(filter.typeIn.map(Variable.withString));
    }

    if (filter.statusIn.isNotEmpty) {
      final ph = List.filled(filter.statusIn.length, '?').join(', ');
      conditions.add('e.status IN ($ph)');
      vars.addAll(filter.statusIn.map(Variable.withString));
    }

    final distinct = filter.tagsAny.isNotEmpty ? 'DISTINCT ' : '';
    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final sql =
        'SELECT ${distinct}e.* FROM $fromClause $where ORDER BY e.pinned DESC, e.created_at ASC';

    final readsTables = <ResultSetImplementation<dynamic, dynamic>>[entries];
    if (filter.tagsAny.isNotEmpty) {
      readsTables.add(db.entryTags);
      readsTables.add(db.tags);
    }

    return customSelect(sql, variables: vars, readsFrom: readsTables.toSet())
        .watch()
        .map((rows) => rows.map((row) => entries.map(row.data)).toList());
  }

  /// Gibt die neuesten Einträge zurück (für den Wikilink-Picker).
  /// Zeigt sowohl Einträge mit als auch ohne Titel, damit alle verlinkt
  /// werden können – beim Verlinken wird der Titel automatisch gesetzt.
  Future<List<Entry>> getRecentEntries(String workspaceId,
          {int limit = 100}) =>
      (select(entries)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([
              (t) => OrderingTerm(
                    expression: t.createdAt,
                    mode: OrderingMode.desc,
                  ),
            ])
            ..limit(limit))
          .get();

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

  /// Setzt oder löscht den Erinnerungszeitpunkt eines Eintrags.
  ///
  /// [reminderAt] = null entfernt eine bestehende Erinnerung (Alarm bleibt
  /// Aufgabe des Aufrufers – dieser muss auch NotificationService.cancelReminder
  /// aufrufen).
  Future<void> setReminderAt(String id, DateTime? reminderAt) =>
      (update(entries)..where((t) => t.id.equals(id))).write(
        EntriesCompanion(
          reminderAt: Value(reminderAt),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
}
