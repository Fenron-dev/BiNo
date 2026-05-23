// Datei: lib/features/entry_detail/entry_detail_screen.dart
//
// ZWECK: Vollansicht eines Eintrags. Zeigt den gesamten Text, alle Bilder
//        (zoombar) und einen Audio-Player. Ermöglicht Pinnen und Löschen.
// ABHÄNGIGKEITEN: just_audio, entryRepositoryProvider, attachmentRepositoryProvider,
//                 path_provider, path.
// PHASE: 3 – Detail-Ansicht, Audio-Wiedergabe, Pin/Unpin, Löschen.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/di.dart';
// 'Container' aus database.dart ausblenden – kollidiert mit Flutter's Container-Widget.
import '../../data/db/database.dart' hide Container;

// ── Provider ─────────────────────────────────────────────────────────────────

/// Lädt einen einzelnen Eintrag per ID. Wird beim Öffnen der Detailansicht
/// einmalig aufgerufen; Pinnen/Löschen invalidieren den Provider nicht,
/// da wir danach navigieren.
final _entryProvider = FutureProvider.autoDispose
    .family<Entry?, String>((ref, id) {
  return ref.read(entryRepositoryProvider).getEntryById(id);
});

/// Beobachtet Anhänge reaktiv (Bild/Audio erscheinen sofort nach Capture).
final _attachmentsProvider = StreamProvider.autoDispose
    .family<List<Attachment>, String>((ref, entryId) {
  return ref.watch(attachmentRepositoryProvider).watchForEntry(entryId);
});

// ── Screen ────────────────────────────────────────────────────────────────────

/// Vollansicht eines Eintrags.
class EntryDetailScreen extends ConsumerStatefulWidget {
  final String entryId;

  const EntryDetailScreen({super.key, required this.entryId});

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  /// Ob gerade eine Aktion (Löschen) läuft – verhindert Doppelklicks.
  bool _isActing = false;

  // ── Aktionen ──────────────────────────────────────────────────────────────

  Future<void> _togglePin(Entry entry) async {
    await ref.read(entryRepositoryProvider).togglePin(entry.id);
    // Seite neu bauen damit das Pin-Icon sofort wechselt.
    ref.invalidate(_entryProvider(widget.entryId));
  }

  Future<void> _confirmDelete(BuildContext context, Entry entry) async {
    // Router vor allen async-Lücken sichern.
    final router = GoRouter.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: const Text(
          'Dieser Eintrag und alle zugehörigen Anhänge werden dauerhaft gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActing = true);
    await ref.read(entryRepositoryProvider).deleteEntry(entry.id);
    if (mounted) router.pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final entryAsync = ref.watch(_entryProvider(widget.entryId));

    return entryAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Eintrag nicht gefunden.')),
      ),
      data: (entry) {
        if (entry == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Eintrag nicht gefunden.')),
          );
        }
        return _EntryView(
          entry: entry,
          isActing: _isActing,
          onTogglePin: () => _togglePin(entry),
          onDelete: () => _confirmDelete(context, entry),
        );
      },
    );
  }
}

// ── Eintrag-Ansicht ───────────────────────────────────────────────────────────

class _EntryView extends ConsumerWidget {
  final Entry entry;
  final bool isActing;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;

