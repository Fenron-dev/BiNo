// Datei: lib/features/hubs/hub_provider.dart
//
// ZWECK: Riverpod-Provider für Hub-Tabs (Liste + gefilterte Einträge).
// ABHÄNGIGKEITEN: containerDaoProvider, entryDaoProvider, activeWorkspaceProvider.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../data/db/database.dart';
import '../../domain/filters/filter_definition.dart';

/// Beobachtet alle nicht-archivierten Hub-Tabs sortiert nach sortOrder.
final hubTabsProvider = StreamProvider<List<Container>>((ref) {
  return ref.watch(containerDaoProvider).watchHubTabs();
}, name: 'hubTabsProvider');

/// Liefert die gefilterten Einträge für einen Hub-Tab (identifiziert per Container-ID).
///
/// Liest das filterJson aus dem Container, wandelt es in eine FilterDefinition
/// um und gibt den reaktiven Entry-Stream zurück.
final hubEntriesProvider =
    StreamProvider.family<List<Entry>, String>((ref, containerId) async* {
  final dao = ref.watch(containerDaoProvider);
  final container = await dao.getContainerById(containerId);
  if (container == null) {
    yield [];
    return;
  }

  final filter = container.filterJson != null
      ? FilterDefinition.fromJsonString(container.filterJson!)
      : const FilterDefinition();

  final workspaceId = ref.watch(activeWorkspaceProvider);

  yield* ref
      .watch(entryDaoProvider)
      .watchEntriesForFilter(filter, workspaceId);
}, name: 'hubEntriesProvider');
