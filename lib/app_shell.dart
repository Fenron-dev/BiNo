// Datei: lib/app_shell.dart
//
// ZWECK: Persistente App-Hülle mit BottomAppBar (Navigation) und zentralem FAB.
//        Hub-Tabs werden über einen einzigen „Hubs"-Button geöffnet (verhindert
//        Overflow), der ein Auswahl-Sheet mit allen Hubs zeigt.
//        Aktiver Hub-Inhalt wird via lokalem _activeHubId-State in der Shell
//        gerendert (kein go_router-Branch-Wechsel nötig).
// ABHÄNGIGKEITEN: go_router (StatefulNavigationShell), CaptureSheet,
//                 AudioCaptureSheet, hubTabsProvider, HubScreen, HubFormSheet.

import 'package:flutter/material.dart' hide Container;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:drift/drift.dart' show Value;

import 'core/di.dart';
import 'data/db/database.dart';
import 'features/capture/capture_sheet.dart';
import 'features/capture/audio_capture_sheet.dart';
import 'features/containers/container_form_sheet.dart';
import 'domain/filters/filter_definition.dart';
import 'features/hubs/hub_provider.dart';
import 'features/hubs/hub_screen.dart';
import 'features/hubs/hub_form_sheet.dart';

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// ID des aktiven Hub-Tabs. Null = Standard-Tab ist aktiv.
  String? _activeHubId;

  void _onStandardTabTapped(int index) {
    setState(() => _activeHubId = null);
    widget.navigationShell.goBranch(
      index,
      initialLocation:
          index == widget.navigationShell.currentIndex && _activeHubId == null,
    );
  }

  void _openCaptureSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const CaptureSheet(),
    );
  }

  void _openAudioCaptureSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const AudioCaptureSheet(),
    );
  }

  Future<void> _onFabPressed() async {
    if (_activeHubId != null) {
      _openCaptureSheet();
      return;
    }
    switch (widget.navigationShell.currentIndex) {
      case 0:
        _openCaptureSheet();
      case 1:
        await _createContainer('project');
      case 2:
        await _createContainer('area');
    }
  }

  Future<void> _createContainer(String kind) async {
    final result = await showContainerFormSheet(context);
    if (result == null) return;
    await ref.read(containerDaoProvider).insertContainer(
          ContainersCompanion.insert(
            id: const Uuid().v4(),
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

  /// Öffnet das Hub-Auswahl-Sheet (oder direkt das Erstell-Formular wenn leer).
  void _openHubSelector(List<Container> hubs) {
    if (hubs.isEmpty) {
      showHubFormSheet(context);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _HubSelectorSheet(
        hubs: hubs,
        activeHubId: _activeHubId,
        onHubSelected: (id) {
          Navigator.of(context).pop();
          setState(() => _activeHubId = id);
        },
        onCreateNew: () {
          Navigator.of(context).pop();
          showHubFormSheet(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hubs = ref.watch(hubTabsProvider).value ?? [];
    final isOnFeedOrHub =
        _activeHubId != null || widget.navigationShell.currentIndex == 0;

    return Scaffold(
      extendBody: true,
      body: _activeHubId != null
          ? HubScreen(key: ValueKey(_activeHubId), hubId: _activeHubId!)
          : widget.navigationShell,

      floatingActionButton: GestureDetector(
        onLongPress: isOnFeedOrHub ? _openAudioCaptureSheet : null,
        child: FloatingActionButton(
          onPressed: _onFabPressed,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // ── Linke Seite ───────────────────────────────────────────────
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Feed',
              isActive: _activeHubId == null &&
                  widget.navigationShell.currentIndex == 0,
              onTap: () => _onStandardTabTapped(0),
            ),
            _NavItem(
              icon: Icons.folder_outlined,
              activeIcon: Icons.folder,
              label: 'Projekte',
              isActive: _activeHubId == null &&
                  widget.navigationShell.currentIndex == 1,
              onTap: () => _onStandardTabTapped(1),
            ),

            // ── FAB-Freiraum ──────────────────────────────────────────────
            const SizedBox(width: 56),

            // ── Rechte Seite ──────────────────────────────────────────────
            _NavItem(
              icon: Icons.grid_view_outlined,
              activeIcon: Icons.grid_view,
              label: 'Bereiche',
              isActive: _activeHubId == null &&
                  widget.navigationShell.currentIndex == 2,
              onTap: () => _onStandardTabTapped(2),
            ),

            // Einzelner Hubs-Button – öffnet Auswahl-Sheet
            _NavItem(
              icon: Icons.bookmarks_outlined,
              activeIcon: Icons.bookmarks,
              label: 'Hubs',
              isActive: _activeHubId != null,
              badge: hubs.isNotEmpty ? hubs.length : null,
              onTap: () => _openHubSelector(hubs),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hub-Auswahl-Sheet ─────────────────────────────────────────────────────────

class _HubSelectorSheet extends StatelessWidget {
  final List<Container> hubs;
  final String? activeHubId;
  final ValueChanged<String> onHubSelected;
  final VoidCallback onCreateNew;

  const _HubSelectorSheet({
    required this.hubs,
    required this.activeHubId,
    required this.onHubSelected,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const SizedBox(width: 36, height: 4),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                Text(
                  'Hubs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          ...hubs.map(
            (hub) {
              final isActive = hub.id == activeHubId;
              Color hubColor;
              try {
                hubColor = Color(
                  int.parse(
                    'FF${hub.color.replaceFirst('#', '')}',
                    radix: 16,
                  ),
                );
              } catch (_) {
                hubColor = colorScheme.primary;
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: hubColor.withValues(alpha: 0.18),
                  child: Icon(_hubIconData(hub.icon), color: hubColor, size: 20),
                ),
                title: Text(hub.name),
                subtitle: hub.filterJson != null
                    ? Text(
                        _filterSummary(hub.filterJson!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: isActive
                    ? Icon(Icons.check_circle, color: colorScheme.primary)
                    : null,
                selected: isActive,
                onTap: () => onHubSelected(hub.id),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Neuen Hub erstellen'),
            onTap: onCreateNew,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _filterSummary(String filterJson) {
    try {
      final f = FilterDefinition.fromJsonString(filterJson);
      final parts = <String>[];
      if (f.tagsAny.isNotEmpty) parts.add('#${f.tagsAny.join(', #')}');
      if (f.typeIn.isNotEmpty) parts.add(f.typeIn.join(', '));
      if (f.statusIn.isNotEmpty) parts.add(f.statusIn.join(', '));
      return parts.isEmpty ? 'Kein Filter' : parts.join(' · ');
    } catch (_) {
      return '';
    }
  }
}

// ── Nav-Item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color =
        isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge != null
                ? Badge(
                    label: Text('$badge'),
                    child: Icon(isActive ? activeIcon : icon, color: color),
                  )
                : Icon(isActive ? activeIcon : icon, color: color),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hilfsfunktion: Icon-Name → IconData ──────────────────────────────────────

IconData _hubIconData(String name) => kHubIconMap[name] ?? Icons.bookmarks_outlined;
