// Datei: lib/services/url_metadata_service.dart
//
// ZWECK: Holt Open-Graph-Metadaten (Titel, Beschreibung, Vorschaubild) für URLs.
//        Wird beim Erfassen von Links aufgerufen, um den Eintrag anzureichern.
// ABHÄNGIGKEITEN: http.
// PHASE: 2 – URL/Link-Capture.

import 'dart:io';
import 'package:http/http.dart' as http;

/// Open-Graph-Metadaten einer URL.
class UrlMetadata {
  /// Seitentitel (og:title oder <title>-Tag).
  final String? title;

  /// Kurzbeschreibung (og:description oder meta description).
  final String? description;

  /// URL des Vorschaubilds (og:image).
  final String? imageUrl;

  /// Domain der URL (z. B. 'youtube.com').
  final String domain;

  /// Originale URL.
  final String url;

  const UrlMetadata({
    this.title,
    this.description,
    this.imageUrl,
    required this.domain,
    required this.url,
  });
}

/// Service zum Abrufen von Open-Graph-Metadaten.
///
/// WARUM eigene Implementierung statt `metadata_fetch`-Package?
/// Das metadata_fetch-Package hat ältere Abhängigkeiten. Mit http und
/// einfachem Regex-Parsing decken wir alle Standard-OG-Tags zuverlässig ab.
/// Für Phase 5 kann bei Bedarf ein robusteres HTML-Parser-Package ergänzt werden.
class UrlMetadataService {
  final http.Client _client;

  UrlMetadataService({http.Client? client})
      : _client = client ?? http.Client();

  /// Holt Open-Graph-Metadaten für [url].
  ///
  /// Gibt null zurück wenn die URL nicht erreichbar ist oder kein gültiges
  /// HTML zurückliefert. Fehler werden nicht geworfen – fehlendes Metadata
  /// ist kein kritischer Fehler (Eintrag wird trotzdem gespeichert).
  Future<UrlMetadata?> fetch(String url) async {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host.replaceFirst('www.', '');

      final response = await _client
          .get(
            uri,
            headers: {
              // User-Agent: viele Seiten blockieren Anfragen ohne User-Agent.
              'User-Agent':
                  'Mozilla/5.0 (compatible; BiNo-LinkPreview/1.0)',
              'Accept': 'text/html,application/xhtml+xml',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final html = response.body;

      return UrlMetadata(
        title: _extractOgTag(html, 'og:title') ??
            _extractMetaTag(html, 'title') ??
            _extractTitleTag(html),
        description: _extractOgTag(html, 'og:description') ??
            _extractMetaTag(html, 'description'),
        imageUrl: _extractOgTag(html, 'og:image'),
        domain: domain,
        url: url,
      );
    } on SocketException {
      // Keine Netzwerkverbindung: kein Fehler werfen.
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Prüft ob ein String eine valide HTTP(S)-URL ist.
  static bool isUrl(String text) {
    final trimmed = text.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  /// Extrahiert den Wert eines Open-Graph-Meta-Tags.
  /// Beispiel: <meta property="og:title" content="Seitentitel">
  String? _extractOgTag(String html, String property) {
    final regex = RegExp(
      '<meta[^>]+property=["\']$property["\'][^>]+content=["\']([^"\']+)["\']',
      caseSensitive: false,
    );
    final match = regex.firstMatch(html);
    if (match != null) return _cleanText(match.group(1));

    // Alternativ: content vor property
    final regex2 = RegExp(
      '<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']$property["\']',
      caseSensitive: false,
    );
    return _cleanText(regex2.firstMatch(html)?.group(1));
  }

  /// Extrahiert den Wert eines <meta name="...">-Tags.
  String? _extractMetaTag(String html, String name) {
    final regex = RegExp(
      '<meta[^>]+name=["\']$name["\'][^>]+content=["\']([^"\']+)["\']',
      caseSensitive: false,
    );
    return _cleanText(regex.firstMatch(html)?.group(1));
  }

  /// Extrahiert den Inhalt des <title>-Tags als Fallback.
  String? _extractTitleTag(String html) {
    final regex = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false);
    return _cleanText(regex.firstMatch(html)?.group(1));
  }

  /// Bereinigt HTML-Entitäten und überschüssige Leerzeichen.
  String? _cleanText(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}