  const _EntryView({
    required this.entry,
    required this.isActing,
    required this.onTogglePin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final attachmentsAsync = ref.watch(_attachmentsProvider(entry.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('dd.MM.yyyy, HH:mm', 'de_DE').format(
            entry.createdAt.toLocal(),
          ),
          style: theme.textTheme.titleSmall,
        ),
        actions: [
          // Pin / Unpin
          IconButton(
            icon: Icon(
              entry.pinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: entry.pinned ? theme.colorScheme.primary : null,
            ),
            tooltip: entry.pinned ? 'Losösen' : 'Anpinnen',
            onPressed: isActing ? null : onTogglePin,
          ),
          // Löschen
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: theme.colorScheme.error),
            tooltip: 'Löschen',
            onPressed: isActing ? null : onDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Titel (optional)
          if (entry.title != null && entry.title!.isNotEmpty) ...[
            SelectableText(
              entry.title!,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
          ],

          // Body
          if (entry.body.isNotEmpty)
            SelectableText(
              entry.body,
              style: theme.textTheme.bodyLarge,
            ),

          // Anhänge
          attachmentsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (attachments) => _AttachmentSection(
              attachments: attachments,
            ),
          ),

          // URL-Quelle
          if (entry.sourceUrl != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 4),
            Text(
              entry.sourceUrl!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Anhänge-Bereich ───────────────────────────────────────────────────────────

class _AttachmentSection extends StatelessWidget {
  final List<Attachment> attachments;

  const _AttachmentSection({required this.attachments});

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final images =
        attachments.where((a) => a.mimeType.startsWith('image/')).toList();
    final audios =
        attachments.where((a) => a.mimeType.startsWith('audio/')).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ImageGallery(images: images),
        ],
        for (final audio in audios) ...[
          const SizedBox(height: 12),
          _AudioPlayerWidget(attachment: audio),
        ],
      ],
    );
  }
}

// ── Bild-Galerie ──────────────────────────────────────────────────────────────

class _ImageGallery extends StatelessWidget {
  final List<Attachment> images;

  const _ImageGallery({required this.images});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Directory>(
      future: getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final basePath = p.join(snapshot.data!.path, 'attachments');

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: images.map((img) {
            final file = File(p.join(basePath, img.filePath));
            return GestureDetector(
              onTap: () => _showFullscreen(context, file),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 160,
                    height: 160,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showFullscreen(BuildContext context, File file) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: InteractiveViewer(
            child: Center(
              child: Image.file(file, errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Audio-Player ──────────────────────────────────────────────────────────────

/// Play/Pause-Player für einen Audio-Anhang (media_kit-basiert).
///
/// WARUM media_kit statt just_audio?
/// media_kit unterstützt einheitlich Audio und Video, hat einen aktiv
/// gepflegten Android-Backend und ermöglicht Resume-Funktionalität
/// über player.state.position.
class _AudioPlayerWidget extends StatefulWidget {
  final Attachment attachment;

  const _AudioPlayerWidget({required this.attachment});

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  late final Player _player;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _loadAudio();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadAudio() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final path =
          p.join(appDir.path, 'attachments', widget.attachment.filePath);
      await _player.open(Media(Uri.file(path).toString()), play: false);
      if (mounted) setState(() => _isLoaded = true);
    } catch (_) {
      // Datei nicht lesbar – Player bleibt deaktiviert.
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatMs(int? ms) {
    if (ms == null) return '--:--';
    return _formatDuration(Duration(milliseconds: ms));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Play/Pause/Replay-Button
          StreamBuilder<bool>(
            stream: _player.stream.playing,
            builder: (context, playSnap) {
              return StreamBuilder<bool>(
                stream: _player.stream.completed,
                builder: (context, compSnap) {
                  final playing = playSnap.data ?? false;
                  final completed = compSnap.data ?? false;

                  return IconButton(
                    icon: Icon(
                      completed
                          ? Icons.replay
                          : playing
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                      size: 36,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    onPressed: _isLoaded
                        ? () async {
                            if (completed) {
                              await _player.seek(Duration.zero);
                              await _player.play();
                            } else if (playing) {
                              await _player.pause();
                            } else {
                              await _player.play();
                            }
                          }
                        : null,
                  );
                },
              );
            },
          ),

          const SizedBox(width: 8),

          // Seeker + Zeitanzeige
          Expanded(
            child: StreamBuilder<Duration>(
              stream: _player.stream.position,
              builder: (context, posSnap) {
                final position = posSnap.data ?? Duration.zero;
                final duration = _player.state.duration;
                final progress = duration.inMilliseconds > 0
                    ? (position.inMilliseconds / duration.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0;

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: _isLoaded
                            ? (v) => _player.seek(
                                  Duration(
                                    milliseconds:
                                        (v * duration.inMilliseconds).round(),
                                  ),
                                )
                            : null,
                        activeColor: theme.colorScheme.onSecondaryContainer,
                        inactiveColor: theme.colorScheme.onSecondaryContainer
                            .withAlpha(64),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        Text(
                          _formatMs(widget.attachment.durationMs),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
