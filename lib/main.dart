// Datei: lib/main.dart
//
// ZWECK: App-Einstiegspunkt. Bewusst minimal gehalten.
//        Alle Initialisierungslogik übernehmen Riverpod-Provider lazy beim ersten Zugriff.
// ABHÄNGIGKEITEN: flutter_riverpod (ProviderScope), app.dart (BiNoApp).
// PHASE: 1 – Grundgerüst.

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:media_kit/media_kit.dart';
import 'package:metadata_god/metadata_god.dart';

import 'app.dart';
import 'core/di.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized() muss vor allen Plugin-
  // oder FFI-Aufrufen beim Start stehen. drift_flutter und sqlite3 nutzen
  // FFI/Plattformkanäle beim Öffnen der Datenbank.
  WidgetsFlutterBinding.ensureInitialized();

  // media_kit muss vor dem ersten Player-Aufruf initialisiert werden.
  // Lädt native Bibliotheken (libmpv/FFmpeg) für Audio- und Video-Wiedergabe.
  MediaKit.ensureInitialized();

  // metadata_god: Rust-basierte Audio-Metadaten-Bibliothek.
  // Initialisierung lädt die nativen Bibliotheken für ID3/FLAC/OGG-Tag-Parsing.
  MetadataGod.initialize();

  // Lokalisierungsdaten für DateFormat('de_DE') laden – ohne diesen Aufruf
  // wirft DateFormat eine LocaleDataException zur Laufzeit.
  await initializeDateFormatting('de_DE');

  // Benachrichtigungsdienst initialisieren (Zeitzone + Kanäle).
  // Muss vor dem ersten Frame abgeschlossen sein, damit Erinnerungen bei
  // App-Start sofort eingeplant werden können.
  await NotificationService.initialize();
  // Wöchentlichen Rückblick einmalig (wieder-)einplanen.
  // zonedSchedule mit matchDateTimeComponents ist idempotent – ein Doppelaufruf
  // überschreibt die bestehende Planung ohne eine zweite Benachrichtigung zu erzeugen.
  unawaited(NotificationService.scheduleWeeklyDigest());

  // Theme vor dem ersten Frame laden, damit kein Flicker zwischen System-
  // Default und Nutzereinstellung auftritt.
  final initialTheme = await ThemeService().getThemeMode();

  runApp(
    ProviderScope(
      overrides: [
        // Überschreibt den StateProvider-Initialwert mit dem gespeicherten Wert.
        themeModeProvider.overrideWith((ref) => initialTheme),
      ],
      child: const BiNoApp(),
    ),
  );
}
