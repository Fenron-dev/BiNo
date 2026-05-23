// Datei: lib/data/db/tables/entries.dart
//
// ZWECK: Definiert die SQLite-Tabelle für Einträge (Kern-Entity der App).
// ABHÄNGIGKEITEN: Nur drift – keine Flutter- oder App-Abhängigkeiten.
// PHASE: 1 – Grundgerüst

import 'package:drift/drift.dart';

// WARUM TextColumn für id statt IntColumn (Auto-Increment)?
// UUIDs überleben Export/Import ohne Kollisionen, funktionieren offline-first
// ohne zentrale Sequenz und sind opak (kein Informations-Leak).
// Drift's Standard-Integer-PK würde Auto-Increment nutzen – wir weichen bewusst ab.

/// Enum für den Eintragstyp. Als TEXT in SQLite gespeichert,
/// damit neue Werte in Zukunft keine bestehenden Zeilen brechen.
enum EntryType {
  /// Reiner Textinhalt
  text,

  /// Web-Link mit Open-Graph-Metadaten (Phase 2)
  link,

  /// Bild mit optionalem OCR-Text (Phase 2)
  image,

  /// Audioaufnahme mit Transkription (Phase 2)
  audio,

  /// Videoaufnahme oder geteiltes Video (Phase 3)
  video,

  /// Gemischte Inhalte (Text + Anhänge)
  mixed
}

/// Enum für den Bearbeitungsstatus eines Eintrags.
enum EntryStatus {
  /// Neu erfasst, noch nicht bearbeitet
  inbox,

  /// Aktiv in Bearbeitung
  active,

  /// Abgeschlossen
  done,

  /// Archiviert (ausgeblendet, aber nicht gelöscht)
  archived
}

/// Drift-Tabellendefinition für Einträge.
///
/// WARUM DateTime als INTEGER (Unix-Millisekunden)?
/// Drift mappt DateTimeColumn standardmäßig auf INTEGER (Millisekunden seit Epoch).
/// Das ist effizienter als TEXT und vermeidet Zeitzonenprobleme, da wir
/// immer UTC speichern und die Konvertierung in der Dart-Schicht vornehmen.
class Entries extends Table {
  /// UUID-Primärschlüssel. Wird im Repository via `uuid`-Paket generiert.
  TextColumn get id => text()();

  /// Erfassungszeitpunkt (UTC). Wird einmalig beim Erstellen gesetzt.
  /// clientDefault nutzt Dart-seitige Logik – funktioniert ohne DB-Trigger.
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  /// Letzter Änderungszeitpunkt (UTC). Wird bei jedem Update manuell gesetzt.
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  /// Eintragstyp als TEXT (z. B. 'text', 'link'). Standard: 'text'.
  TextColumn get type => text().withDefault(const Constant('text'))();

  /// Optionaler Titel. Wenn leer, generiert die UI eine Vorschau aus dem Body.
  TextColumn get title => text().nullable()();

  /// Hauptinhalt als Markdown-String. Unterstützt #tags und [[Wikilinks]].
  /// Nie null – leerer String für Nicht-Text-Typen.
  TextColumn get body => text().withDefault(const Constant(''))();

  /// Bearbeitungsstatus. Standard 'inbox' = neu erfasst, noch unbearbeitet.
  TextColumn get status => text().withDefault(const Constant('inbox'))();

  /// Angepinnte Einträge erscheinen sticky oben im Feed (max. 5 per UI-Schicht).
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();

  /// Optionaler Standort. Beide Felder sind entweder beide gesetzt oder beide null.
  RealColumn get geoLat => real().nullable()();
  RealColumn get geoLng => real().nullable()();

  /// Erinnerungszeitpunkt für flutter_local_notifications (Phase 6).
  DateTimeColumn get reminderAt => dateTime().nullable()();

  /// Quell-URL bei Link-Einträgen oder Share-Intent (Phase 2).
  TextColumn get sourceUrl => text().nullable()();

  /// Herkunfts-App bei Share-Intent, z. B. 'com.google.android.youtube' (Phase 2).
  TextColumn get sourceApp => text().nullable()();

  /// 384-dimensionaler float32-Einbettungsvektor (Phase 3: ONNX + sqlite-vec).
  /// Als BLOB gespeichert. Null, bis der Embedding-Service den Eintrag verarbeitet hat.
  BlobColumn get embedding => blob().nullable()();

  /// Zeitpunkt, wann zuletzt eine Cloud-KI den Eintrag angereichert hat (Phase 5).
  DateTimeColumn get aiEnrichedAt => dateTime().nullable()();

  /// ISO-639-1-Sprachcode, erkannt von ML Kit Language ID (Phase 3).
  TextColumn get lang => text().nullable()();

  // ── Phase 3: Workspace, Notizen, Wiedergabe-Position ─────────────────────

  /// Workspace-Zugehörigkeit. Alle bestehenden Einträge erhalten beim
  /// Migrations-Upgrade automatisch den Wert 'default'.
  TextColumn get workspaceId =>
      text().withDefault(const Constant('default'))();

  /// Persönliche Anmerkungen des Nutzers – getrennt vom ursprünglichen Body.
  /// Vergleichbar mit Annotationen in einer Lese-App.
  TextColumn get notes => text().nullable()();

  /// Letzte Wiedergabe-Position für Audio/Video in Millisekunden.
  /// Null = noch nicht abgespielt oder am Anfang.
  IntColumn get playbackPositionMs => integer().nullable()();

  // WARUM Set<Column> statt @primaryKey-Annotation auf der Spalte?
  // Drift verlangt bei TEXT-PKs den Override von primaryKey als Set.
  // @primaryKey wäre nur für Integer-PKs mit Auto-Increment nutzbar.
  @override
  Set<Column> get primaryKey => {id};
}
