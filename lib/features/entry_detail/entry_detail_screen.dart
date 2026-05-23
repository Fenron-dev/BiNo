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
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:convert';

import '../../core/constants.dart';
import '../../core/di.dart';
// 'Container' aus database.dart ausblenden – kollidiert mit Flutter's Container-Widget.
import '../../data/db/database.dart' hide Container;
import '../../data/db/tables/property_definitions.dart';
import '../containers/container_form_sheet.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

/// Beobachtet einen einzelnen Eintrag reaktiv.
///
/// WARUM StreamProvider statt FutureProvider?
/// Der Edit-Screen schreibt in die DB. StreamProvider reagiert automatisch
/// auf Änderungen, ohne dass der Provider manuell invalidiert werden muss.
/// Pinnen und Bearbeiten spiegeln sich sofort im AppBar-Icon und Titel wider.
final _entryProvider = StreamProvider.autoDispose
    .family<Entry?, String>((ref, id) {
  return ref.watch(entryRepositoryProvider).watchEntryById(id);
});

/// Beobachtet Anhänge reaktiv (Bild/Audio erscheinen sofort nach Capture).
final _attachmentsProvider = StreamProvider.autoDispose
    .family<List<Attachment>, String>((ref, entryId) {
  return ref.watch(attachmentRepositoryProvider).watchForEntry(entryId);
});

/// Beobachtet gesetzte Property-Werte für einen Eintrag.
final _detailPropertiesProvider = StreamProvider.autoDispose
    .family<List<EntryProperty>, String>((ref, entryId) {
  return ref.watch(propertyDaoProvider).watchPropertiesForEntry(entryId);
});

/// Beobachtet Property-Definitionen für einen Workspace.
final _detailDefinitionsProvider = StreamProvider.autoDispose
    .family<List<PropertyDefinition>, String>((ref, workspaceId) {
  return ref.watch(propertyDaoProvider).watchDefinitionsForWorkspace(workspaceId);
});

