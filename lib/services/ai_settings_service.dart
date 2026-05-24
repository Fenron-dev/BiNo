// Datei: lib/services/ai_settings_service.dart
//
// ZWECK: Persistiert KI-Einstellungen (Provider, API-Keys, Modelle) als JSON.
//        Unterstützt Anthropic und OpenRouter als Provider.
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

const _kDefaultAnthropicModel = 'claude-haiku-4-5-20251001';
const _kDefaultOpenRouterModel = 'mistralai/mistral-7b-instruct:free';

/// Unterstützte KI-Anbieter.
const kProviderAnthropic = 'anthropic';
const kProviderOpenRouter = 'openrouter';

class AiSettingsService {
  static const _filename = 'ai_settings.json';

  String _provider = kProviderAnthropic;
  String? _anthropicKey;
  String _anthropicModel = _kDefaultAnthropicModel;
  String? _openRouterKey;
  String _openRouterModel = _kDefaultOpenRouterModel;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, _filename));
      if (await file.exists()) {
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;

        // Rückwärtskompatibilität: altes Format hatte nur 'api_key' und 'model'.
        if (json.containsKey('provider')) {
          _provider = json['provider'] as String? ?? kProviderAnthropic;
          _anthropicKey = json['anthropic_key'] as String?;
          _anthropicModel =
              json['anthropic_model'] as String? ?? _kDefaultAnthropicModel;
          _openRouterKey = json['openrouter_key'] as String?;
          _openRouterModel =
              json['openrouter_model'] as String? ?? _kDefaultOpenRouterModel;
        } else {
          // Altes Format → als Anthropic übernehmen.
          _anthropicKey = json['api_key'] as String?;
          _anthropicModel =
              json['model'] as String? ?? _kDefaultAnthropicModel;
        }
      }
    } catch (_) {}
    _loaded = true;
  }

  Future<String> getProvider() async {
    await _ensureLoaded();
    return _provider;
  }

  Future<String?> getAnthropicKey() async {
    await _ensureLoaded();
    final key = _anthropicKey;
    return (key == null || key.isEmpty) ? null : key;
  }

  /// Alias für Rückwärtskompatibilität (wird von AiEnrichService genutzt).
  Future<String?> getApiKey() => getAnthropicKey();

  Future<String> getAnthropicModel() async {
    await _ensureLoaded();
    return _anthropicModel;
  }

  /// Alias für Rückwärtskompatibilität.
  Future<String> getModel() => getAnthropicModel();

  Future<String?> getOpenRouterKey() async {
    await _ensureLoaded();
    final key = _openRouterKey;
    return (key == null || key.isEmpty) ? null : key;
  }

  Future<String> getOpenRouterModel() async {
    await _ensureLoaded();
    return _openRouterModel;
  }

  Future<void> save({
    String? provider,
    String? anthropicKey,
    String? anthropicModel,
    String? openRouterKey,
    String? openRouterModel,
  }) async {
    await _ensureLoaded();
    if (provider != null) _provider = provider;
    if (anthropicKey != null) {
      _anthropicKey = anthropicKey.trim().isEmpty ? null : anthropicKey.trim();
    }
    if (anthropicModel != null) _anthropicModel = anthropicModel;
    if (openRouterKey != null) {
      _openRouterKey =
          openRouterKey.trim().isEmpty ? null : openRouterKey.trim();
    }
    if (openRouterModel != null) _openRouterModel = openRouterModel;

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, _filename));
    await file.writeAsString(jsonEncode({
      'provider': _provider,
      'anthropic_key': _anthropicKey,
      'anthropic_model': _anthropicModel,
      'openrouter_key': _openRouterKey,
      'openrouter_model': _openRouterModel,
    }));
  }
}
