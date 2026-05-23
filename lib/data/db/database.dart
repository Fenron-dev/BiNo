// Datei: lib/data/db/database.dart
//
// ZWECK: Zentrale Drift-Datenbank-Definition. Referenziert alle Tabellen und DAOs,
//        führt Schema-Migrationen durch und konfiguriert SQLite-PRAGMAs.
// ABHÄNGIGKEITEN: drift, drift_flutter, alle Tabellen- und DAO-Dateien.
// PHASE: 1 – Grundgerüst. Phase 2: AttachmentDao hinzugefügt.
//
// WICHTIG: `part 'database.g.dart'` erfordert, dass drift_dev via build_runner
// ausgeführt wurde. Ohne den generierten Code compiliert diese Datei nicht.

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/entries.dart';
import 'tables/tags.dart';
import 'tables/containers.dart';
import 'tables/attachments.dart';
import 'tables/workspaces.dart';
import 'tables/property_definitions.dart';
import 'tables/templates.dart';
import 'daos/entry_dao.dart';
import 'daos/tag_dao.dart';
import 'daos/container_dao.dart';
import 'daos/attachment_dao.dart';
import 'daos/property_dao.dart';

// Der `part`-Direktive verweist auf die von drift_dev generierte Datei.
// Sie enthält die _$AppDatabase-Basisklasse mit allen Query-Methoden.
part 'database.g.dart';

