// Datei: lib/features/areas/areas_screen.dart
//
// ZWECK: Einstiegspunkt für den Bereiche-Tab. Delegiert an ContainerListScreen.
// PHASE: 4 – Projekte & Bereiche.

import 'package:flutter/material.dart';
import '../containers/container_list_screen.dart';

class AreasScreen extends StatelessWidget {
  const AreasScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ContainerListScreen(kind: 'area');
}
