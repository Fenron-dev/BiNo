// Datei: lib/widgets/wikilink_text.dart
//
// ZWECK: Rendert Text mit [[Titel]]-Wikilinks als tappbare, farbige Inline-Spans.
//        Einträge ohne Wikilinks werden als normaler RichText ausgegeben.
// ABHÄNGIGKEITEN: flutter/gestures.dart (TapGestureRecognizer), WikilinkParser.
// PHASE: 4 – Wikilinks.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';


/// Zeigt [text] mit tappbaren [[Titel]]-Spans an.
///
/// Für jeden Wikilink-Treffer wird [onWikilinkTap] mit dem Linktitel aufgerufen.
/// Da TapGestureRecognizer und SelectableText inkompatibel sind, ist dieser
/// Widget nicht selektierbar – akzeptabler Tradeoff für inline-Navigierbarkeit.
class WikilinkText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Future<void> Function(String title) onWikilinkTap;

  const WikilinkText({
    super.key,
    required this.text,
    required this.onWikilinkTap,
    this.style,
  });

  @override
  State<WikilinkText> createState() => _WikilinkTextState();
}

class _WikilinkTextState extends State<WikilinkText> {
  final _recognizers = <TapGestureRecognizer>[];

  static final _regex = RegExp(r'\[\[([^\[\]\n]+)\]\]');

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Alte Recognizer freigeben bevor neue gebaut werden.
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final theme = Theme.of(context);
    final linkStyle = (widget.style ?? theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary.withAlpha(120),
    );

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in _regex.allMatches(widget.text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: widget.text.substring(lastEnd, match.start)));
      }

      final title = match.group(1)!.trim();
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onWikilinkTap(title);
      _recognizers.add(recognizer);

      spans.add(TextSpan(
        text: '[[$title]]',
        style: linkStyle,
        recognizer: recognizer,
      ));

      lastEnd = match.end;
    }

    if (lastEnd < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: widget.style ?? theme.textTheme.bodyLarge,
        children: spans,
      ),
    );
  }
}