/// Zentrale SQLite-Datenbank der App (Drift-gestützt).
///
/// MUSTER: Singleton – wird einmalig über den Riverpod-Provider in di.dart
/// erzeugt und für die gesamte App-Lebensdauer gehalten.
///
/// WARUM driftDatabase() statt NativeDatabase direkt?
/// drift_flutter's driftDatabase() öffnet die DB auf einem Hintergrund-Isolat,
/// sodass kein DB-Zugriff den UI-Thread blockiert. Gleichzeitig löst es
/// path_provider auf, um das korrekte Dokumentenverzeichnis zu finden.
@DriftDatabase(
  tables: [
    Entries,
    Tags,
    EntryTags,
    Containers,
    EntryContainers,
    Attachments,
    Workspaces,
    PropertyDefinitions,
    EntryProperties,
    Templates,
  ],
  daos: [
    EntryDao,
    TagDao,
    ContainerDao,
    AttachmentDao,
    PropertyDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Standardkonstruktor für die Produktion. Nutzt driftDatabase() aus drift_flutter.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDatabase());

  /// Öffnet die Produktions-Datenbank im App-Dokumentenverzeichnis.
  static QueryExecutor _openDatabase() {
    // 'bino_notes' wird als Dateiname verwendet → bino_notes.db
    return driftDatabase(name: 'bino_notes');
  }

  // WICHTIG: schemaVersion darf NUR erhöht werden, nie verringert.
  // Jede Erhöhung erfordert einen neuen onUpgrade-Block in migration.
  // REGEL: Bestehende Migrationen nie nachträglich ändern – nur neue hinzufügen.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        /// onCreate: Wird bei Erstinstallation ausgeführt.
        /// Legt alle Tabellen, FTS5-Index, Trigger und Indizes an.
        onCreate: (Migrator m) async {
          // Alle Drift-verwalteten Tabellen erstellen.
          await m.createAll();

          // ── FTS5-Volltext-Index ────────────────────────────────────────────
          // WARUM content='entries' statt contentless?
          // Ein Content-Table-FTS5 verknüpft den Index mit der entries-Tabelle.
          // Dadurch funktionieren snippet() und highlight() für Such-Highlighting
          // in Phase 3. Contentless würde nur den Index speichern und diese
          // Funktionen deaktivieren.
          //
          // content_rowid='rowid' verknüpft den FTS5-Index mit SQLites internem
          // Integer-rowid, NICHT mit unserem UUID-Feld id. Drift weist jeder
          // Zeile automatisch eine interne rowid zu, auch wenn der PK ein TEXT ist.
          //
          // ACHTUNG: Bei Content-Tables muss die Synchronisation manuell über
          // Trigger erfolgen (siehe unten). FTS5 aktualisiert sich nicht automatisch.
          await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts
            USING fts5(
              title,
              body,
              content='entries',
              content_rowid='rowid'
            )
          ''');

          // ── FTS5-Synchronisierungs-Trigger ────────────────────────────────
          // WARUM Trigger statt manuelle Aufrufe im DAO?
          // Trigger laufen atomar innerhalb derselben Transaktion wie das
          // auslösende DML-Statement. Auch Batch-Operationen oder direkte
          // SQL-Zugriffe (z. B. in Migrationen) halten den FTS5-Index konsistent.
          // Dies ist das Standard-Muster aus der offiziellen SQLite-FTS5-Dokumentation.

          // Trigger nach INSERT
          await customStatement('''
            CREATE TRIGGER entries_ai AFTER INSERT ON entries BEGIN
              INSERT INTO entries_fts(rowid, title, body)
                VALUES (new.rowid, new.title, new.body);
            END
          ''');

          // Trigger nach DELETE
          await customStatement('''
            CREATE TRIGGER entries_ad AFTER DELETE ON entries BEGIN
              INSERT INTO entries_fts(entries_fts, rowid, title, body)
                VALUES ('delete', old.rowid, old.title, old.body);
            END
          ''');

          // Trigger nach UPDATE: FTS5 kennt kein direktes UPDATE –
          // zuerst löschen, dann neu einfügen.
          await customStatement('''
            CREATE TRIGGER entries_au AFTER UPDATE ON entries BEGIN
              INSERT INTO entries_fts(entries_fts, rowid, title, body)
                VALUES ('delete', old.rowid, old.title, old.body);
              INSERT INTO entries_fts(rowid, title, body)
                VALUES (new.rowid, new.title, new.body);
            END
          ''');

          // ── Indizes für häufige Abfragenmuster ────────────────────────────
          // Covering Index für die Feed-Abfrage (ORDER BY created_at DESC).
          // Ohne Index würde SQLite bei jedem Feed-Reload einen Full Table Scan machen.
          await customStatement(
            'CREATE INDEX idx_entries_created_at ON entries(created_at DESC)',
          );

          // Unique-Index auf tags.name verhindert doppelte Tag-Einträge und
          // beschleunigt die Suche nach Tag-Namen im TagParser.
          await customStatement(
            'CREATE UNIQUE INDEX idx_tags_name ON tags(name)',
          );
        },

        /// onUpgrade: Wird ausgeführt, wenn schemaVersion erhöht wurde.
        /// REGEL: Blöcke nie nachträglich ändern – nur neue if-Blöcke anfügen.
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // ── Neue Tabellen anlegen ───────────────────────────────────────
            await m.createTable(workspaces);
            await m.createTable(propertyDefinitions);
            await m.createTable(entryProperties);
            await m.createTable(templates);

            // Standard-Workspace einfügen – alle bestehenden Daten gehören ihm.
            await customStatement('''
              INSERT INTO workspaces (id, name, icon, color, is_default, created_at)
              VALUES ('default', 'Standard', '🏠', '#6750A4', 1,
                      strftime('%s','now') * 1000)
            ''');

            // ── Spalten zu entries hinzufügen ───────────────────────────────
            // withDefault('default') → SQLite setzt alle Bestandszeilen auf 'default'
            await m.addColumn(entries, entries.workspaceId);
            await m.addColumn(entries, entries.notes);
            await m.addColumn(entries, entries.playbackPositionMs);

            // ── Spalten zu tags hinzufügen ──────────────────────────────────
            await m.addColumn(tags, tags.workspaceId);

            // ── Spalten zu containers hinzufügen ────────────────────────────
            await m.addColumn(containers, containers.workspaceId);
            await m.addColumn(containers, containers.parentId);
            await m.addColumn(containers, containers.sortOrder);
            await m.addColumn(containers, containers.isSmartFilter);
            await m.addColumn(containers, containers.smartFilterQuery);
          }
        },

        /// beforeOpen: Wird bei JEDEM App-Start ausgeführt, nach der Migration.
        /// WICHTIG: SQLite-PRAGMAs müssen pro Verbindung gesetzt werden und
        /// gehören deshalb hierher, nicht in onCreate.
        beforeOpen: (OpeningDetails details) async {
          // PFLICHT: SQLite deaktiviert Fremdschlüssel-Prüfung standardmäßig.
          await customStatement('PRAGMA foreign_keys = ON');

          // WAL (Write-Ahead Logging): Ermöglicht gleichzeitige Lesezugriffe
          // während eines Schreibvorgangs. Wichtig für Riverpod-StreamProvider
          // (liest) während CaptureController schreibt.
          await customStatement('PRAGMA journal_mode = WAL');

          // NORMAL ist mit WAL sicher und ~3× schneller als FULL (Standard).
          await customStatement('PRAGMA synchronous = NORMAL');
        },
      );
}
