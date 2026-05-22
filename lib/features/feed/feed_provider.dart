// Datei: lib/features/feed/feed_provider.dart
//
// ZWECK: Riverpod-Provider, der den reaktiven Eintrags-Stream für den Feed-Screen bereitstellt.
// ABHÄNGIGKEITEN: entryRepositoryProvider aus di.dart, Entry-Typ aus Drift.
// PHASE: 1 – Grundgerüst.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
// Entry ist eine von drift_dev generierte Datenklasse, zugänglich über database.dart.
import '../../data/db/database.dart';

/// Beobachtet alle Einträge als reaktiven Stream.
///
/// WARUM StreamProvider statt FutureProvider?
/// Drift's watch()-Methoden geben Streams zurück, die bei jeder DB-Änderung
/// automatisch einen neuen Wert emittieren. StreamProvider leitet das an
/// den Widget-Tree weiter – kein manuelles Refresh nötig.
///
/// WARUM kein @riverpod (Code-Gen)?
/// Code-Gen ist für diesen einfachen Fall unnötig. Der manuelle Provider
/// ist kürzer, lesbarer und spart einen build_runner-Durchlauf.
final feedEntriesProvider = StreamProvider<List<Entry>>((ref) {
  return ref.watch(entryRepositoryProvider).watchAllEntries();
}, name: 'feedEntriesProvider');
