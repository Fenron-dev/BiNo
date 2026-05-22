// test/widget_test.dart
//
// ZWECK: Basis-Smoke-Test. Wird in Phase 7 durch vollständige Widget- und
//        Unit-Tests ersetzt (TagParser, EntryRepository, FeedScreen).
// PHASE: 1 – Platzhalter.

import 'package:flutter_test/flutter_test.dart';

import 'package:bino_bit_notes/domain/tag_parser.dart';

void main() {
  group('TagParser', () {
    test('Erkennt einfache Tags', () {
      final tags = TagParser.parse('Notiz über #idee und #lernen');
      expect(tags, containsAll(['idee', 'lernen']));
    });

    test('Erkennt hierarchische Tags', () {
      final tags = TagParser.parse('Buch #buch/sachbuch gelesen');
      expect(tags, contains('buch/sachbuch'));
    });

    test('Ignoriert reine Zahlen wie #1', () {
      final tags = TagParser.parse('Punkt #1 ist kein Tag');
      expect(tags, isEmpty);
    });

    test('Dedupliziert doppelte Tags', () {
      final tags = TagParser.parse('#idee und nochmal #idee');
      expect(tags.length, 1);
      expect(tags, contains('idee'));
    });
  });
}
