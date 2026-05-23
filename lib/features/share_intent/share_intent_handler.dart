// Datei: lib/features/share_intent/share_intent_handler.dart
//
// ZWECK: Verarbeitet eingehende Share-Intents von anderen Apps (Text, URLs, Bilder).
//        Wird einmalig in main.dart initialisiert und hört auf Intents während
//        der gesamten App-Lebensdauer.
// ABHÄNGIGKEITEN: receive_sharing_intent, entryRepositoryProvider,
//                 attachmentRepositoryProvider.
// PHASE: 2 – Share-to-Capture via Android Share-Intent.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../core/di.dart';
import '../../data/db/tables/entries.dart';

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
              await entryRepo.createEntry(
                title: meta?.title,
                body: meta?.description ?? text,
                type: EntryType.link,
                sourceUrl: text,
                sourceApp: 'share_intent',
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
              final body = _formatAudioMeta(meta);
              final durationMs =
                  meta?.duration?.inMilliseconds ?? file.duration;

              final audioEntryId = await entryRepo.createEntry(
                title: title,
                body: body,
                type: EntryType.audio,
                sourceApp: 'share_intent',
              );
              await attachmentRepo.saveAudio(
                entryId: audioEntryId,
                audioFile: File(file.path),
                mimeType: detectedMime,
                durationMs: durationMs,
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

  /// Formatiert Audio-Metadaten als lesbaren Body-Text.
  ///
  /// Gibt einen leeren String zurück, wenn keine relevanten Felder vorhanden sind.
  String _formatAudioMeta(Metadata? meta) {
    if (meta == null) return '';
    final lines = <String>[];
    if (meta.artist?.isNotEmpty == true) lines.add('Interpret: ${meta.artist}');
    if (meta.album?.isNotEmpty == true) {
      final albumLine = meta.year != null
          ? 'Album: ${meta.album} (${meta.year})'
          : 'Album: ${meta.album}';
      lines.add(albumLine);
    }
    if (meta.genre?.isNotEmpty == true) lines.add('Genre: ${meta.genre}');
    if (meta.trackNumber != null) lines.add('Track: ${meta.trackNumber}');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
