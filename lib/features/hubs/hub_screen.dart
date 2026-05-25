// Datei: lib/features/hubs/hub_screen.dart
//
// ZWECK: Zeigt alle Einträge eines Hub-Tabs als gefilterte Liste.
//        Layout analog zum FeedScreen, aber mit Hub-spezifischem Header
//        und Navigation über die Top-Level-Route /entry/:id.
// ABHÄNGIGKEITEN: hubEntriesProvider, EntryCard, HubFormSheet.

import 'package:flutter/material.dart' hide Container;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/db/database.dart';
import '../feed/entry_card.dart';
import 'hub_form_sheet.dart';
import 'hub_provider.dart';

/// Zeigt die gefilterten Einträge eines Hub-Tabs.
class HubScreen extends ConsumerStatefulWidget {
  final String hubId;

  const HubScreen({super.key, required this.hubId});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openEditSheet(
    BuildContext context,
    Container hub,
  ) async {
    await showHubFormSheet(context, existing: hub);
  }

  @override
  Widget build(BuildContext context) {
    final hubs = ref.watch(hubTabsProvider).value ?? [];
    final hub = hubs.where((h) => h.id == widget.hubId).firstOrNull;
    final entriesAsync = ref.watch(hubEntriesProvider(widget.hubId));

    final colorScheme = Theme.of(context).colorScheme;
    final hubColor = hub != null
        ? _hexToColor(hub.color, colorScheme.primary)
        : colorScheme.primary;
    final hubIcon = hub != null ? _iconData(hub.icon) : Icons.bookmarks;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(hubIcon, size: 20, color: hubColor),
            const SizedBox(width: 8),
            Text(hub?.name ?? 'Hub'),
          ],
        ),
        actions: [
          if (hub != null)
            IconButton(
              icon: const Icon(Icons.tune_outlined),
              tooltip: 'Hub bearbeiten',
              onPressed: () => _openEditSheet(context, hub),
            ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Fehler beim Laden der Einträge.')),
        data: (entries) {
          if (entries.isEmpty) {
            return _EmptyState(hub: hub);
          }
          return ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
            itemCount: entries.length,
            itemBuilder: (_, i) => EntryCard(
              entry: entries[i],
              detailRoute: AppRoutes.hubEntryDetail(entries[i].id),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Container? hub;

  const _EmptyState({this.hub});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_off, size: 48, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'Keine Einträge',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            hub?.filterJson != null
                ? 'Kein Eintrag entspricht dem aktuellen Filter.'
                : 'Erstelle Einträge und passe den Filter an.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Hilfsfunktionen ──────────────────────────────────────────────────────────

Color _hexToColor(String hex, Color fallback) {
  try {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  } catch (_) {
    return fallback;
  }
}

IconData _iconData(String name) {
  return _kIconMap[name] ?? Icons.bookmarks_outlined;
}

const _kIconMap = <String, IconData>{
  'bookmark': Icons.bookmark,
  'bookmarks': Icons.bookmarks,
  'menu_book': Icons.menu_book,
  'label': Icons.label,
  'star': Icons.star,
  'favorite': Icons.favorite,
  'link': Icons.link,
  'image': Icons.image,
  'mic': Icons.mic,
  'note': Icons.note,
  'task': Icons.task_alt,
  'inbox': Icons.inbox,
  'archive': Icons.archive,
  'folder': Icons.folder,
  'work': Icons.work,
  'home': Icons.home,
  'school': Icons.school,
  'fitness': Icons.fitness_center,
  'music': Icons.music_note,
  'movie': Icons.movie,
  'shopping': Icons.shopping_bag,
  'code': Icons.code,
  'travel': Icons.flight,
  'food': Icons.restaurant,
  'health': Icons.health_and_safety,
  'idea': Icons.lightbulb,
  'todo': Icons.checklist,
};
