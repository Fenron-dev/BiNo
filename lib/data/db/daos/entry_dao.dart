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
  Stream<List<Entry>> watchAllEntries() {
    return (select(entries)
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
  /// Wird im Repository für Duplikat-Erkennung (Phase 3) und Update-Prüfungen genutzt.
  Future<Entry?> getEntryById(String id) =>
      (select(entries)..where((t) => t.id.equals(id))).getSingleOrNull();
}
