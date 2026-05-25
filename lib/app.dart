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

import 'core/di.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'features/lock/app_lock_guard.dart';
import 'features/share_intent/share_intent_handler.dart';
import 'services/theme_service.dart';

/// Haupteinstieg-Widget der App.
///
/// ConsumerWidget statt StatelessWidget, weil wir den routerProvider beobachten.
class BiNoApp extends ConsumerWidget {
  const BiNoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    final (flutterThemeMode, effectiveDarkTheme) = switch (themeMode) {
      ThemeService.kLight => (ThemeMode.light, AppTheme.darkTheme),
      ThemeService.kDark => (ThemeMode.dark, AppTheme.darkTheme),
      ThemeService.kOled => (ThemeMode.dark, AppTheme.oledDarkTheme),
      _ => (ThemeMode.system, AppTheme.darkTheme), // kSystem + Fallback
    };

    return ShareIntentHandler(
      child: MaterialApp.router(
        title: 'BiNo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: effectiveDarkTheme,
        themeMode: flutterThemeMode,
        routerConfig: router,
        // AppLockGuard MUSS innerhalb von MaterialApp stehen, damit Theme,
        // MediaQuery, SafeArea und Material-Buttons korrekt funktionieren.
        builder: (context, child) =>
            AppLockGuard(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
