// Datei: lib/data/repositories/attachment_repository.dart
//
// ZWECK: Koordiniert das Speichern von Anhängen: Dateisystem (AttachmentService)
//        + Datenbank (AttachmentDao) + asynchrone KI-Verarbeitung (OCR, STT).
// ABHÄNGIGKEITEN: AttachmentDao, AttachmentService, OcrService, uuid.
// PHASE: 2 – Foto und Audio. Phase 3: Embedding für Anhänge.

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../db/daos/attachment_dao.dart';
import '../../services/attachment_service.dart';
import '../../data/ml/ocr_service.dart';

/// Repository für Anhänge.
///
/// Koordiniert das zweistufige Speichern:
/// 1. Datei im Dateisystem ablegen (AttachmentService).
/// 2. Metadaten + relativer Pfad in der DB speichern (AttachmentDao).
/// 3. Optional: OCR oder STT im Hintergrund starten.
class AttachmentRepository {
  final AttachmentDao _dao;
  final AttachmentService _fileService;
  final OcrService _ocrService;
  final Uuid _uuid;

  AttachmentRepository({
    required AttachmentDao dao,
    required AttachmentService fileService,
    required OcrService ocrService,
    Uuid? uuid,
  })  : _dao = dao,
        _fileService = fileService,
        _ocrService = ocrService,
        _uuid = uuid ?? const Uuid();

  /// Speichert ein Bild als Anhang zu [entryId].
  ///
  /// Startet OCR im Hintergrund (fire-and-forget). Das OCR-Ergebnis wird
  /// sobald es vorliegt asynchron in die DB geschrieben.
  ///
  /// Gibt die UUID des neuen Anhangs zurück.
  Future<String> saveImage({
    required String entryId,
    required File imageFile,
    String mimeType = 'image/jpeg',
    int? width,
    int? height,
  }) async {
    final fileInfo =
        await _fileService.saveFile(imageFile, mimeType: mimeType);
    final id = _uuid.v4();

    await _dao.insertAttachment(
      AttachmentsCompanion.insert(
        id: id,
        entryId: entryId,
        filePath: fileInfo.relativePath,
        mimeType: fileInfo.mimeType,
        size: fileInfo.size,
        width: Value(width),
        height: Value(height),
      ),
    );

    // OCR im Hintergrund starten (fire-and-forget mit unawaited).
    // WARUM fire-and-forget? OCR dauert 200–500 ms. Der Nutzer soll nicht
    // auf das Ergebnis warten müssen – der Eintrag ist sofort sichtbar.
    _runOcrInBackground(id: id, imageFile: imageFile);

    return id;
  }

  /// Speichert eine Audioaufnahme als Anhang zu [entryId].
  ///
  /// Gibt die UUID des neuen Anhangs zurück.
  Future<String> saveAudio({
    required String entryId,
    required File audioFile,
    String mimeType = 'audio/m4a',
    int? durationMs,
  }) async {
    final fileInfo =
        await _fileService.saveFile(audioFile, mimeType: mimeType);
    final id = _uuid.v4();

    await _dao.insertAttachment(
      AttachmentsCompanion.insert(
        id: id,
        entryId: entryId,
        filePath: fileInfo.relativePath,
        mimeType: fileInfo.mimeType,
        size: fileInfo.size,
        durationMs: Value(durationMs),
      ),
    );

    return id;
  }

  /// Gibt alle Anhänge eines Eintrags zurück.
  Future<List<Attachment>> getForEntry(String entryId) =>
      _dao.getAttachmentsForEntry(entryId);

  /// Beobachtet Anhänge eines Eintrags als reaktiven Stream.
  Stream<List<Attachment>> watchForEntry(String entryId) =>
      _dao.watchAttachmentsForEntry(entryId);

  /// Löscht alle Anhänge eines Eintrags (DB + Dateisystem).
  Future<void> deleteAllForEntry(String entryId) async {
    final list = await _dao.getAndDeleteAttachmentsForEntry(entryId);
    for (final attachment in list) {
      await _fileService.deleteFile(attachment.filePath);
    }
  }

  /// Aktualisiert den Transkriptionstext eines Audio-Anhangs.
  Future<void> updateTranscription(String attachmentId, String text) =>
      _dao.updateTextContent(id: attachmentId, transcription: text);

  // ── Hintergrund-Hilfsmethoden ──────────────────────────────────────────

  Future<void> _runOcrInBackground({
    required String id,
    required File imageFile,
  }) async {
    final text = await _ocrService.recognizeText(imageFile);
    if (text != null) {
      await _dao.updateTextContent(id: id, ocrText: text);
    }
  }
}
