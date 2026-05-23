// Datei: lib/features/containers/container_detail_screen.dart
//
// ZWECK: Zeigt alle einem Container (Projekt/Bereich) zugeordneten Einträge
//        als Mini-Feed. Erlaubt Bearbeiten und Archivieren des Containers.
// ABHÄNGIGKEITEN: containerDaoProvider, entryRepositoryProvider, EntryCard.
// PHASE: 4 – Projekte & Bereiche.

import 'package:flutter/material.dart' hide Container;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di.dart';
import '../../data/db/database.dart';
import '../feed/entry_card.dart';
import 'container_form_sheet.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

final _containerDetailProvider = StreamProvider.autoDispose
    .family<List<Entry>, String>((ref, containerId) {
  return ref
      .watch(containerDaoProvider)
      .watchEntriesForContainer(containerId);
});

// ── Screen ────────────────────────────────────────────────────────────────────

/// Detail-Ansicht eines Containers mit allen zugeordneten Einträgen.
class ContainerDetailScreen extends ConsumerWidget {
  final String containerId;
  final String containerName;
  final String containerIcon;
  final String containerColor;
  final String containerKind;

  const ContainerDetailScreen({
    super.key,
    required this.containerId,
    required this.containerName,
    required this.containerIcon,
    required this.containerColor,
    required this.containerKind,
  });

  Future<void> _editContainer(BuildContext context, WidgetRef ref) async {
    final dao = ref.read(containerDaoProvider);
    final existing = await dao.getContainerById(containerId);
    if (!context.mounted) return;
    final result = await showContainerFormSheet(context, existing: existing);
    if (result == null) return;
    await dao.updateContainer(
      id: containerId,
      name: result['name']!,
      description: result['description']!.isEmpty
          ? null
          : result['description'],
      icon: result['icon']!,
      color: result['color']!,
    );
  }

  Future<void> _archiveContainer(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Container archivieren?'),
        content: Text(
          '"$containerName" wird ausgeblendet. '
          'Zugeordnete Einträge bleiben erhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Archivieren'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(containerDaoProvider).archiveContainer(containerId);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(_containerDetailProvider(containerId));
    final color = hexToColor(containerColor);
    final icon = containerIconData(containerIcon);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: color),
        title: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                containerName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Bearbeiten',
            onPressed: () => _editContainer(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archivieren',
            onPressed: () => _archiveContainer(context, ref),
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Fehler beim Laden.')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 64, color: color.withAlpha(120)),
                  const SizedBox(height: 16),
                  Text(
                    'Noch keine Einträge in\n"$containerName"',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Öffne einen Eintrag und weise\nihn diesem Container zu.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // Neueste Einträge unten (WhatsApp-Stil) wie im Haupt-Feed.
          return ListView.builder(
            reverse: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              // reverse: true → letztes Element oben, erstes unten.
              final entry = entries[entries.length - 1 - index];
              return EntryCard(entry: entry, key: ValueKey(entry.id));
            },
          );
        },
      ),
    );
  }
}

// ── Container-Karte für die Listenansicht ─────────────────────────────────────

/// Karte für einen Container in der Projekteliste / Bereichsliste.
class ContainerCard extends ConsumerWidget {
  final Container container;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const ContainerCard({
    super.key,
    required this.container,
    required this.onTap,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = hexToColor(container.color);
    final icon = containerIconData(container.icon);

    final countAsync = ref.watch(
      _entryCountProvider(container.id),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Farbiges Icon
              CircleAvatar(
                backgroundColor: color.withAlpha(30),
                radius: 22,
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),

              // Name + Beschreibung
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      container.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (container.description != null &&
                        container.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        container.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Eintragsanzahl
              countAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (count) => Text(
                  '$count',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Kontextmenü
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'archive') onArchive();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                  PopupMenuItem(value: 'archive', child: Text('Archivieren')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Hilfs-Provider für die Eintragsanzahl-Badge auf der Karte.
final _entryCountProvider = StreamProvider.autoDispose
    .family<int, String>((ref, containerId) {
  return ref
      .watch(containerDaoProvider)
      .watchEntryCountForContainer(containerId);
});
