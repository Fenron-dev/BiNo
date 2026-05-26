// Datei: lib/services/youtube_transcript_service.dart
//
// ZWECK: Lädt das Transkript (Untertitel) eines YouTube-Videos ohne API-Key.
//        Nutzt YouTubes inoffizielles timedtext-API, das über die eingebetteten
//        Seiten-JSON-Daten adressiert wird.
// ABHÄNGIGKEITEN: http, xml.
// HINWEIS: YouTube kann die Seitenstruktur jederzeit ändern – immer robust
//          mit Null-Returns umgehen.
// PHASE: 6 – URL-Analyse.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class YoutubeTranscriptService {
  static final _videoIdPattern = RegExp(
    r'(?:youtube\.com/(?:watch\?v=|embed/|shorts/)|youtu\.be/)([a-zA-Z0-9_-]{11})',
  );

  /// Extrahiert die Video-ID aus einer YouTube-URL.
  /// Gibt null zurück wenn die URL kein YouTube-Link ist.
  static String? extractVideoId(String url) =>
      _videoIdPattern.firstMatch(url)?.group(1);

  /// Versucht das Transkript für [videoId] zu laden.
  ///
  /// Gibt null zurück wenn kein Transkript verfügbar, der Abruf fehlschlägt
  /// oder YouTube die Anfrage blockiert.
  /// Bevorzugt Deutsch, fällt auf Englisch und dann auf die erste verfügbare
  /// Sprache zurück.
  Future<String?> fetchTranscript(String videoId) async {
    try {
      final pageResp = await http.get(
        Uri.parse('https://www.youtube.com/watch?v=$videoId'),
        headers: {
          // Mobile User-Agent um schlankere Seite und weniger Bot-Schutz zu erhalten.
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
          'Accept-Language': 'de-DE,de;q=0.9,en;q=0.8',
        },
      ).timeout(const Duration(seconds: 12));

      if (pageResp.statusCode != 200) return null;

      final tracks = _extractCaptionTracks(pageResp.body);
      if (tracks == null || tracks.isEmpty) return null;

      final trackUrl = _selectBestTrack(tracks);
      if (trackUrl == null) return null;

      final transcriptResp = await http
          .get(Uri.parse(trackUrl))
          .timeout(const Duration(seconds: 10));
      if (transcriptResp.statusCode != 200) return null;

      return _parseXml(transcriptResp.body);
    } catch (_) {
      return null;
    }
  }

  // ── Privat ────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>>? _extractCaptionTracks(String html) {
    const marker = '"captionTracks":';
    final idx = html.indexOf(marker);
    if (idx == -1) return null;

    final start = idx + marker.length;
    var depth = 0;
    var end = start;

    for (var i = start; i < html.length; i++) {
      if (html[i] == '[') depth++;
      if (html[i] == ']') {
        depth--;
        if (depth == 0) {
          end = i + 1;
          break;
        }
      }
    }
    if (end <= start) return null;

    try {
      return (jsonDecode(html.substring(start, end)) as List)
          .cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  String? _selectBestTrack(List<Map<String, dynamic>> tracks) {
    for (final lang in ['de', 'en']) {
      for (final t in tracks) {
        final code = t['languageCode'] as String? ?? '';
        if (code.startsWith(lang)) return t['baseUrl'] as String?;
      }
    }
    return tracks.first['baseUrl'] as String?;
  }

  String? _parseXml(String rawXml) {
    try {
      final doc = XmlDocument.parse(rawXml);
      final buf = StringBuffer();
      for (final node in doc.findAllElements('text')) {
        final text = node.innerText
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .trim();
        if (text.isNotEmpty) buf.write('$text ');
      }
      final result = buf.toString().trim();
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }
}
