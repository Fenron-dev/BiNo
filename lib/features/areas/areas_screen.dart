// Datei: lib/features/areas/areas_screen.dart
//
// ZWECK: Stub-Bildschirm für die Bereiche-Ansicht.
// PHASE: 1 – Platzhalter. Vollständige Implementierung in Phase 4.

import 'package:flutter/material.dart';

/// Platzhalter-Bildschirm für Bereiche.
/// Phase 4: Identisch zu Projekten, aber für dauerhaf laufende Lebensbereiche
/// (Arbeit, Hobby, Familie) statt zeitlich begrenzte Vorhaben.
class AreasScreen extends StatelessWidget {
  const AreasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bereiche')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view_outlined, size: 64),
            SizedBox(height: 16),
            Text('Bereiche – kommt in Phase 4'),
          ],
        ),
      ),
    );
  }
}
