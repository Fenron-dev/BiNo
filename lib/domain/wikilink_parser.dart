// Datei: lib/domain/wikilink_parser.dart
//
// ZWECK: Extrahiert [[Eintragstitel]]-Verweise aus Text (Wikilink-Syntax).
//        Reines Dart ohne Flutter-Abhängigkeit – direkt unit-testbar.
// PHASE: 4 – Wikilinks.

/// Erkennt und extrahiert [[Titel]]-Wikilinks aus einem Text.
class WikilinkParser {
  WikilinkParser._();

  static final _regex = RegExp(r'\[\[([^\[\]\n]+)\]\]');

  /// Gibt alle eindeutigen Wikilink-Titel zurück, die im [text] vorkommen.
  static List<String> extract(String text) {
    return _regex
        .allMatches(text)
        .map((m) => m.group(1)!.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Gibt true zurück, wenn [text] mindestens einen Wikilink enthält.
  static bool containsWikilinks(String text) => _regex.hasMatch(text);
}
