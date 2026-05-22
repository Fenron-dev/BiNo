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
            await entryRepo.createEntry(
              body: text,
              type: isUrl ? EntryType.link : EntryType.text,
              sourceUrl: isUrl ? text : null,
              sourceApp: 'share_intent',
            );

          case SharedMediaType.image:
            final entryId = await entryRepo.createEntry(
              body: '',
              type: EntryType.image,
              sourceApp: 'share_intent',
            );
            await attachmentRepo.saveImage(
              entryId: entryId,
              imageFile: File(file.path),
            );

          default:
            // Andere Typen (Video, etc.) werden in späteren Phasen unterstützt.
            break;
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            files.length == 1
                ? 'Inhalt in BiNo gespeichert'
                : '${files.length} Inhalte in BiNo gespeichert',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
