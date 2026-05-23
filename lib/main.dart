// Datei: lib/main.dart
//
// ZWECK: App-Einstiegspunkt. Bewusst minimal gehalten.
//        Alle Initialisierungslogik übernehmen Riverpod-Provider lazy beim ersten Zugriff.
// ABHÄNGIGKEITEN: flutter_riverpod (ProviderScope), app.dart (BiNoApp).
// PHASE: 1 – Grundgerüst.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:media_kit/media_kit.dart';

import 'app.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized() muss vor allen Plugin-
  // oder FFI-Aufrufen beim Start stehen. drift_flutter und sqlite3 nutzen
  // FFI/Plattformkanäle beim Öffnen der Datenbank.
  WidgetsFlutterBinding.ensureInitialized();

  // media_kit muss vor dem ersten Player-Aufruf initialisiert werden.
  // Lädt native Bibliotheken (libmpv/FFmpeg) für Audio- und Video-Wiedergabe.
  MediaKit.ensureInitialized();

  // Lokalisierungsdaten für DateFormat('de_DE') laden – ohne diesen Aufruf
  // wirft DateFormat eine LocaleDataException zur Laufzeit.
  await initializeDateFormatting('de_DE');

  runApp(
    // ProviderScope: Wurzel des Riverpod-Provider-Baums.
    // Alle ref.watch()-Aufrufe lösen Provider aus diesem Scope auf.
    const ProviderScope(
      child: BiNoApp(),
    ),
  );
}
