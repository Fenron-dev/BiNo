// Datei: lib/services/theme_service.dart
//
// ZWECK: Liest und schreibt die Theme-Einstellung (System/Hell/Dunkel/OLED)
//        in eine JSON-Datei im App-Dokumentenverzeichnis.
// ABHÄNGIGKEITEN: dart:io, dart:convert, path_provider, path.
// PHASE: 6 – Theme-Auswahl.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ThemeService {
  static const _filename = 'theme_settings.json';

  static const kSystem = 'system';
  static const kLight = 'light';
  static const kDark = 'dark';
  static const kOled = 'oled';

  Future<String> getThemeMode() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, _filename));
      if (!await file.exists()) return kSystem;
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return data['theme'] as String? ?? kSystem;
    } catch (_) {
      return kSystem;
    }
  }

  Future<void> save(String mode) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, _filename));
    await file.writeAsString(jsonEncode({'theme': mode}));
  }
}
