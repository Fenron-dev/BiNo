// Datei: lib/services/ai_settings_service.dart
//
// ZWECK: Persistiert KI-Einstellungen (API-Key, Modell) als JSON-Datei
//        im App-Dokumentenverzeichnis. Kein eigener Backend-Server –
//        der Nutzer verwendet seinen eigenen Anthropic-API-Key.
// ABHÄNGIGKEITEN: dart:io, dart:convert, path, path_provider.
// PHASE: 5 – KI-Anreicherung.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Verfügbare Anthropic-Modelle (ID → Anzeigename).
const kAiModels = <(String, String)>[
  ('claude-haiku-4-5-20251001', 'Haiku 4.5 – schnell & günstig'),
  ('claude-sonnet-4-6', 'Sonnet 4.6 – ausgewogen'),
  ('claude-opus-4-7', 'Opus 4.7 – beste Qualität'),
];

const _kDefaultModel = 'claude-haiku-4-5-20251001';

class AiSettingsService {
  static const _filename = 'ai_settings.json';

  String? _apiKey;
  String _model = _kDefaultModel;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, _filename));
      if (await file.exists()) {
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _apiKey = json['api_key'] as String?;
        _model = (json['model'] as String?) ?? _kDefaultModel;
      }
    } catch (_) {}
    _loaded = true;
  }

  Future<String?> getApiKey() async {
    await _ensureLoaded();
    final key = _apiKey;
    return (key == null || key.isEmpty) ? null : key;
  }

  Future<String> getModel() async {
    await _ensureLoaded();
    return _model;
  }

  Future<void> save({String? apiKey, String? model}) async {
    await _ensureLoaded();
    if (apiKey != null) {
      _apiKey = apiKey.trim().isEmpty ? null : apiKey.trim();
    }
    if (model != null) _model = model;
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, _filename));
    await file.writeAsString(jsonEncode({
      'api_key': _apiKey,
      'model': _model,
    }));
  }
}
