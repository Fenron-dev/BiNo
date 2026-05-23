// Datei: lib/services/ai_enrich_service.dart
//
// ZWECK: Ruft die Anthropic Messages-API mit dem Nutzer-eigenen API-Key auf.
//        Liefert strukturierte Ergebnisse für die vier Anreicherungs-Aktionen:
//        Zusammenfassen, Titel generieren, Tags vorschlagen, Metadaten extrahieren.
// ABHÄNGIGKEITEN: http, dart:convert, AiSettingsService.
// PHASE: 5 – KI-Anreicherung.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_settings_service.dart';

class AiEnrichService {
  final AiSettingsService _settings;

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _apiVersion = '2023-06-01';
  static const _system =
      'Du bist ein Assistent für eine persönliche Notiz-App. '
      'Antworte immer auf Deutsch. Sei prägnant und direkt.';

  AiEnrichService(this._settings);

  Future<String> _call(String prompt) async {
    final key = await _settings.getApiKey();
    if (key == null) throw Exception('Kein API-Key konfiguriert.');
    final model = await _settings.getModel();

    final res = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'x-api-key': key,
            'anthropic-version': _apiVersion,
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
}
