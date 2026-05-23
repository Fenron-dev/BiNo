// Datei: lib/app_shell.dart
//
// ZWECK: Persistente App-Hülle mit BottomAppBar (Navigation) und zentralem FAB.
//        Alle Tabs teilen diese Hülle – sie selbst ändert sich nicht beim Tab-Wechsel.
// ABHÄNGIGKEITEN: go_router (StatefulNavigationShell), CaptureSheet, AudioCaptureSheet.
// PHASE: 1 – Feed, Projekte, Bereiche + FAB. Phase 2: Long-Press → AudioCaptureSheet.

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

/// App-Hülle mit persistenter Bottom-Navigation und kontextsensitivem FAB.
///
/// WARUM BottomAppBar + FAB statt NavigationBar?
/// Material 3's NavigationBar unterstützt keinen eingebetteten Center-FAB.
/// BottomAppBar mit CircularNotchedRectangle + FloatingActionButtonLocation.centerDocked
/// ist das korrekte Material-3-Muster für diese Layout-Anforderung (WhatsApp-/Telegram-Stil).
///
/// FAB-Verhalten nach Tab:
/// - Feed (0): Kurztippen → CaptureSheet, Long-Press → AudioCaptureSheet
/// - Projekte (1): Kurztippen → neues Projekt erstellen
/// - Bereiche (2): Kurztippen → neuen Bereich erstellen
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  /// Wechselt zum Tab mit dem gegebenen Index.
  ///
  /// initialLocation: true setzt den Tab auf seinen Root-Screen zurück,
  /// wenn der Nutzer den bereits aktiven Tab nochmals antippt –
  /// Standard-Verhalten in Chat-Apps (Doppeltipp scrollt nach oben).
  void _onTabTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  /// Öffnet das Quick-Capture-Sheet als modales BottomSheet.
  void _openCaptureSheet(BuildContext context) {
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

  /// Öffnet das Audio-Capture-Sheet (Long-Press auf FAB im Feed-Tab).
  void _openAudioCaptureSheet(BuildContext context) {
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

  /// FAB-Aktion je nach aktivem Tab.
  Future<void> _onFabPressed(BuildContext context, WidgetRef ref) async {
    switch (navigationShell.currentIndex) {
      case 0:
        _openCaptureSheet(context);
      case 1:
        await _createContainer(context, ref, 'project');
      case 2:
        await _createContainer(context, ref, 'area');
    }
  }

  /// Öffnet das ContainerFormSheet und legt den neuen Container an.
  Future<void> _createContainer(
    BuildContext context,
    WidgetRef ref,
    String kind,
  ) async {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnFeed = navigationShell.currentIndex == 0;

    return Scaffold(
      // extendBody: true lässt den Inhalt unter die BottomAppBar rendern.
      extendBody: true,
      body: navigationShell,

      // GestureDetector wrappet den FAB für Long-Press (nur im Feed-Tab).
      // WICHTIG: Kein 'tooltip' auf dem FAB – Tooltip registriert intern
      // einen eigenen onLongPress-Handler, der den GestureDetector aussticht.
      floatingActionButton: GestureDetector(
        onLongPress: isOnFeed ? () => _openAudioCaptureSheet(context) : null,
        child: FloatingActionButton(
          onPressed: () => _onFabPressed(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        // CircularNotchedRectangle erstellt die Einkerbung für den FAB.
        shape: const CircularNotchedRectangle(),
        // notchMargin: Abstand zwischen FAB-Rand und Einkerbungs-Rand.
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Linke Seite: Feed + Projekte
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Feed',
              index: 0,
              currentIndex: navigationShell.currentIndex,
              onTap: () => _onTabTapped(0),
            ),
            _NavItem(
              icon: Icons.folder_outlined,
              activeIcon: Icons.folder,
              label: 'Projekte',
              index: 1,
              currentIndex: navigationShell.currentIndex,
              onTap: () => _onTabTapped(1),
            ),
            // Freiraum für den FAB-Notch in der Mitte.
            const SizedBox(width: 56),
            // Rechte Seite: Bereiche (Phase 4: + Hub-Tabs)
            _NavItem(
              icon: Icons.grid_view_outlined,
              activeIcon: Icons.grid_view,
              label: 'Bereiche',
              index: 2,
              currentIndex: navigationShell.currentIndex,
              onTap: () => _onTabTapped(2),
            ),
            // Phase 4: Dynamische Hub-Tabs werden hier eingefügt.
            // Mehr als 4 sichtbare Tabs → Overflow-"Mehr"-Menü.
          ],
        ),
      ),
    );
  }
}

/// Einzelner Navigation-Button in der BottomAppBar.
///
/// WARUM kein NavigationDestination?
/// NavigationDestination gehört zur NavigationBar, nicht zur BottomAppBar.
/// Wir bauen unsere eigenen Tap-Targets mit Expanded + InkWell.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color:
                  isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
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
