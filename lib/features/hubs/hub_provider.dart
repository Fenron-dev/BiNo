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
/// REAKTIVITÄT: Liest den Hub aus hubTabsProvider (reaktiver Stream) statt
/// per einmaligem getContainerById. Wenn filterJson in der DB geändert wird,
/// emittiert hubTabsProvider sofort einen neuen Wert → dieser Provider baut
/// watchEntriesForFilter mit dem neuen Filter neu auf.
final hubEntriesProvider =
    StreamProvider.family<List<Entry>, String>((ref, containerId) {
  // Reaktive Hub-Daten aus dem laufenden watchHubTabs()-Stream.
  final hubsAsync = ref.watch(hubTabsProvider);
  final hub = hubsAsync.value?.where((h) => h.id == containerId).firstOrNull;

  if (hub == null) return Stream.value(<Entry>[]);

  final filter = hub.filterJson != null
      ? FilterDefinition.fromJsonString(hub.filterJson!)
      : const FilterDefinition();

  final workspaceId = ref.watch(activeWorkspaceProvider);

  return ref
      .watch(entryDaoProvider)
      .watchEntriesForFilter(filter, workspaceId);
}, name: 'hubEntriesProvider');
