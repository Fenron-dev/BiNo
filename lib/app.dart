// Datei: lib/app.dart
//
// ZWECK: Wurzel-Widget der App. Verbindet MaterialApp.router mit dem
//        go_router- und Theme-Setup.
// ABHÄNGIGKEITEN: routerProvider (di.dart), AppTheme (theme.dart).
// PHASE: 1 – Grundgerüst. Phase 6 fügt ThemeMode-Auswahl via Provider hinzu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'core/router.dart';

/// Haupteinstieg-Widget der App.
///
/// ConsumerWidget statt StatelessWidget, weil wir den routerProvider beobachten.
/// Die App selbst hält keinen eigenen Zustand – alles kommt aus Riverpod-Providern.
class BiNoApp extends ConsumerWidget {
  const BiNoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'BiNo',
      debugShowCheckedModeBanner: false,

      // Theme folgt dem System-Setting. Phase 6: User-Override via Riverpod-Provider
      // der den Wert aus SharedPreferences liest.
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      routerConfig: router,
    );
  }
}