/// Beobachtet die Container, denen ein Eintrag zugewiesen ist.
/// List<dynamic> wird genutzt um den Drift-Container-Namenskonflikt mit
/// Flutter's Container-Widget in dieser Datei zu umgehen.
final _entryContainersProvider = StreamProvider.autoDispose
    .family<List<dynamic>, String>((ref, entryId) {
  return ref.watch(containerDaoProvider).watchContainersForEntry(entryId);
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
    // StreamProvider aktualisiert sich automatisch – kein manuelles Invalidate nötig.
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
    final workspaceId = ref.watch(activeWorkspaceProvider);
    final propsAsync = ref.watch(_detailPropertiesProvider(entry.id));
    final defsAsync = ref.watch(_detailDefinitionsProvider(workspaceId));
    final containersAsync = ref.watch(_entryContainersProvider(entry.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('dd.MM.yyyy, HH:mm', 'de_DE').format(
            entry.createdAt.toLocal(),
          ),
          style: theme.textTheme.titleSmall,
        ),
        actions: [
          // Bearbeiten
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Bearbeiten',
            onPressed: isActing
                ? null
                : () => context.push('/feed/detail/${entry.id}/edit'),
          ),
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

          // Notizen (falls vorhanden)
          if (entry.notes != null && entry.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.edit_note,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Anmerkungen',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              entry.notes!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Properties (nur wenn mindestens ein Wert gesetzt ist)
          propsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (props) {
              if (props.isEmpty) return const SizedBox.shrink();
              return defsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (defs) {
                  // Nur Definitionen anzeigen, für die ein Wert gesetzt ist
                  final setProps = props
                      .map((p) {
                        final def = defs.where((d) => d.id == p.propertyId).firstOrNull;
                        return def != null ? (def, p) : null;
                      })
                      .whereType<(PropertyDefinition, EntryProperty)>()
                      .toList();
                  if (setProps.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      ...setProps.map(
                        (pair) => _PropertyRow(
                          definition: pair.$1,
                          property: pair.$2,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // Container-Badges (Projekte / Bereiche)
          containersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (containers) {
              if (containers.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: containers.map((c) {
                      // c ist dynamisch (Drift Container, aber Container-Widget ist
                      // in dieser Datei versteckt) → Property-Zugriff via dynamic dispatch.
                      final id = c.id as String;
                      final name = c.name as String;
                      final icon = c.icon as String;
                      final color = c.color as String;
                      final kind = c.kind as String;
                      return ActionChip(
                        avatar: Icon(
                          containerIconData(icon),
                          size: 16,
                          color: hexToColor(color),
                        ),
                        label: Text(name),
                        onPressed: () => context.push(
                          AppRoutes.containerDetail(id),
                          extra: {
                            'id': id,
                            'name': name,
                            'icon': icon,
                            'color': color,
                            'kind': kind,
                          },
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),

          // URL-Quelle (Fallback für ältere Einträge ohne "Quelle"-Property)
          if (entry.sourceUrl != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                final uri = Uri.tryParse(entry.sourceUrl!);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                entry.sourceUrl!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Property-Zeile (read-only) ────────────────────────────────────────────────

class _PropertyRow extends StatelessWidget {
  final PropertyDefinition definition;
  final EntryProperty property;

  const _PropertyRow({required this.definition, required this.property});

  PropertyFieldType get _type {
    try {
      return PropertyFieldType.values.byName(definition.fieldType);
    } catch (_) {
      return PropertyFieldType.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              definition.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildValue(theme)),
        ],
      ),
    );
  }

  Widget _buildValue(ThemeData theme) {
    final raw = property.value;
    if (raw == null) return const SizedBox.shrink();

    switch (_type) {
      case PropertyFieldType.boolean:
        final val = raw == 'true';
        return Icon(
          val ? Icons.check_circle_outline : Icons.cancel_outlined,
          size: 20,
          color: val ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
        );

      case PropertyFieldType.rating:
        final stars = int.tryParse(raw) ?? 0;
        return Row(
          children: List.generate(
            5,
            (i) => Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 20,
              color: i < stars
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
        );

      case PropertyFieldType.tags:
        List<String> tags = [];
        try {
          tags = List<String>.from(jsonDecode(raw));
        } catch (_) {}
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: tags
              .map((t) => Chip(
                    label: Text(t),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ))
              .toList(),
        );

      case PropertyFieldType.multiselect:
        List<String> values = [];
        try {
          values = List<String>.from(jsonDecode(raw));
        } catch (_) {}
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: values
              .map((v) => Chip(
                    label: Text(v),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ))
              .toList(),
        );

      case PropertyFieldType.url:
        String urlDisplay = raw;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is String) urlDisplay = decoded;
        } catch (_) {}
        return GestureDetector(
          onTap: () async {
            final uri = Uri.tryParse(urlDisplay);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Text(
            urlDisplay,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
              decorationColor: theme.colorScheme.primary,
            ),
          ),
        );

      default:
        // text, number, date, link, select → einfach dekodieren
        String display = raw;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is String) display = decoded;
          if (decoded is num) display = decoded.toString();
        } catch (_) {}
        return SelectableText(
          display,
          style: theme.textTheme.bodyMedium,
        );
    }
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
    final videos =
        attachments.where((a) => a.mimeType.startsWith('video/')).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final video in videos) ...[
          const SizedBox(height: 12),
          _VideoPlayerWidget(attachment: video),
        ],
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

// ── Video-Player ──────────────────────────────────────────────────────────────

/// Eingebetteter Video-Player mit Play/Pause-Overlay (media_kit_video-basiert).
class _VideoPlayerWidget extends StatefulWidget {
  final Attachment attachment;

  const _VideoPlayerWidget({required this.attachment});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late final Player _player;
  late final VideoController _controller;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _loadVideo();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Video(
              controller: _controller,
              controls: AdaptiveVideoControls,
            ),
            if (!_isLoaded)
              Container(
                color: Colors.black54,
                child: const CircularProgressIndicator(color: Colors.white),
              ),
          ],
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
  String? _loadError;

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

      final file = File(path);
      if (!await file.exists()) {
        debugPrint('_AudioPlayerWidget: Datei nicht gefunden: $path');
        if (mounted) setState(() => _loadError = 'Datei nicht gefunden');
        return;
      }

      await _player.open(Media(Uri.file(path).toString()), play: false);
      if (mounted) setState(() => _isLoaded = true);
    } catch (e) {
      debugPrint('_AudioPlayerWidget: Ladefehler: $e');
      if (mounted) setState(() => _loadError = e.toString());
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

    // Ladefehler anzeigen statt leerem Player
    if (_loadError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _loadError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

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
                // Gespeicherte Dauer hat Priorität: korrigiert fehlerhafte
                // M4A-Header bei selbst aufgenommenen Dateien.
                final storedMs = widget.attachment.durationMs;
                final duration = (storedMs != null && storedMs > 0)
                    ? Duration(milliseconds: storedMs)
                    : _player.state.duration;
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
                        onChanged: _isLoaded && duration.inMilliseconds > 0
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
