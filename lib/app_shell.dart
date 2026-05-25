// Datei: lib/app_shell.dart
//
// ZWECK: Persistente App-Hülle mit BottomAppBar (Navigation) und zentralem FAB.
//        Zeigt Hub-Tabs als zusätzliche Nav-Items rechts neben Bereiche.
//        Wenn ein Hub aktiv ist, wird HubScreen statt des NavigationShell-Inhalts
//        gerendert (lokaler State-Swap ohne go_router-Branch-Wechsel).
// ABHÄNGIGKEITEN: go_router (StatefulNavigationShell), CaptureSheet,
//                 AudioCaptureSheet, hubTabsProvider, HubScreen.

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
import 'features/hubs/hub_provider.dart';
import 'features/hubs/hub_screen.dart';

/// App-Hülle mit persistenter Bottom-Navigation, FAB und dynamischen Hub-Tabs.
///
/// Hub-Tab-Navigation nutzt lokalen State (_activeHubId) statt go_router-Branches,
/// da StatefulShellRoute statische Branches erfordert.
/// Wenn _activeHubId gesetzt ist, rendert body den HubScreen direkt.
/// Top-Level-Routen (entry-Detail, Settings) liegen über der Shell und
/// funktionieren unabhängig davon, ob ein Hub oder ein Standard-Tab aktiv ist.
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
      initialLocation: index == widget.navigationShell.currentIndex && _activeHubId == null,
    );
  }

  void _onHubTabTapped(String hubId) {
    setState(() => _activeHubId = hubId);
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

  @override
  Widget build(BuildContext context) {
    final hubs = ref.watch(hubTabsProvider).value ?? [];
    final isOnFeedOrHub =
        _activeHubId != null || widget.navigationShell.currentIndex == 0;

    // Hub-Tabs passen nur 2 Slots rechts neben Bereiche (insgesamt max 4 rechts vom FAB).
    // Wenn mehr als 1 Hub existiert, wird der letzte Slot durch "Mehr"-Button ersetzt.
    final visibleHubs = hubs.length <= 2 ? hubs : hubs.take(1).toList();
    final hasOverflow = hubs.length > 2;

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

            // Sichtbare Hub-Tabs (max 1–2)
            for (final hub in visibleHubs)
              _HubNavItem(
                hub: hub,
                isActive: _activeHubId == hub.id,
                onTap: () => _onHubTabTapped(hub.id),
              ),

            // Overflow-Button wenn > 2 Hubs
            if (hasOverflow)
              _MoreHubsButton(
                hubs: hubs,
                activeHubId: _activeHubId,
                onHubSelected: _onHubTabTapped,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Standard-Nav-Item ──────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hub-Nav-Item ───────────────────────────────────────────────────────────────

class _HubNavItem extends StatelessWidget {
  final Container hub;
  final bool isActive;
  final VoidCallback onTap;

  const _HubNavItem({
    required this.hub,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color hubColor;
    try {
      hubColor = Color(
        int.parse('FF${hub.color.replaceFirst('#', '')}', radix: 16),
      );
    } catch (_) {
      hubColor = colorScheme.primary;
    }

    final iconData = _hubIconData(hub.icon);
    final activeColor = isActive ? hubColor : colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, color: activeColor),
            Text(
              hub.name,
              style: TextStyle(fontSize: 11, color: activeColor),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overflow-Button für > 2 Hub-Tabs ─────────────────────────────────────────

class _MoreHubsButton extends StatelessWidget {
  final List<Container> hubs;
  final String? activeHubId;
  final ValueChanged<String> onHubSelected;

  const _MoreHubsButton({
    required this.hubs,
    required this.activeHubId,
    required this.onHubSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasActiveOverflow =
        activeHubId != null && hubs.skip(1).any((h) => h.id == activeHubId);

    return Expanded(
      child: InkWell(
        onTap: () => _showOverflowSheet(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.more_horiz,
              color: hasActiveOverflow
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            Text(
              'Mehr',
              style: TextStyle(
                fontSize: 11,
                color: hasActiveOverflow
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOverflowSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _HubOverflowSheet(
        hubs: hubs,
        activeHubId: activeHubId,
        onHubSelected: (id) {
          Navigator.of(context).pop();
          onHubSelected(id);
        },
      ),
    );
  }
}

class _HubOverflowSheet extends StatelessWidget {
  final List<Container> hubs;
  final String? activeHubId;
  final ValueChanged<String> onHubSelected;

  const _HubOverflowSheet({
    required this.hubs,
    required this.activeHubId,
    required this.onHubSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ...hubs.map(
            (hub) => ListTile(
              leading: Icon(_hubIconData(hub.icon)),
              title: Text(hub.name),
              selected: hub.id == activeHubId,
              onTap: () => onHubSelected(hub.id),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Hilfsfunktion: Icon-Name → IconData ──────────────────────────────────────

IconData _hubIconData(String name) {
  const map = <String, IconData>{
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
    'idea': Icons.lightbulb,
    'todo': Icons.checklist,
    'inbox': Icons.inbox,
    'archive': Icons.archive,
    'folder': Icons.folder,
    'work': Icons.work,
    'home': Icons.home,
    'school': Icons.school,
    'code': Icons.code,
    'travel': Icons.flight,
    'music': Icons.music_note,
    'movie': Icons.movie,
    'food': Icons.restaurant,
    'health': Icons.health_and_safety,
    'shopping': Icons.shopping_bag,
    'fitness': Icons.fitness_center,
  };
  return map[name] ?? Icons.bookmarks_outlined;
}
