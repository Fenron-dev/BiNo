// Datei: lib/app.dart
//
// ZWECK: Wurzel-Widget der App. Verbindet MaterialApp.router mit dem
//        go_router- und Theme-Setup. ShareIntentHandler verarbeitet eingehende
//        Share-Intents von anderen Apps.
// ABHÄNGIGKEITEN: routerProvider (di.dart), AppTheme (theme.dart),
//                 ShareIntentHandler.
// PHASE: 1 – Grundgerüst. Phase 2: ShareIntentHandler. Phase 6: ThemeMode-Override.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'core/router.dart';
import 'features/share_intent/share_intent_handler.dart';

/// Haupteinstieg-Widget der App.
///
/// ConsumerWidget statt StatelessWidget, weil wir den routerProvider beobachten.
class BiNoApp extends ConsumerWidget {
  const BiNoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ShareIntentHandler(
      child: MaterialApp.router(
        title: 'BiNo',
        debugShowCheckedModeBanner: false,

        // Theme folgt dem System-Setting. Phase 6: User-Override via Riverpod-Provider.
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,

        routerConfig: router,
      ),
    );
  }
}
