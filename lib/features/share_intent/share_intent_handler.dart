// Datei: lib/features/share_intent/share_intent_handler.dart
//
// ZWECK: Verarbeitet eingehende Share-Intents von anderen Apps (Text, URLs, Bilder).
//        Wird einmalig in main.dart initialisiert und hört auf Intents während
//        der gesamten App-Lebensdauer.
// ABHÄNGIGKEITEN: receive_sharing_intent, entryRepositoryProvider,
//                 attachmentRepositoryProvider, propertyDaoProvider.
// PHASE: 2 – Share-to-Capture via Android Share-Intent.

import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uuid/uuid.dart';

import '../../core/di.dart';
import '../../data/db/database.dart' hide Container;
import '../../data/db/daos/property_dao.dart';
import '../../data/db/tables/entries.dart';
import '../../data/db/tables/property_definitions.dart';

/// Verarbeitet eingehende Share-Intents und speichert sie als Einträge.
///
/// WARUM kein eigener Screen für Share-Intents?
/// BiNo ist eine Capture-App: geteilte Inhalte sollen sofort in den Inbox
/// wandern ohne weitere Nutzerinteraktion. Ein optionaler "Bestätigung"-Screen
/// kann in Phase 5 (AI-Enrichment) ergänzt werden.
class ShareIntentHandler extends ConsumerStatefulWidget {
  final Widget child;

  const ShareIntentHandler({super.key, required this.child});

  @override
  ConsumerState<ShareIntentHandler> createState() => _ShareIntentHandlerState();
}

class _ShareIntentHandlerState extends ConsumerState<ShareIntentHandler> {
  static const _uuid = Uuid();

  /// Subscription auf Intents während die App läuft.
  late final Stream<List<SharedMediaFile>> _intentStream;

  @override
  void initState() {
    super.initState();

    // Intents verarbeiten die gesendet wurden während die App bereits lief.
    _intentStream = ReceiveSharingIntent.instance.getMediaStream();
    _intentStream.listen(_processSharedFiles);

    // Initiale Intents verarbeiten (App wurde durch den Intent gestartet).
    ReceiveSharingIntent.instance.getInitialMedia().then(_processSharedFiles);
  }

  Future<void> _processSharedFiles(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;

    final entryRepo = ref.read(entryRepositoryProvider);
    final attachmentRepo = ref.read(attachmentRepositoryProvider);
    final propertyDao = ref.read(propertyDaoProvider);
    final workspaceId = ref.read(activeWorkspaceProvider);

    for (final file in files) {
      try {
        switch (file.type) {
          case SharedMediaType.text:
          case SharedMediaType.url:
            final text = file.path;
            final isUrl = text.startsWith('http://') || text.startsWith('https://');
            if (isUrl) {
              // Metadaten laden damit im Feed Titel + Beschreibung statt
              // nur der rohen URL erscheinen.
              final urlService = ref.read(urlMetadataServiceProvider);
              final meta = await urlService.fetch(text);
              final entryId = await entryRepo.createEntry(
                title: meta?.title,
                body: meta?.description ?? text,
                type: EntryType.link,
                sourceUrl: text,
                sourceApp: 'share_intent',
              );
              // Quelle als klickbare Property speichern.
              await _saveProperty(
                propertyDao: propertyDao,
                workspaceId: workspaceId,
                entryId: entryId,
                name: 'Quelle',
                type: PropertyFieldType.url,
                jsonValue: jsonEncode(text),
              );
            } else {
              await entryRepo.createEntry(
                body: text,
                type: EntryType.text,
                sourceApp: 'share_intent',
              );
            }

          case SharedMediaType.image:
            final imageEntryId = await entryRepo.createEntry(
              title: _filenameWithout(file.path),
              body: '',
              type: EntryType.image,
              sourceApp: 'share_intent',
            );
            await attachmentRepo.saveImage(
              entryId: imageEntryId,
              imageFile: File(file.path),
            );

          case SharedMediaType.video:
            final videoEntryId = await entryRepo.createEntry(
              title: _filenameWithout(file.path),
              body: '',
              type: EntryType.video,
              sourceApp: 'share_intent',
            );
            final videoMime =
                file.mimeType ?? lookupMimeType(file.path) ?? 'video/mp4';
            await attachmentRepo.saveVideo(
              entryId: videoEntryId,
              videoFile: File(file.path),
              mimeType: videoMime,
              durationMs: file.duration,
            );

          case SharedMediaType.file:
            // receive_sharing_intent liefert Audio-Dateien als SharedMediaType.file.
            // MIME-Typ: zuerst vom Paket (file.mimeType), dann aus der Dateiendung.
            final detectedMime =
                file.mimeType ?? lookupMimeType(file.path) ?? '';

            if (detectedMime.startsWith('audio/')) {
              // Audio-Metadaten auslesen (ID3, FLAC-Tags, …)
              final meta = await _readAudioMeta(file.path);
              final title = (meta?.title?.isNotEmpty == true)
                  ? meta!.title!
                  : _filenameWithout(file.path);
              final durationMs =
                  meta?.duration?.inMilliseconds ?? file.duration;

              final audioEntryId = await entryRepo.createEntry(
                title: title,
                body: '',
                type: EntryType.audio,
                sourceApp: 'share_intent',
              );
              await attachmentRepo.saveAudio(
                entryId: audioEntryId,
                audioFile: File(file.path),
                mimeType: detectedMime,
                durationMs: durationMs,
              );
              // Metadaten-Felder als Properties statt als Body-Text.
              await _saveAudioMetaAsProperties(
                propertyDao: propertyDao,
                workspaceId: workspaceId,
                entryId: audioEntryId,
                meta: meta,
              );
            } else if (detectedMime.startsWith('image/')) {
              final fileImageId = await entryRepo.createEntry(
                title: _filenameWithout(file.path),
                body: '',
                type: EntryType.image,
                sourceApp: 'share_intent',
              );
              await attachmentRepo.saveImage(
                entryId: fileImageId,
                imageFile: File(file.path),
                mimeType: detectedMime,
              );
            } else if (detectedMime.startsWith('video/')) {
              final fileVideoId = await entryRepo.createEntry(
                title: _filenameWithout(file.path),
                body: '',
                type: EntryType.video,
                sourceApp: 'share_intent',
              );
              await attachmentRepo.saveVideo(
                entryId: fileVideoId,
                videoFile: File(file.path),
                mimeType: detectedMime,
                durationMs: file.duration,
              );
            } else {
              // PDF, Dokumente usw. – speichern ohne spezifische Verarbeitung
              await entryRepo.createEntry(
                title: _filenameWithout(file.path),
                body: '',
                type: EntryType.mixed,
                sourceApp: 'share_intent',
              );
            }
        }
      } catch (e) {
        // Fehler beim Verarbeiten eines einzelnen Intents sollen die anderen
        // nicht blockieren – deshalb wird hier nicht geworfen.
        debugPrint('ShareIntentHandler: Fehler bei $file: $e');
      }
    }

    // Intent als verarbeitet markieren, damit er beim nächsten Start nicht
    // erneut verarbeitet wird.
    ReceiveSharingIntent.instance.reset();
    // Kein SnackBar hier: ShareIntentHandler sitzt oberhalb von MaterialApp
    // und hat daher keinen ScaffoldMessenger-Vorfahren. Die gespeicherten
    // Einträge erscheinen automatisch im Feed.
  }

