// Datei: lib/main.dart
//
// ZWECK: App-Einstiegspunkt. Bewusst minimal gehalten.
//        Alle Initialisierungslogik übernehmen Riverpod-Provider lazy beim ersten Zugriff.
// ABHÄNGIGKEITEN: flutter_riverpod (ProviderScope), app.dart (BiNoApp).
// PHASE: 1 – Grundgerüst.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized() muss vor allen Plugin-
  // oder FFI-Aufrufen beim Start stehen. drift_flutter und sqlite3 nutzen
  // FFI/Plattformkanäle beim Öffnen der Datenbank.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // ProviderScope: Wurzel des Riverpod-Provider-Baums.
    // Alle ref.watch()-Aufrufe lösen Provider aus diesem Scope auf.
    const ProviderScope(
      child: BiNoApp(),
    ),
  );
}
