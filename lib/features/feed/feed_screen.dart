// Datei: lib/features/feed/feed_screen.dart
//
// ZWECK: Hauptansicht der App. Zeigt alle Einträge als chronologische Liste,
//        neueste Einträge unten (WhatsApp-Stil). Scrollt automatisch bei neuen Einträgen.
//        Phase 3: Volltext-Suche via FTS5, Swipe-to-Delete.
// ABHÄNGIGKEITEN: feedEntriesProvider, searchResultsProvider, EntryCard.
// PHASE: 1 – Grundgerüst. Phase 3: Suche + Löschen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/di.dart';
import '../../data/db/database.dart' hide Container;
import 'feed_provider.dart';
import 'entry_card.dart';

/// Feed-Screen: chronologische Liste aller Einträge.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _previousEntryCount = 0;
  bool _isSearching = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _isSearching = true);
  }

  void _closeSearch() {
    setState(() => _isSearching = false);
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    if (animate) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        // Im Such-Modus: TextField statt Titel.
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Suchen…',
                  border: InputBorder.none,
                ),
                onChanged: (q) =>
                    ref.read(searchQueryProvider.notifier).state = q,
              )
            : const Text('Feed'),
        actions: _isSearching
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Suche schließen',
                  onPressed: _closeSearch,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Suchen',
                  onPressed: _openSearch,
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Einstellungen',
                  onPressed: () => context.push(AppRoutes.settings),
                ),
              ],
      ),
      body: _isSearching
          ? _SearchResultsView(query: searchQuery)
          : _FeedView(
              scrollController: _scrollController,
              previousEntryCount: _previousEntryCount,
              onCountUpdate: (count) => _previousEntryCount = count,
              onScrollToBottom: _scrollToBottom,
            ),
    );
  }
}

// ── Such-Ergebnisse ───────────────────────────────────────────────────────────

class _SearchResultsView extends ConsumerWidget {
  final String query;

  const _SearchResultsView({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text('Suchbegriff eingeben…'),
      );
    }

    final resultsAsync = ref.watch(searchResultsProvider(query));

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const Center(child: Text('Fehler bei der Suche.')),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Text('Keine Ergebnisse für „$query"'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: entries.length,
          itemBuilder: (context, index) =>
              EntryCard(entry: entries[index], key: ValueKey(entries[index].id)),
        );
      },
    );
  }
}

// ── Normaler Feed ─────────────────────────────────────────────────────────────

class _FeedView extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final int previousEntryCount;
  final void Function(int count) onCountUpdate;
  final void Function({bool animate}) onScrollToBottom;

  const _FeedView({
    required this.scrollController,
    required this.previousEntryCount,
    required this.onCountUpdate,
    required this.onScrollToBottom,
  });

  @override
  ConsumerState<_FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends ConsumerState<_FeedView> {
  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(feedEntriesProvider);

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorView(
        error: error,
        onRetry: () => ref.invalidate(feedEntriesProvider),
      ),
      data: (entries) {
        if (entries.length > widget.previousEntryCount &&
            widget.previousEntryCount > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onScrollToBottom();
          });
        }
        if (widget.previousEntryCount == 0 && entries.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onScrollToBottom(animate: false);
          });
        }
        widget.onCountUpdate(entries.length);

        if (entries.isEmpty) return const _EmptyFeedPlaceholder();

        return ListView.builder(
          controller: widget.scrollController,
          reverse: true,
          padding: const EdgeInsets.only(top: 8, bottom: 88),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[entries.length - 1 - index];
            return _SwipableEntryCard(
              key: ValueKey(entry.id),
              entry: entry,
            );
          },
        );
      },
    );
  }
}

/// EntryCard mit Swipe-to-Delete (Wischen nach links).
class _SwipableEntryCard extends ConsumerWidget {
  final Entry entry;

  const _SwipableEntryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey('dismissible_${entry.id}'),
      direction: DismissDirection.endToStart,
      // Roter Hintergrund mit Papierkorb-Icon beim Wischen.
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      // Bestätigung vor dem endgültigen Löschen.
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
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
      },
      onDismissed: (_) {
        ref.read(entryRepositoryProvider).deleteEntry(entry.id);
      },
      child: EntryCard(entry: entry),
    );
  }
}

// ── Platzhalter & Fehlerview ──────────────────────────────────────────────────

class _EmptyFeedPlaceholder extends StatelessWidget {
  const _EmptyFeedPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Noch keine Notizen.\nTipp auf + um loszulegen.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 8),
            Text(
              'Fehler beim Laden der Einträge:\n$error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}
