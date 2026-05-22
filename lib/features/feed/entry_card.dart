// Datei: lib/features/feed/entry_card.dart
//
// ZWECK: Einzelne Eintragskarte im Feed. Zeigt Body-Vorschau, Zeitstempel und Tags.
// ABHÄNGIGKEITEN: Entry-Typ aus Drift, intl für Datumsformatierung.
// PHASE: 1 – Einfache Textvorschau. Phase 2+ fügt Medien-Vorschau, OCR-Snippet hinzu.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Entry ist eine von drift_dev generierte Datenklasse in database.g.dart,
// die via database.dart zugänglich ist.
import '../../data/db/database.dart';

/// Karte für einen einzelnen Eintrag im Feed.
///
/// WARUM kein InheritedWidget für den Entry?
/// Die Karte wird als `itemBuilder`-Callback in ListView.builder erzeugt.
/// Dort ist der Entry direkt verfügbar – kein Kontext-Passing nötig.
class EntryCard extends StatelessWidget {
  final Entry entry;

  const EntryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      // surfaceContainerLow: leicht vom Hintergrund abgehoben ohne harte Grenze.
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        // Phase 2: tippen öffnet die Detail-Ansicht.
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Optionaler Titel – nur anzeigen wenn vorhanden.
              if (entry.title != null && entry.title!.isNotEmpty) ...[
                Text(
                  entry.title!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],

              // Body-Vorschau: maximal 4 Zeilen.
              // Phase 2: Markdown-Rendering via flutter_markdown.
              Text(
                entry.body,
                style: theme.textTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Metadaten-Zeile: Zeitstempel + Pin-Indikator.
              Row(
                children: [
                  Text(
                    _formatTimestamp(entry.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (entry.pinned)
                    Icon(
                      Icons.push_pin,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formatiert den Zeitstempel abhängig vom Alter:
  /// - Heute: nur Uhrzeit ("14:30")
  /// - Diese Woche: Wochentag + Uhrzeit ("Mo. 14:30")
  /// - Älter: Datum ("12.05.2025")
  ///
  /// WARUM keine absolute Datumsanzeige für alles?
  /// Für kürzlich erfasste Einträge ist die relative Information
  /// ("heute", "Montag") für den Nutzer relevanter als das vollständige Datum.
  String _formatTimestamp(DateTime utcTime) {
    final local = utcTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(entryDay).inDays;

    if (diffDays == 0) {
      return DateFormat.Hm('de_DE').format(local);
    } else if (diffDays < 7) {
      return DateFormat('E., HH:mm', 'de_DE').format(local);
    } else {
      return DateFormat('dd.MM.yyyy', 'de_DE').format(local);
    }
  }
}