  /// Speichert Audio-Metadaten als einzelne Properties (statt als Body-Text).
  Future<void> _saveAudioMetaAsProperties({
    required PropertyDao propertyDao,
    required String workspaceId,
    required String entryId,
    required Metadata? meta,
  }) async {
    if (meta == null) return;
    if (meta.artist?.isNotEmpty == true) {
      await _saveProperty(
        propertyDao: propertyDao,
        workspaceId: workspaceId,
        entryId: entryId,
        name: 'Interpret',
        type: PropertyFieldType.text,
        jsonValue: jsonEncode(meta.artist),
      );
    }
    if (meta.album?.isNotEmpty == true) {
      await _saveProperty(
        propertyDao: propertyDao,
        workspaceId: workspaceId,
        entryId: entryId,
        name: 'Album',
        type: PropertyFieldType.text,
        jsonValue: jsonEncode(meta.album),
      );
    }
    if (meta.genre?.isNotEmpty == true) {
      await _saveProperty(
        propertyDao: propertyDao,
        workspaceId: workspaceId,
        entryId: entryId,
        name: 'Genre',
        type: PropertyFieldType.text,
        jsonValue: jsonEncode(meta.genre),
      );
    }
    if (meta.year != null) {
      await _saveProperty(
        propertyDao: propertyDao,
        workspaceId: workspaceId,
        entryId: entryId,
        name: 'Jahr',
        type: PropertyFieldType.text,
        jsonValue: jsonEncode(meta.year.toString()),
      );
    }
    if (meta.trackNumber != null) {
      await _saveProperty(
        propertyDao: propertyDao,
        workspaceId: workspaceId,
        entryId: entryId,
        name: 'Track',
        type: PropertyFieldType.number,
        jsonValue: meta.trackNumber.toString(),
      );
    }
  }

  /// Findet oder erstellt eine PropertyDefinition und speichert den Wert.
  ///
  /// WARUM find-or-create?
  /// Geteilte Dateien sollen Definitionen workspace-weit teilen. Beim zweiten
  /// Import einer MP3 existiert "Interpret" bereits – kein Duplikat entstehen.
  Future<void> _saveProperty({
    required PropertyDao propertyDao,
    required String workspaceId,
    required String entryId,
    required String name,
    required PropertyFieldType type,
    required String jsonValue,
  }) async {
    var def = await propertyDao.findDefinitionByName(workspaceId, name);
    if (def == null) {
      final defId = _uuid.v4();
      await propertyDao.insertDefinition(
        PropertyDefinitionsCompanion.insert(
          id: defId,
          workspaceId: Value(workspaceId),
          name: name,
          fieldType: type.name,
        ),
      );
      def = await propertyDao.findDefinitionByName(workspaceId, name);
      if (def == null) return;
    }

    // Nur einfügen wenn noch kein Wert für diesen Eintrag vorhanden ist.
    final existing = await propertyDao.findPropertyValue(entryId, def.id);
    if (existing != null) return;

    await propertyDao.insertProperty(
      EntryPropertiesCompanion.insert(
        id: _uuid.v4(),
        entryId: entryId,
        propertyId: def.id,
        value: Value(jsonValue),
      ),
    );
  }

  /// Dateiname ohne Erweiterung als Titelvorschlag.
  String _filenameWithout(String path) {
    final name = p.basenameWithoutExtension(path);
    // URL-kodierte Zeichen dekodieren (z. B. %20 → Leerzeichen)
    try {
      return Uri.decodeComponent(name);
    } catch (_) {
      return name;
    }
  }

  /// Liest Audio-Metadaten via metadata_god (ID3, FLAC-Tags, …).
  ///
  /// Gibt null zurück wenn die Datei kein unterstütztes Format hat oder
  /// das Lesen fehlschlägt – der Aufrufer fällt dann auf den Dateinamen zurück.
  Future<Metadata?> _readAudioMeta(String path) async {
    try {
      return await MetadataGod.readMetadata(file: path);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
