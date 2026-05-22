// Datei: lib/data/db/tables/attachments.dart
//
// ZWECK: Stub-Tabelle für Dateianhänge (Fotos, Audio, Videos).
// ABHÄNGIGKEITEN: Nur drift.
// PHASE: 1 – Stub-Deklaration; Befüllung erfolgt in Phase 2.
//
// WARUM jetzt deklarieren, obwohl wir sie erst in Phase 2 befüllen?
// Die Tabelle wird in Schema-Version 1 erstellt. Würden wir sie erst in
// Phase 2 hinzufügen, bräuchten wir einen Schema-Version-Bump (Version 2)
// mit einer onUpgrade-Migration. So bleibt die gesamte Basis-Struktur in
// einer einzigen, übersichtlichen Migration.

import 'package:drift/drift.dart';

/// Anhänge-Tabelle: Fotos, Audioaufnahmen und andere Mediendateien.
///
/// Dateien werden im App-Dokumentenverzeichnis unter
/// `attachments/YYYY/MM/` gespeichert. filePath ist relativ zu diesem Basis-Pfad.
class Attachments extends Table {
  /// UUID-Primärschlüssel.
  TextColumn get id => text()();

  /// Referenz auf den zugehörigen Eintrag. Löschen des Eintrags muss
  /// im EntryDao die Anhänge mitlöschen (kaskadierend, Phase 2).
  TextColumn get entryId => text()();

  /// Relativer Pfad zum Anhang, z. B. '2025/05/audio_abc123.m4a'.
  TextColumn get filePath => text()();

  /// MIME-Typ, z. B. 'image/jpeg', 'audio/mp4', 'video/mp4'.
  TextColumn get mimeType => text()();

  /// Dateigröße in Byte.
  IntColumn get size => integer()();

  /// Bildbreite in Pixeln. Null bei Nicht-Bild-Typen.
  IntColumn get width => integer().nullable()();

  /// Bildhöhe in Pixeln. Null bei Nicht-Bild-Typen.
  IntColumn get height => integer().nullable()();

  /// Audio-/Videolänge in Millisekunden. Null bei Nicht-Audio/Video-Typen.
  IntColumn get durationMs => integer().nullable()();

  /// Transkriptionstext (Phase 2: speech_to_text). Null bis verarbeitet.
  TextColumn get transcription => text().nullable()();

  /// OCR-Text (Phase 2: google_mlkit_text_recognition). Null bis verarbeitet.
  /// Wird Teil des FTS5-Index, aber NICHT automatisch in den Entry-Body übernommen.
  /// Der Nutzer entscheidet via "Text übernehmen"-Aktion, ob er den Text im Body sehen will.
  TextColumn get ocrText => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
