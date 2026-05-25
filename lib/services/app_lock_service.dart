// Datei: lib/services/app_lock_service.dart
//
// ZWECK: App-Sperre via Biometrie (Fingerabdruck / Gesichts-ID / PIN-Fallback).
//        Speichert den Aktivierungszustand in einer JSON-Datei analog zum ThemeService.
// ABHÄNGIGKEITEN: local_auth, dart:io, path_provider, path.
// PHASE: 6 – App-Lock.

import 'dart:convert';
import 'dart:io';

import 'package:local_auth/local_auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppLockService {
  AppLockService._();

  static const _filename = 'app_lock_settings.json';
  static final _auth = LocalAuthentication();

  // ── Persistenz ────────────────────────────────────────────────────────────

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _filename));
  }

  /// Gibt zurück ob die App-Sperre aktiv ist.
  static Future<bool> isEnabled() async {
    try {
      final file = await _file();
      if (!await file.exists()) return false;
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return data['enabled'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Aktiviert oder deaktiviert die App-Sperre.
  static Future<void> setEnabled(bool enabled) async {
    final file = await _file();
    await file.writeAsString(jsonEncode({'enabled': enabled}));
  }

  // ── Biometrie ─────────────────────────────────────────────────────────────

  /// Prüft ob Biometrie oder Gerätesperre (PIN/Muster) vorhanden ist.
  static Future<bool> canAuthenticate() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Startet die Authentifizierung.
  /// Gibt true zurück wenn erfolgreich, false bei Abbruch oder Fehler.
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'BiNo entsperren',
        options: const AuthenticationOptions(
          biometricOnly: false, // PIN/Muster als Fallback erlauben
          stickyAuth: true,     // Auth-Dialog bleibt bei App-Wechsel offen
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
