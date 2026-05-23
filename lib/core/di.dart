// Datei: lib/core/di.dart
//
// ZWECK: Dependency-Injection-Wurzel der App via Riverpod.
//        Definiert alle "singleton-artigen" Provider für DB, DAOs, Services und Repositories.
// ABHÄNGIGKEITEN: database.dart, alle DAOs, Services und Repositories.
// MUSTER: Provider-basiertes DI (Riverpod).
// PHASE: 1 – Grundgerüst. Phase 2: AttachmentDao, AttachmentService,
//        OcrService, SttService, UrlMetadataService, AttachmentRepository.
//
// WARUM Riverpod statt get_it oder service_locator?
// Riverpod-Provider sind scoped und können in Tests via ProviderContainer
// mit overrides() überschrieben werden – ohne globale Singletons zurückzusetzen.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/db/daos/entry_dao.dart';
import '../data/db/daos/tag_dao.dart';
import '../data/db/daos/container_dao.dart';
import '../data/db/daos/attachment_dao.dart';
import '../data/repositories/entry_repository.dart';
import '../data/repositories/attachment_repository.dart';
import '../data/ml/ocr_service.dart';
import '../data/ml/stt_service.dart';
import '../services/attachment_service.dart';
import '../services/backup_service.dart';
import '../services/url_metadata_service.dart';

// ── Datenbank ──────────────────────────────────────────────────────────────

/// Öffnet und hält die AppDatabase für die gesamte App-Lebensdauer.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}, name: 'databaseProvider');

// ── DAOs ──────────────────────────────────────────────────────────────────

/// EntryDao – einzeln überschreibbar in Tests ohne die gesamte DB zu mocken.
final entryDaoProvider = Provider<EntryDao>((ref) {
  return ref.watch(databaseProvider).entryDao;
}, name: 'entryDaoProvider');

final tagDaoProvider = Provider<TagDao>((ref) {
  return ref.watch(databaseProvider).tagDao;
}, name: 'tagDaoProvider');

final containerDaoProvider = Provider<ContainerDao>((ref) {
  return ref.watch(databaseProvider).containerDao;
}, name: 'containerDaoProvider');

final attachmentDaoProvider = Provider<AttachmentDao>((ref) {
  return ref.watch(databaseProvider).attachmentDao;
}, name: 'attachmentDaoProvider');

// ── Services ──────────────────────────────────────────────────────────────

/// AttachmentService: Dateiverwaltung im App-Dokumentenverzeichnis.
/// keepAlive: true – der Service hält keine DB-Verbindung, aber das Dateisystem-
/// Handle soll nicht bei jedem Render neu aufgelöst werden.
final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  return AttachmentService();
}, name: 'attachmentServiceProvider');

/// OcrService: Singleton da das Laden des ML-Kit-Modells ~200 ms kostet.
/// WARUM keepAlive (via onDispose)?
/// Riverpod würde den Provider bei keepAlive: false disposen wenn kein Widget
/// mehr hört. Bei ML-Kit-Services würde dann beim nächsten Aufruf das Modell
/// neu geladen werden. Als workaround nutzen wir den globalen Provider ohne autoDispose.
final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  // Sauberes Schließen des ML-Kit-TextRecognizer beim App-Ende.
  ref.onDispose(service.dispose);
  return service;
}, name: 'ocrServiceProvider');

/// SttService: Speech-to-Text (lokal, on-device).
final sttServiceProvider = Provider<SttService>((ref) {
  return SttService();
}, name: 'sttServiceProvider');

/// UrlMetadataService: Open-Graph-Fetch für Link-Einträge.
final urlMetadataServiceProvider = Provider<UrlMetadataService>((ref) {
  return UrlMetadataService();
}, name: 'urlMetadataServiceProvider');

/// BackupService: Export und Import der App-Daten als ZIP.
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
}, name: 'backupServiceProvider');

// ── Workspace ─────────────────────────────────────────────────────────────

/// Aktiver Workspace-ID. Default: 'default' (wird in Phase 4 via WorkspaceScreen geändert).
final activeWorkspaceProvider = StateProvider<String>(
  (ref) => 'default',
  name: 'activeWorkspaceProvider',
);

// ── Repositories ──────────────────────────────────────────────────────────

/// EntryRepository – Hauptkoordinator für Eintrags-Logik.
final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  return EntryRepository(
    entryDao: ref.watch(entryDaoProvider),
    tagDao: ref.watch(tagDaoProvider),
    attachmentRepo: ref.watch(attachmentRepositoryProvider),
  );
}, name: 'entryRepositoryProvider');

/// AttachmentRepository – koordiniert Dateisystem + DB + OCR für Anhänge.
final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  return AttachmentRepository(
    dao: ref.watch(attachmentDaoProvider),
    fileService: ref.watch(attachmentServiceProvider),
    ocrService: ref.watch(ocrServiceProvider),
  );
}, name: 'attachmentRepositoryProvider');
