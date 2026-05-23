// Datei: lib/core/router.dart
//
// ZWECK: Definiert die gesamte Navigation der App via go_router.
//        Nutzt StatefulShellRoute für persistente Bottom-Navigation.
// ABHÄNGIGKEITEN: go_router, alle Screen-Klassen.
// PHASE: 1 – Feed, Projekte, Bereiche. Phase 2+ fügt Detail-, Settings- und
//        Such-Routen hinzu.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'constants.dart';
import '../app_shell.dart';
import '../features/feed/feed_screen.dart';
import '../features/projects/projects_screen.dart';
import '../features/areas/areas_screen.dart';
import '../features/entry_detail/entry_detail_screen.dart';
import '../features/settings/settings_screen.dart';

/// GoRouter als Riverpod-Provider.
///
/// WARUM Provider statt globale GoRouter-Instanz?
/// Provider ermöglicht das Überschreiben in Tests (ProviderContainer.overrides)
/// und den Zugriff auf andere Provider (z. B. Authentifizierungs-Status in Phase 6).
///
/// keepAlive: true – der Router darf nie disposed werden, solange die App läuft.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.feed,
    // debugLogDiagnostics: Gibt jeden Navigations-Event auf der Konsole aus.
    // In der Produktion deaktivieren (Phase 7: Release-Build-Flag).
    debugLogDiagnostics: true,
    routes: [
      // Einstellungen: Außerhalb der Shell → kein BottomAppBar sichtbar.
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      // StatefulShellRoute: Hält für jeden Tab einen eigenen NavigatorKey.
      // Beim Tab-Wechsel wird der vorherige Tab-Zustand bewahrt (z. B.
      // Scroll-Position im Feed, Drill-Down-Zustand in Projekten).
      //
      // WARUM StatefulShellRoute statt ShellRoute?
      // ShellRoute würde den Navigations-Stack eines Tabs zurücksetzen,
      // sobald man zu einem anderen Tab wechselt. StatefulShellRoute
      // bewahrt jeden Tab-Stack unabhängig.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // AppShell bekommt die navigationShell übergeben, um Tab-Wechsel
          // via navigationShell.goBranch() auslösen zu können.
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Feed + Entry-Detail (Subroute im Feed-Branch)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.feed,
                builder: (context, state) => const FeedScreen(),
                routes: [
                  GoRoute(
                    // Relativer Pfad → Vollpfad: /feed/detail/:id
                    path: 'detail/:id',
                    builder: (context, state) => EntryDetailScreen(
                      entryId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Branch 1: Projekte
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.projects,
                builder: (context, state) => const ProjectsScreen(),
              ),
            ],
          ),
          // Branch 2: Bereiche
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.areas,
                builder: (context, state) => const AreasScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}, name: 'routerProvider');
