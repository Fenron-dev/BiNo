// Datei: lib/services/url_analysis_service.dart
//
// ZWECK: Orchestriert die automatische KI-Analyse neu erfasster Link-Einträge.
//        Erkennt YouTube-Videos, lädt optional das Transkript und ruft die KI
//        mit einem strukturierten Prompt auf. Das Ergebnis wird als Notiz
//        (notes-Feld) in den Eintrag geschrieben.
// ABHÄNGIGKEITEN: AiEnrichService, UrlAnalysisSettingsService,
//                 YoutubeTranscriptService, EntryRepository.
// MUSTER: Service – wird fire-and-forget nach createEntry() aufgerufen.
// PHASE: 6 – URL-Analyse.

import 'package:flutter/foundation.dart';

import '../data/repositories/entry_repository.dart';
import 'ai_enrich_service.dart';
import 'url_analysis_settings_service.dart';
import 'youtube_transcript_service.dart';

class UrlAnalysisService {
  final AiEnrichService _ai;
  final UrlAnalysisSettingsService _settings;
  final YoutubeTranscriptService _transcript;
  final EntryRepository _entryRepo;

  UrlAnalysisService({
    required AiEnrichService ai,
    required UrlAnalysisSettingsService settings,
    required YoutubeTranscriptService transcript,
    required EntryRepository entryRepo,
  })  : _ai = ai,
        _settings = settings,
        _transcript = transcript,
        _entryRepo = entryRepo;

  /// Analysiert [url] und schreibt das Ergebnis als Notiz in Eintrag [entryId].
  ///
  /// Wird fire-and-forget nach dem Erstellen eines Link-Eintrags aufgerufen.
  /// Fehler werden geloggt aber nicht geworfen – der Eintrag bleibt immer sicher.
  Future<void> analyzeAndUpdateEntry({
    required String entryId,
    required String url,
    String? title,
    String? description,
  }) async {
    try {
      final config = await _settings.load();
      if (!config.enabled) return;

      // YouTube-Erkennung
      final videoId = YoutubeTranscriptService.extractVideoId(url);
      final isYoutube = videoId != null;

      // Transkript laden (nur wenn aktiviert + YouTube)
      String? transcript;
      if (isYoutube && config.youtubeTranscriptEnabled) {
        transcript = await _transcript.fetchTranscript(videoId);
      }

      // Prompt bauen
      final prompt = isYoutube
          ? _buildYouTubePrompt(
              url: url,
              title: title,
              transcript: transcript,
            )
          : _buildUrlPrompt(
              url: url,
              title: title,
              description: description,
            );

      // AI-Provider aus Konfiguration
      final provider =
          config.provider == UrlAnalysisSettingsService.kSame ? null : config.provider;

      final analysis = await _ai.callPrompt(prompt, providerOverride: provider);

      if (analysis.trim().isEmpty) return;

      // Ergebnis als Notiz speichern (überschreibt bestehende Notizen).
      // Enthält den vorhandenen Eintrag – falls Notes schon befüllt ist,
      // wird der AI-Analyse-Block angehängt.
      final existing = await _entryRepo.getEntryById(entryId);
      if (existing == null) return;

      final existingNotes = existing.notes?.trim() ?? '';
      final separator = existingNotes.isEmpty ? '' : '\n\n---\n\n';
      final combinedNotes = '$existingNotes$separator$analysis'.trim();

      await _entryRepo.updateEntry(
        id: entryId,
        body: existing.body,
        title: existing.title,
        notes: combinedNotes,
        status: existing.status,
      );
    } catch (e, st) {
      debugPrint('[UrlAnalysisService] Fehler: $e\n$st');
    }
  }

  // ── Prompts ───────────────────────────────────────────────────────────────

  String _buildYouTubePrompt({
    required String url,
    String? title,
    String? transcript,
  }) {
    final buf = StringBuffer();
    buf.writeln(
      'Du bist ein Assistent für BiNo, eine persönliche Notiz-App. '
      'Analysiere das folgende YouTube-Video und erstelle eine strukturierte '
      'Notiz auf Deutsch. Sei prägnant und fokussiert.',
    );
    buf.writeln();
    if (title != null && title.isNotEmpty) buf.writeln('Titel: $title');
    buf.writeln('URL: $url');
    if (transcript != null && transcript.isNotEmpty) {
      final excerpt = transcript.length > 4000
          ? '${transcript.substring(0, 4000)}…'
          : transcript;
      buf.writeln();
      buf.writeln('Transkript-Auszug:');
      buf.writeln(excerpt);
    }
    buf.writeln();
    buf.writeln(
      'Antworte NUR mit dem formatierten Text – keine Einleitung, kein Kommentar. '
      'Nutze exakt diese Struktur:',
    );
    buf.writeln('''
## Zusammenfassung
[2–4 Sätze: Was behandelt das Video?]

## Hauptpunkte
- [Kernaussage 1]
- [Kernaussage 2]
- [Kernaussage 3]

## Erkenntnisse
[Wichtige Einsichten, Tipps oder Schlussfolgerungen]

## Für wen geeignet?
[1–2 Sätze: Zielgruppe und Relevanz]

Tags: #tag1 #tag2 #tag3''');
    return buf.toString();
  }

  String _buildUrlPrompt({
    required String url,
    String? title,
    String? description,
  }) {
    final buf = StringBuffer();
    buf.writeln(
      'Du bist ein Assistent für BiNo, eine persönliche Notiz-App. '
      'Analysiere den folgenden Link und erstelle eine strukturierte '
      'Notiz auf Deutsch. Sei prägnant und direkt.',
    );
    buf.writeln();
    if (title != null && title.isNotEmpty) buf.writeln('Titel: $title');
    buf.writeln('URL: $url');
    if (description != null && description.isNotEmpty) {
      buf.writeln('Beschreibung: $description');
    }
    buf.writeln();
    buf.writeln(
      'Antworte NUR mit dem formatierten Text – keine Einleitung. '
      'Lass nicht zutreffende Abschnitte einfach weg:',
    );
    buf.writeln('''
## Zusammenfassung
[2–3 Sätze: Was ist das?]

## Vorteile
- [Vorteil 1]
- [Vorteil 2]

## Nachteile / Risiken
- [Nachteil oder Risiko, falls vorhanden]

## Preis
[Falls Produkt oder kostenpflichtiger Service]

## Fazit
[1–2 Sätze Gesamteinschätzung]

Tags: #tag1 #tag2 #tag3''');
    return buf.toString();
  }
}
