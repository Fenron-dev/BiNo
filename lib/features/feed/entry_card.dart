// Datei: lib/features/feed/entry_card.dart
//
// ZWECK: Einzelne Eintragskarte im Feed. Zeigt Body-Vorschau, Zeitstempel,
//        Bild-Thumbnails und Audio-Chip für Einträge mit Anhängen.
// ABHÄNGIGKEITEN: Entry + Attachment aus Drift, attachmentRepositoryProvider, intl.
// MUSTER: ConsumerWidget – beobachtet Anhänge als Stream.
// PHASE: 2 – Bild-Thumbnails, Audio-Chip, Link-Domain-Badge.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/di.dart';
// 'Container' aus database.dart ausblenden – kollidiert mit Flutter's Container-Widget.
import '../../data/db/database.dart' hide Container;

/// Karte für einen einzelnen Eintrag im Feed.
class EntryCard extends ConsumerWidget {
  final Entry entry;

  /// Optionale Route für den Detail-Screen. Standardmäßig /feed/detail/:id.
  /// Hub-Tabs übergeben /entry/:id für die Top-Level-Route (ohne Shell).
  final String? detailRoute;

  const EntryCard({super.key, required this.entry, this.detailRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Anhänge als reaktiven Stream beobachten.
    final attachmentsAsync = ref.watch(
      _attachmentsProvider(entry.id),
    );

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: () => context.push(detailRoute ?? AppRoutes.entryDetail(entry.id)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Optionaler Titel.
              if (entry.title != null && entry.title!.isNotEmpty) ...[
                Text(
                  entry.title!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],

              // Body – nicht anzeigen wenn der Eintrag nur Bilder enthält.
              if (entry.body.isNotEmpty)
                Text(
                  entry.body,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),

              // Anhang-Vorschau: Bild-Streifen oder Audio-Chip.
              attachmentsAsync.when(
                data: (attachments) => _AttachmentPreview(
                  attachments: attachments,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 8),

              // Metadaten-Zeile: Link-Domain, Zeitstempel, Pin.
              Row(
                children: [
                  if (entry.sourceUrl != null)
                    _DomainBadge(url: entry.sourceUrl!),
                  Text(
                    _formatTimestamp(entry.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (entry.pinned)
                    Icon(Icons.push_pin, size: 14, color: colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime utcTime) {
    final local = utcTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(entryDay).inDays;

    if (diffDays == 0) {
      return DateFormat.Hm('de_DE').format(local);
    } else if (diffDays < 7) {
      return DateFormat('E., HH:mm', 'de_DE').format(local);
    } else {
      return DateFormat('dd.MM.yyyy', 'de_DE').format(local);
    }
  }
}

// ── Hilfsprovider ──────────────────────────────────────────────────────────────

/// Beobachtet Anhänge eines Eintrags als Stream.
final _attachmentsProvider = StreamProvider.autoDispose
    .family<List<Attachment>, String>((ref, entryId) {
  return ref.watch(attachmentRepositoryProvider).watchForEntry(entryId);
});

// ── Hilfswidgets ───────────────────────────────────────────────────────────────

/// Zeigt Bild-Thumbnails oder einen Audio-Chip abhängig von den Anhängen.
class _AttachmentPreview extends StatelessWidget {
  final List<Attachment> attachments;

  const _AttachmentPreview({required this.attachments});

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final images = attachments
        .where((a) => a.mimeType.startsWith('image/'))
        .toList();
    final audios = attachments
        .where((a) => a.mimeType.startsWith('audio/'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ImageThumbnailRow(images: images),
        ],
        if (audios.isNotEmpty) ...[
          const SizedBox(height: 6),
          _AudioChip(attachment: audios.first),
        ],
      ],
    );
  }
}

/// Horizontale Reihe mit Bild-Thumbnails (max. 4 angezeigt).
///
/// WARUM FutureBuilder für den Basispfad?
/// AttachmentService.absolutePath() ist async (braucht getApplicationDocumentsDirectory).
/// Ein einzelner FutureBuilder für den Basispfad ist effizienter als
/// ein FutureBuilder pro Bild.
class _ImageThumbnailRow extends StatelessWidget {
  final List<Attachment> images;

  const _ImageThumbnailRow({required this.images});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Directory>(
      future: getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 64);
        }
        final basePath = p.join(snapshot.data!.path, 'attachments');

        const maxVisible = 4;
        final visible = images.take(maxVisible).toList();
        final overflow = images.length - maxVisible;

        return SizedBox(
          height: 64,
          child: Row(
            children: [
              for (int i = 0; i < visible.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(p.join(basePath, visible[i].filePath)),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(context),
                      ),
                    ),
                    // "+N"-Badge für Überschuss-Bilder.
                    if (i == maxVisible - 1 && overflow > 0)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: ColoredBox(
                            color: Colors.black54,
                            child: Center(
                              child: Text(
                                '+$overflow',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _placeholder(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

/// Audio-Chip mit Mikrofon-Icon und optionaler Dauer.
class _AudioChip extends StatelessWidget {
  final Attachment attachment;

  const _AudioChip({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = attachment.durationMs != null
        ? _formatDuration(attachment.durationMs!)
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic,
              size: 16,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              duration ?? 'Audioaufnahme',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int ms) {
    final total = ms ~/ 1000;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Kleine Domain-Kennzeichnung für Link-Einträge (z. B. "youtube.com").
class _DomainBadge extends StatelessWidget {
  final String url;

  const _DomainBadge({required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String domain;
    try {
      domain = Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text(
        domain,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
