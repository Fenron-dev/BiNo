// Datei: lib/features/projects/projects_screen.dart
//
// ZWECK: Stub-Bildschirm für die Projekte-Ansicht.
// PHASE: 1 – Platzhalter. Vollständige Implementierung in Phase 4.

import 'package:flutter/material.dart';

/// Platzhalter-Bildschirm für Projekte.
/// Phase 4: Liste aller Projekte mit Cover-Karten, Drill-Down und CRUD.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projekte')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 64),
            SizedBox(height: 16),
            Text('Projekte – kommt in Phase 4'),
          ],
        ),
      ),
    );
  }
}
