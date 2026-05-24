// Datei: lib/services/ai_enrich_service.dart
//
// ZWECK: Ruft KI-APIs (Anthropic oder OpenRouter) auf.
//        Liefert strukturierte Ergebnisse für die vier Anreicherungs-Aktionen.
// ABHÄNGIGKEITEN: http, dart:convert, AiSettingsService.
// PHASE: 5 – KI-Anreicherung.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_settings_service.dart';

/// Ein OpenRouter-Modell mit ID, Anzeigename und Free-Tier-Flag.
class OpenRouterModel {
  final String id;
  final String name;
  final bool isFree;

  const OpenRouterModel({
    required this.id,
    required this.name,
    required this.isFree,
  });
}

class AiEnrichService {
  final AiSettingsService _settings;

  static const _anthropicEndpoint = 'https://api.anthropic.com/v1/messages';
  static const _openRouterEndpoint =
      'https://openrouter.ai/api/v1/chat/completions';
  static const _anthropicVersion = '2023-06-01';
  static const _system =
      'Du bist ein Assistent für eine persönliche Notiz-App. '
      'Antworte immer auf Deutsch. Sei prägnant und direkt.';

  AiEnrichService(this._settings);

  // ── Interne Call-Methoden ─────────────────────────────────────────────────

  Future<String> _callAnthropic(String prompt) async {
    final key = await _settings.getAnthropicKey();
    if (key == null) throw Exception('Kein Anthropic-API-Key konfiguriert.');
    final model = await _settings.getAnthropicModel();

    final res = await http
        .post(
          Uri.parse(_anthropicEndpoint),
          headers: {
            'x-api-key': key,
            'anthropic-version': _anthropicVersion,
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'max_tokens': 1024,
            'system': _system,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      final err = jsonDecode(res.body) as Map<String, dynamic>;
      final msg = ((err['error'] as Map?)?['message'] as String?) ??
          'API-Fehler ${res.statusCode}';
      throw Exception(msg);
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final content = (data['content'] as List).first as Map<String, dynamic>;
    return content['text'] as String;
  }

  Future<String> _callOpenRouter(String prompt) async {
    final key = await _settings.getOpenRouterKey();
    if (key == null) throw Exception('Kein OpenRouter-API-Key konfiguriert.');
    final model = await _settings.getOpenRouterModel();

    final res = await http
        .post(
          Uri.parse(_openRouterEndpoint),
          headers: {
            'Authorization': 'Bearer $key',
            'HTTP-Referer': 'https://github.com/Fenron-dev/BiNo',
            'X-Title': 'BiNo',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'max_tokens': 1024,
            'messages': [
              {'role': 'system', 'content': _system},
              {'role': 'user', 'content': prompt},
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      final err = jsonDecode(res.body) as Map<String, dynamic>;
      final msg = ((err['error'] as Map?)?['message'] as String?) ??
          'API-Fehler ${res.statusCode}';
      throw Exception(msg);
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List;
    final message = (choices.first as Map)['message'] as Map<String, dynamic>;
    return message['content'] as String;
  }

  Future<String> _call(String prompt) async {
    final provider = await _settings.getProvider();
    if (provider == kProviderOpenRouter) return _callOpenRouter(prompt);
    return _callAnthropic(prompt);
  }

  // ── Öffentliche Aktionen ──────────────────────────────────────────────────

  Future<String> summarize(String content) => _call(
        'Fasse diesen Eintrag in 1–3 Sätzen zusammen. '
        'Antworte nur mit der Zusammenfassung, ohne Einleitung:\n\n$content',
      );

  Future<String> generateTitle(String content) async {
    final raw = await _call(
      'Generiere einen prägnanten Titel (max. 60 Zeichen) für diesen Eintrag. '
      'Antworte nur mit dem Titel, ohne Anführungszeichen oder Einleitung:\n\n$content',
    );
    return raw.trim().replaceAll('"', '').replaceAll("'", '');
  }

  Future<List<String>> suggestTags(String content) async {
    final raw = await _call(
      'Schlage 3–5 relevante Tags für diesen Eintrag vor. '
      'Tags: nur Kleinbuchstaben, Hierarchie via "/" möglich (z. B. buch/roman). '
      'Antworte nur mit einem JSON-Array, keine Erklärungen: '
      '["tag1", "tag2"]\n\n$content',
    );
    final start = raw.indexOf('[');
    final end = raw.lastIndexOf(']');
    if (start < 0 || end < 0) return [];
    try {
      return (jsonDecode(raw.substring(start, end + 1)) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, String>> extractProperties(String content) async {
    final raw = await _call(
      'Extrahiere strukturierte Metadaten aus diesem Eintrag. '
      'Mögliche Felder: Autor, ISBN, URL, Bewertung, Status, Ort, Datum o. ä. '
      'Maximal 5 Felder. Antworte nur mit einem JSON-Objekt, '
      'keine Erklärungen: {"Feld": "Wert"}\n\n$content',
    );
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end < 0) return {};
    try {
      final map =
          jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  // ── OpenRouter Modell-Liste ───────────────────────────────────────────────

  /// Lädt alle verfügbaren OpenRouter-Modelle (kostenlose zuerst).
  static Future<List<OpenRouterModel>> fetchOpenRouterModels() async {
    try {
      final res = await http
          .get(Uri.parse('https://openrouter.ai/api/v1/models'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final models = (data['data'] as List).map((m) {
        final id = m['id'] as String;
        final name = m['name'] as String? ?? id;
        final promptPrice =
            (m['pricing']?['prompt'] as String?) ?? '1';
        final isFree = double.tryParse(promptPrice) == 0.0;
        return OpenRouterModel(id: id, name: name, isFree: isFree);
      }).toList();

      // Kostenlose Modelle zuerst, dann alphabetisch.
      models.sort((a, b) {
        if (a.isFree && !b.isFree) return -1;
        if (!a.isFree && b.isFree) return 1;
        return a.name.compareTo(b.name);
      });

      return models;
    } catch (_) {
      return [];
    }
  }
}
