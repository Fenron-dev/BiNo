// Datei: lib/features/containers/container_list_screen.dart
//
// ZWECK: Gemeinsamer Listen-Screen für Projekte (kind='project') und
//        Bereiche (kind='area'). Wird von ProjectsScreen und AreasScreen
//        per kind-Parameter konfiguriert.
// ABHÄNGIGKEITEN: containerDaoProvider, ContainerCard, ContainerFormSheet.
// PHASE: 4 – Projekte & Bereiche.

import 'package:flutter/material.dart' hide Container;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/constants.dart';
import '../../core/di.dart';
import '../../data/db/database.dart';
import 'container_detail_screen.dart';
import 'container_form_sheet.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

/// Beobachtet alle aktiven Container eines bestimmten Typs.
final containersByKindProvider = StreamProvider.autoDispose
    .family<List<Container>, String>((ref, kind) {
  return ref.watch(containerDaoProvider).watchContainersByKind(kind);
});

// ── Screen ────────────────────────────────────────────────────────────────────

/// Listen-Screen für Projekte oder Bereiche (über [kind] gesteuert).
class ContainerListScreen extends ConsumerWidget {
  final String kind;

  const ContainerListScreen({super.key, required this.kind});

  String get _title => kind == 'project' ? 'Projekte' : 'Bereiche';

  String get _emptyLabel =>
      kind == 'project' ? 'Noch keine Projekte' : 'Noch keine Bereiche';

  String get _emptyHint => kind == 'project'
      ? 'Erstelle dein erstes Projekt mit "+".'
      : 'Erstelle deinen ersten Bereich mit "+".';

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showContainerFormSheet(context);
    if (result == null) return;
    const uuid = Uuid();
    await ref.read(containerDaoProvider).insertContainer(
          ContainersCompanion.insert(
            id: uuid.v4(),
            kind: kind,
            name: result['name']!,
            description: Value(
              result['description']!.isEmpty ? null : result['description'],
            ),
            icon: Value(result['icon']!),
            color: Value(result['color']!),
          ),
        );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Container container,
  ) async {
    final result = await showContainerFormSheet(context, existing: container);
    if (result == null) return;
    await ref.read(containerDaoProvider).updateContainer(
          id: container.id,
          name: result['name']!,
          description:
              result['description']!.isEmpty ? null : result['description'],
          icon: result['icon']!,
          color: result['color']!,
        );
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    Container container,
  ) async {
    final label = kind == 'project' ? 'Projekt' : 'Bereich';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label archivieren?'),
        content: Text(
          '"${container.name}" wird ausgeblendet. '
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
    await ref.read(containerDaoProvider).archiveContainer(container.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containersAsync = ref.watch(containersByKindProvider(kind));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_$kind',
        onPressed: () => _create(context, ref),
        tooltip: '$_title erstellen',
        child: const Icon(Icons.add),
      ),
      body: containersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Fehler beim Laden.')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    kind == 'project'
                        ? Icons.folder_outlined
                        : Icons.grid_view_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(_emptyLabel, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    _emptyHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final container = items[index];
              return ContainerCard(
                key: ValueKey(container.id),
                container: container,
                onTap: () => context.push(
                  AppRoutes.containerDetail(container.id),
                  extra: {
                    'id': container.id,
                    'name': container.name,
                    'icon': container.icon,
                    'color': container.color,
                    'kind': container.kind,
                  },
                ),
                onEdit: () => _edit(context, ref, container),
                onArchive: () => _archive(context, ref, container),
              );
            },
          );
        },
      ),
    );
  }
}
