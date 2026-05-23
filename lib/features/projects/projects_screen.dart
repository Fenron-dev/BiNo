// Datei: lib/features/projects/projects_screen.dart
//
// ZWECK: Einstiegspunkt für den Projekte-Tab. Delegiert an ContainerListScreen.
// PHASE: 4 – Projekte & Bereiche.

import 'package:flutter/material.dart';
import '../containers/container_list_screen.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ContainerListScreen(kind: 'project');
}
