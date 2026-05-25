// Datei: lib/data/repositories/entry_repository.dart
//
// ZWECK: Koordiniert alle Geschäftslogik rund um Einträge. Verbindet
//        EntryDao, TagDao und TagParser zu atomaren Operationen.
// ABHÄNGIGKEITEN: EntryDao, TagDao, TagParser, drift (Value), uuid.
// MUSTER: Repository – hält SQL-Logik (DAO) von Geschäftslogik getrennt.
// PHASE: 1 – createEntry + watchAllEntries. Phase 2+ fügt updateEntry,
//        deleteEntry, Embedding-Trigger und OCR-Verarbeitung hinzu.

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../db/daos/entry_dao.dart';
import '../db/daos/tag_dao.dart';
import '../db/tables/entries.dart';
import '../repositories/attachment_repository.dart';
import '../../domain/tag_parser.dart';

/// Repository für Einträge.
///
/// WARUM ein Repository statt direkte DAO-Aufrufe aus den Providern?
/// (1) Provider bleiben dünn – sie rufen eine Methode auf, das Repository
///     übernimmt die Komplexität (Tag-Parsing, UUID-Vergabe, Transaktionen).
/// (2) Geschäftsregeln (z. B. "keine leeren Einträge") sind testbar ohne UI.
/// (3) Phase 2-5 fügen Embedding-Trigger, Share-Intent-Behandlung und
///     Cloud-KI-Calls hinzu – ohne Änderungen an Providern oder UI.
class EntryRepository {
  final EntryDao _entryDao;
  final TagDao _tagDao;
  final AttachmentRepository _attachmentRepo;
  final Uuid _uuid;

  EntryRepository({
    required EntryDao entryDao,
    required TagDao tagDao,
    required AttachmentRepository attachmentRepo,
    Uuid? uuid,
  })  : _entryDao = entryDao,
        _tagDao = tagDao,
        _attachmentRepo = attachmentRepo,
        _uuid = uuid ?? const Uuid();

  /// Gibt einen einzelnen Eintrag zurück, oder null wenn nicht gefunden.
  Future<Entry?> getEntryById(String id) => _entryDao.getEntryById(id);

  /// Beobachtet einen einzelnen Eintrag reaktiv (für Detail- und Edit-Screen).
  Stream<Entry?> watchEntryById(String id) => _entryDao.watchEntryById(id);

  /// Beobachtet alle Einträge als reaktiven Stream.
  ///
  /// Der Stream wird von Drift automatisch neu ausgelöst, wenn sich
  /// Einträge in der Datenbank ändern. Riverpod's StreamProvider leitet
  /// diese Änderungen direkt an die UI weiter.
  Stream<List<Entry>> watchAllEntries(String workspaceId) =>
      _entryDao.watchAllEntries(workspaceId);

