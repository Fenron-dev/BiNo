// Datei: lib/core/theme.dart
//
// ZWECK: Material 3 Theme-Definitionen für Hell-, Dunkel- und OLED-Dark-Modus.
// ABHÄNGIGKEITEN: Nur Flutter/Material.
// PHASE: 1 – Grundgerüst. Phase 6 ergänzt Nutzerauswahl in den Einstellungen.

import 'package:flutter/material.dart';

/// Alle Theme-Definitionen der App.
///
/// WARUM Material 3?
/// Flutter 3.16+ aktiviert Material 3 standardmäßig. M3-Tokens (ColorScheme,
/// Typography) bieten ein konsistentes, modernes Erscheinungsbild ohne manuelle
/// Farb-Feinabstimmung.
///
/// WARUM violett als Seed-Farbe?
/// #6750A4 ist Material 3's Standard-Purple – wirkt premium und persönlich,
/// nicht korporativ. Passend für eine persönliche Notiz-App.
/// Phase 6: User-konfigurierbare Farbe via Einstellungen.
abstract class AppTheme {
  static const Color _seedColor = Color(0xFF6750A4);

  /// Helles Theme für System-Hellmodus.
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          // Linksbündige Titel fühlen sich eher wie eine Chat-App an.
          centerTitle: false,
          elevation: 0,
          // scrolledUnderElevation: 1 zeigt eine subtile Trennlinie wenn
          // die Liste unter der AppBar gescrollt wird.
          scrolledUnderElevation: 1,
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      );

  /// Dunkles Theme für System-Dunkel- oder expliziten Dunkel-Modus.
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(elevation: 0),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      );

  /// OLED-Dark-Theme: verwendet reines Schwarz als Hintergrund.
  ///
  /// WARUM OLED-Dark separat?
  /// Das Samsung Galaxy S21 FE (Referenzgerät) hat ein AMOLED-Display.
  /// Schwarze Pixel auf AMOLED-Displays schalten sich vollständig ab
  /// und verbrauchen keine Energie. Das spart Akku und sieht schärfer aus.
  /// Phase 6: als Nutzer-Option in den Einstellungen (Allgemein → Theme).
  static ThemeData get oledDarkTheme => darkTheme.copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
          surface: Colors.black,
          surfaceContainerLowest: Colors.black,
          surfaceContainerLow: const Color(0xFF0D0D0D),
          surfaceContainer: const Color(0xFF121212),
        ),
      );
}
