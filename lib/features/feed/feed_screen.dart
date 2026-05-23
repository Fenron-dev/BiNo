// Datei: lib/features/feed/feed_screen.dart
//
// ZWECK: Hauptansicht der App. Zeigt alle Einträge als chronologische Liste,
//        neueste Einträge unten (WhatsApp-Stil). Scrollt automatisch bei neuen Einträgen.
// ABHÄNGIGKEITEN: feedEntriesProvider, EntryCard.
// PHASE: 1 – Grundgerüst. Phase 2+ fügt Pull-to-Refresh, On-this-day-Karten,
//        Filter-Chips und Suchfeld hinzu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import 'feed_provider.dart';
import 'entry_card.dart';

/// Feed-Screen: chronologische Liste aller Einträge.
///
/// WARUM ConsumerStatefulWidget statt ConsumerWidget?
/// Wir benötigen einen ScrollController für Auto-Scroll und müssen den
/// vorherigen Eintragsstand (_previousEntryCount) zwischen Builds speichern.
/// StatefulWidget ist dafür die korrekte Wahl.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  int _previousEntryCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrollt zur untersten Position der Liste.
  ///
  /// WARUM Position 0 bei reverse:true?
  /// ListView(reverse: true) invertiert die Scroll-Achse: Position 0 ist das
  /// untere Ende der Liste (wo der neueste Eintrag erscheint).
  ///
  /// [animate] = false beim ersten Laden (kein sichtbares Ruckeln),
  /// true bei neuen Einträgen (sanfte Animation).
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
    final entriesAsync = ref.watch(feedEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(
          error: error,
          onRetry: () => ref.invalidate(feedEntriesProvider),
        ),
        data: (entries) {
          // Auto-Scroll zum neuesten Eintrag wenn die Anzahl zunimmt.
          // WidgetsBinding.addPostFrameCallback: stellt sicher dass die
          // Liste bereits gerendert ist, bevor der Scroll-Befehl ausgeführt wird.
          if (entries.length > _previousEntryCount && _previousEntryCount > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
          // Beim ersten Laden direkt ohne Animation ans Ende springen.
          if (_previousEntryCount == 0 && entries.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom(animate: false);
            });
          }
          _previousEntryCount = entries.length;

          if (entries.isEmpty) {
            return const _EmptyFeedPlaceholder();
          }

          return ListView.builder(
            controller: _scrollController,
            // reverse:true: Index 0 erscheint unten im Viewport.
            // Da Drift die Einträge aufsteigend (älteste zuerst) liefert,
            // erscheint der neueste Eintrag (letzter Index) ganz unten –
            // genau wie im WhatsApp-Chat.
            reverse: true,
            padding: const EdgeInsets.only(
              top: 8,
              // Abstand über der BottomAppBar, damit der unterste Eintrag
              // nicht hinter der Navigation verborgen liegt.
              bottom: 88,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              // reverse:true dreht die Indizes um: Index 0 = letzter Eintrag
              // der Liste (neuester). So zeigen wir ohne extra Sortierung
              // den neuesten Eintrag unten.
              final entry = entries[entries.length - 1 - index];
              return EntryCard(entry: entry, key: ValueKey(entry.id));
            },
          );
        },
      ),
    );
  }
}

/// Platzhalterverview für einen leeren Feed.
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

/// Fehlerview mit Retry-Option.
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