  /// Erstellt einen neuen Eintrag und verknüpft alle im Body enthaltenen Tags.
  ///
  /// Alle Schritte laufen in einer einzigen Datenbank-Transaktion:
  /// WARUM Transaktion? Würde der Eintrag ohne Tags gespeichert, wäre der
  /// FTS5-Index zwar synchron, aber die Tag-Verknüpfungen fehlten – ein
  /// inkonsistenter Zustand. Die Transaktion stellt Atomarität sicher.
  ///
  /// Gibt die UUID des neuen Eintrags zurück, damit der FeedScreen
  /// zu diesem Eintrag scrollen kann.
  Future<String> createEntry({
    required String body,
    String? title,
    EntryType type = EntryType.text,
    EntryStatus status = EntryStatus.inbox,
    String? sourceUrl,
    String? sourceApp,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();

    // attachedDatabase liefert Zugang zur Transaktion des übergeordneten DB-Objekts.
    await _entryDao.attachedDatabase.transaction(() async {
      // Schritt 1: Eintrag speichern.
      // Value() ist der Drift-Wrapper für optionale und explizit gesetzte Felder.
      await _entryDao.insertEntry(
        EntriesCompanion.insert(
          id: id,
          body: Value(body),
          title: Value(title),
          type: Value(type.name),
          status: Value(status.name),
          createdAt: Value(now),
          updatedAt: Value(now),
          sourceUrl: Value(sourceUrl),
          sourceApp: Value(sourceApp),
        ),
      );

      // Schritt 2: Tags aus dem Body parsen und verknüpfen.
      await _syncTagsForEntry(id: id, body: body);
    });

    return id;
  }

  /// Aktualisiert Titel, Body und Notizen eines bestehenden Eintrags.
  ///
  /// Tags werden neu aus dem Body geparst und synchronisiert:
  /// gelöschte Tags verlieren ihre Verknüpfung, neue werden angelegt.
  Future<void> updateEntry({
    required String id,
    String? title,
    required String body,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();
    await _entryDao.attachedDatabase.transaction(() async {
      await _entryDao.updateEntryFields(
        id: id,
        title: title,
        body: body,
        notes: notes,
        updatedAt: now,
      );
      // Tags neu synchronisieren: alte Links entfernen, neue setzen.
      await _syncTagsForEntry(id: id, body: body, isUpdate: true);
    });
  }

  /// Löscht einen Eintrag mit allen Anhängen (Dateisystem + DB) und Tag-Links.
  Future<void> deleteEntry(String id) async {
    // Anhang-Dateien + DB-Records zuerst bereinigen (Pfade noch vorhanden).
    await _attachmentRepo.deleteAllForEntry(id);
    await _entryDao.attachedDatabase.transaction(() async {
      await _tagDao.unlinkAllTagsFromEntry(id);
      await _entryDao.deleteEntry(id);
    });
  }

  /// Schaltet den Pinned-Status eines Eintrags um.
  Future<void> togglePin(String id) => _entryDao.togglePin(id);

  /// Setzt oder löscht den Erinnerungszeitpunkt. Notification-Scheduling ist
  /// Aufgabe des Aufrufers (UI-Schicht via NotificationService).
  Future<void> setReminderAt(String id, DateTime? reminderAt) =>
      _entryDao.setReminderAt(id, reminderAt);

  /// Durchsucht Einträge via FTS5-Volltext-Index.
  Future<List<Entry>> searchEntries(String query) =>
      _entryDao.searchEntries(query);

  /// Parst Tags aus [body] und synchronisiert die entry_tags-Verknüpfungen.
  ///
  /// Bei [isUpdate] = true werden zuerst alle bestehenden Verknüpfungen
  /// entfernt, dann die neuen angelegt. So werden gelöschte Tags korrekt
  /// aus dem Eintrag entfernt.
  Future<void> _syncTagsForEntry({
    required String id,
    required String body,
    bool isUpdate = false,
  }) async {
    if (isUpdate) {
      // Alle alten Tag-Links entfernen, bevor die neuen aus dem aktuellen
      // Body-Text geparst und neu verknüpft werden.
      await _tagDao.unlinkAllTagsFromEntry(id);
    }

    final tagNames = TagParser.parse(body);
    for (final tagName in tagNames) {
      final tagId = await _findOrCreateTag(tagName);
      await _tagDao.linkTagToEntry(id, tagId);
    }
  }

  /// Sucht einen Tag anhand des vollständigen Namens oder legt ihn neu an.
  ///
  /// Unterstützt hierarchische Tags: 'buch/sachbuch' stellt sicher, dass
  /// 'buch' existiert (wird ggf. angelegt), bevor 'buch/sachbuch' erstellt wird.
  /// Rekursion bricht ab, wenn kein '/' mehr im Namen vorhanden ist.
  ///
  /// WARUM rekursiv statt iterativ?
  /// Die Tiefe ist durch sinnvolle Tag-Hierarchien auf 3-4 Ebenen begrenzt
  /// und Dart-Stacks sind für diese Tiefe gut geeignet.
  Future<String> _findOrCreateTag(String fullName) async {
    // Existiert der Tag bereits? Dann nur die UUID zurückgeben.
    final existing = await _tagDao.getTagByName(fullName);
    if (existing != null) return existing.id;

    // Eltern-Tag sicherstellen, falls hierarchisch (enthält '/').
    String? parentId;
    final parts = fullName.split('/');
    if (parts.length > 1) {
      final parentName = parts.sublist(0, parts.length - 1).join('/');
      parentId = await _findOrCreateTag(parentName); // Rekursiv.
    }

    // Neuen Tag anlegen.
    final tagId = _uuid.v4();
    await _tagDao.insertTag(
      TagsCompanion.insert(
        id: tagId,
        name: fullName,
        parentId: Value(parentId),
      ),
    );
    return tagId;
  }
}
