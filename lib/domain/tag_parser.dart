// Datei: lib/domain/tag_parser.dart
//
// ZWECK: Parst #Tag-Syntax aus dem Eintragstext. Reine Dart-Klasse ohne
//        Flutter- oder Datenbankabhängigkeiten → direkt unit-testbar.
// ABHÄNGIGKEITEN: Keine.
// PHASE: 1 – Grundgerüst.

/// Extrahiert #Tags aus einem Markdown-Text.
///
/// WARUM eine eigene Klasse statt inline im Repository?
/// (1) Testbarkeit: Der Parser kann isoliert getestet werden ohne DB-Setup.
/// (2) Wiederverwendbarkeit: Phase 4 nutzt ihn auch im Wikilink-Editor.
/// (3) Erweiterbarkeit: Hierarchische Tags, Alias-Auflösung etc. kommen hinzu.
class TagParser {
  // Regex einmalig als Klassenkonstante kompilieren.
  // WARUM keine Neuinstanziierung pro Aufruf?
  // Regex-Kompilierung kostet ~0,5 ms. Bei jedem Speichern eines Eintrags
  // würde das sonst unnötig anfallen.
  //
  // Regex-Erklärung:
  //   #          – Literal-Hash
  //   (          – Capture-Gruppe: der eigentliche Tag-Name
  //     [a-zA-Z] – Erstes Zeichen muss ein Buchstabe sein.
  //                WARUM? Verhindert false positives wie '#1' in nummerierten
  //                Listen oder '#FF5733' in Hex-Farben.
  //     [a-zA-Z0-9_/]* – Folgezeichen: Buchstaben, Ziffern, Unterstrich, Schrägstrich.
  //                      '/' ermöglicht hierarchische Tags: #buch/sachbuch.
  //   )
  static final _tagRegex = RegExp(r'#([a-zA-Z][a-zA-Z0-9_/]*)');

  /// Parst alle #Tag-Vorkommen aus [text] und gibt ihre Namen OHNE '#' zurück.
  ///
  /// Duplikate werden entfernt (toSet). Die Reihenfolge ist undefiniert,
  /// da Sets in Dart keine garantierte Reihenfolge haben – das ist beabsichtigt,
  /// da Tag-Zuweisungen ungeordnet sind.
  ///
  /// Beispiele:
  /// ```dart
  /// TagParser.parse('Notiz über #buch/sachbuch und #idee')
  /// // → ['buch/sachbuch', 'idee']
  ///
  /// TagParser.parse('Punkt #1 ist kein Tag')
  /// // → []
  ///
  /// TagParser.parse('#idee und nochmal #idee')
  /// // → ['idee']
  /// ```
  static List<String> parse(String text) {
    return _tagRegex
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet()
        .toList();
  }
}
