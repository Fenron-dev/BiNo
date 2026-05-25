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

import 'package:intl/intl.dart';

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
  String? _activeFilter;
  bool _dismissedOnThisDay = false;
  bool _dismissedRandomCard = false;

  static const _kFilters = <(String, String, IconData)>[
    ('text', 'Text', Icons.text_fields_outlined),
    ('link', 'Link', Icons.link_outlined),
    ('image', 'Bild', Icons.image_outlined),
    ('audio', 'Audio', Icons.mic_none_outlined),
    ('pinned', 'Angepinnt', Icons.push_pin_outlined),
  ];

  List<Entry> _applyFilter(List<Entry> all) {
    if (_activeFilter == null) return all;
    if (_activeFilter == 'pinned') return all.where((e) => e.pinned).toList();
    return all.where((e) => e.type == _activeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(feedEntriesProvider);

    return Column(
      children: [
        // Zufälliger Eintrag (erscheint einmalig pro Session, schließbar)
        if (!_dismissedRandomCard)
          _RandomCardBanner(
            onDismiss: () => setState(() => _dismissedRandomCard = true),
          ),

        // „Heute vor …"-Banner (erscheint einmalig pro Session, schließbar)
        if (!_dismissedOnThisDay)
          _OnThisDayBanner(
            onDismiss: () => setState(() => _dismissedOnThisDay = true),
          ),

        // Filter-Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('Alle'),
                  selected: _activeFilter == null,
                  onSelected: (_) => setState(() => _activeFilter = null),
                ),
              ),
              ..._kFilters.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(f.$3, size: 16),
                    label: Text(f.$2),
                    selected: _activeFilter == f.$1,
                    onSelected: (v) =>
                        setState(() => _activeFilter = v ? f.$1 : null),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Eintrags-Liste
        Expanded(
          child: entriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _ErrorView(
              error: error,
              onRetry: () => ref.invalidate(feedEntriesProvider),
            ),
            data: (allEntries) {
              // Auto-Scroll anhand ungefilterer Gesamtanzahl (verhindert
              // falschen Scroll-Trigger beim Filterwechsel).
              if (allEntries.length > widget.previousEntryCount &&
                  widget.previousEntryCount > 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onScrollToBottom();
                });
              }
              if (widget.previousEntryCount == 0 && allEntries.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onScrollToBottom(animate: false);
                });
              }
              widget.onCountUpdate(allEntries.length);

              final entries = _applyFilter(allEntries);

              if (entries.isEmpty) {
                if (_activeFilter != null) {
                  return const Center(
                    child: Text('Keine Einträge für diesen Filter.'),
                  );
                }
                return const _EmptyFeedPlaceholder();
              }

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
          ),
        ),
      ],
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

// ── Zufälliger Eintrag ────────────────────────────────────────────────────────

class _RandomCardBanner extends ConsumerWidget {
  final VoidCallback onDismiss;

  const _RandomCardBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(randomEntryProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (entry) {
        if (entry == null) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final preview = (entry.title?.isNotEmpty == true
                ? entry.title!
                : entry.body)
            .substring(
              0,
              (entry.title?.isNotEmpty == true ? entry.title! : entry.body)
                  .length
                  .clamp(0, 120),
            );

        return InkWell(
          onTap: () => context.push(AppRoutes.entryDetail(entry.id)),
          child: ColoredBox(
            color: theme.colorScheme.tertiaryContainer.withAlpha(80),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shuffle_outlined,
                    size: 16,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zufälliger Eintrag',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preview,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    visualDensity: VisualDensity.compact,
                    color: theme.colorScheme.onSurfaceVariant,
                    onPressed: onDismiss,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Heute vor … ──────────────────────────────────────────────────────────────

class _OnThisDayBanner extends ConsumerWidget {
  final VoidCallback onDismiss;

  const _OnThisDayBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(onThisDayProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data.isEmpty) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final fmt = DateFormat('dd. MMMM yyyy', 'de_DE');

        return ColoredBox(
          color: theme.colorScheme.secondaryContainer.withAlpha(80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
                child: Row(
                  children: [
                    Icon(Icons.history_outlined,
                        size: 16, color: theme.colorScheme.secondary),
                    const SizedBox(width: 6),
                    Text(
                      'Heute vor …',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      visualDensity: VisualDensity.compact,
                      color: theme.colorScheme.onSurfaceVariant,
                      onPressed: onDismiss,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: data.fold(0, (sum, g) => sum + g.entries.length),
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    // Flache Liste: alle Einträge aller Jahre nacheinander
                    int flat = index;
                    for (final group in data) {
                      if (flat < group.entries.length) {
                        final entry = group.entries[flat];
                        final yearsAgo = group.yearsAgo;
                        final dateLabel =
                            fmt.format(entry.createdAt.toLocal());
                        final preview = (entry.title?.isNotEmpty == true
                                ? entry.title!
                                : entry.body)
                            .substring(
                                0,
                                (entry.title?.isNotEmpty == true
                                            ? entry.title!
                                            : entry.body)
                                        .length
                                        .clamp(0, 80));
                        return _OnThisDayCard(
                          yearsAgo: yearsAgo,
                          dateLabel: dateLabel,
                          preview: preview,
                          onTap: () =>
                              context.push(AppRoutes.entryDetail(entry.id)),
                        );
                      }
                      flat -= group.entries.length;
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OnThisDayCard extends StatelessWidget {
  final int yearsAgo;
  final String dateLabel;
  final String preview;
  final VoidCallback onTap;

  const _OnThisDayCard({
    required this.yearsAgo,
    required this.dateLabel,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label =
        yearsAgo == 1 ? 'Vor einem Jahr' : 'Vor $yearsAgo Jahren';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 200,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    preview,
                    style: theme.textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
