// Datei: lib/data/db/daos/attachment_dao.dart
//
// ZWECK: Datenzugriffsobjekt für Anhänge (Fotos, Audio, Videos).
// ABHÄNGIGKEITEN: database.g.dart (generiert).
// MUSTER: DAO.
// PHASE: 2 – Anhänge aktiv genutzt.

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/attachments.dart';

part 'attachment_dao.g.dart';

/// DAO für CRUD-Operationen auf der attachments-Tabelle.
@DriftAccessor(tables: [Attachments])
class AttachmentDao extends DatabaseAccessor<AppDatabase>
    with _$AttachmentDaoMixin {
  AttachmentDao(super.db);

  /// Legt einen neuen Anhang an. Gibt die interne SQLite-rowid zurück.
  Future<int> insertAttachment(AttachmentsCompanion attachment) =>
      into(attachments).insert(attachment);

  /// Gibt alle Anhänge für einen Eintrag zurück.
  Future<List<Attachment>> getAttachmentsForEntry(String entryId) =>
      (select(attachments)..where((t) => t.entryId.equals(entryId))).get();

  /// Beobachtet Anhänge eines Eintrags als Stream (für die Detail-Ansicht).
  Stream<List<Attachment>> watchAttachmentsForEntry(String entryId) =>
      (select(attachments)..where((t) => t.entryId.equals(entryId))).watch();

  /// Löscht alle Anhänge eines Eintrags.
  /// Muss vor dem Löschen des Eintrags aufgerufen werden, damit die
  /// Dateipfade noch bekannt sind (für die Bereinigung im Dateisystem).
  Future<List<Attachment>> getAndDeleteAttachmentsForEntry(
      String entryId) async {
    final list = await getAttachmentsForEntry(entryId);
    await (delete(attachments)..where((t) => t.entryId.equals(entryId))).go();
    return list;
  }

  /// Aktualisiert Transkriptions- oder OCR-Text eines Anhangs.
  /// Wird aufgerufen, nachdem der Hintergrund-Job abgeschlossen ist.
  Future<void> updateTextContent({
    required String id,
    String? transcription,
    String? ocrText,
  }) async {
    await (update(attachments)..where((t) => t.id.equals(id))).write(
      AttachmentsCompanion(
        transcription: Value(transcription),
        ocrText: Value(ocrText),
      ),
    );
  }
}
