// Datei: lib/features/feed/feed_provider.dart
//
// ZWECK: Riverpod-Provider, der den reaktiven Eintrags-Stream für den Feed-Screen bereitstellt.
// ABHÄNGIGKEITEN: entryRepositoryProvider aus di.dart, Entry-Typ aus Drift.
// PHASE: 1 – Grundgerüst.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
// Entry ist eine von drift_dev generierte Datenklasse, zugänglich über database.dart.
import '../../data/db/database.dart';

/// Beobachtet alle Einträge des aktiven Workspace als reaktiven Stream.
final feedEntriesProvider = StreamProvider<List<Entry>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceProvider);
  return ref.watch(entryRepositoryProvider).watchAllEntries(workspaceId);
}, name: 'feedEntriesProvider');

// ── Suche ─────────────────────────────────────────────────────────────────

/// Hält den aktuellen Suchbegriff des Nutzers.
final searchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
  name: 'searchQueryProvider',
);

/// Liefert Suchergebnisse via FTS5 für den aktuellen Suchbegriff.
///
/// WARUM FutureProvider statt StreamProvider?
/// FTS5-Suche ist eine einmalige Abfrage (kein reaktiver Stream).
/// FutureProvider.family wird durch Riverpod automatisch neu ausgeführt,
/// sobald sich [query] ändert – das gibt uns Reaktivität ohne Stream.
final searchResultsProvider = FutureProvider.autoDispose
    .family<List<Entry>, String>((ref, query) {
  return ref.read(entryRepositoryProvider).searchEntries(query);
}, name: 'searchResultsProvider');

// ── Heute vor … ───────────────────────────────────────────────────────────

/// Einträge vom selben Kalender-Tag in vergangenen Jahren (max. 5 Jahre zurück).
/// Typ: Liste aus (Jahre-zurück, Einträge-dieses-Tages).
typedef OnThisDayData = List<({int yearsAgo, List<Entry> entries})>;

final onThisDayProvider = FutureProvider<OnThisDayData>((ref) async {
  final dao = ref.read(entryDaoProvider);
  final today = DateTime.now();
  final result = <({int yearsAgo, List<Entry> entries})>[];

  for (var years = 1; years <= 5; years++) {
    try {
      final date = DateTime(today.year - years, today.month, today.day);
      final start = date.toUtc();
      final end = start.add(const Duration(days: 1));
      final list = await dao.getEntriesForDateRange(start, end);
      if (list.isNotEmpty) result.add((yearsAgo: years, entries: list));
    } catch (_) {
      // Ungültige Daten (z. B. 29. Feb in einem Nicht-Schaltjahr) überspringen.
    }
  }
  return result;
}, name: 'onThisDayProvider');
