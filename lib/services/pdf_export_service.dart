// Datei: lib/services/pdf_export_service.dart
//
// ZWECK: Erstellt ein PDF aus einem Eintrag und öffnet das Share-Sheet.
// ABHÄNGIGKEITEN: pdf, share_plus, path_provider, path, intl, database.dart.
// MUSTER: Service – zustandslos, nur Methoden.
// PHASE: 5 – Export.

import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/db/database.dart';

class PdfExportService {
  /// Erstellt ein PDF für [entry] und öffnet das Share-Sheet.
  Future<void> shareEntry({
    required Entry entry,
    required List<Tag> tags,
    required List<EntryProperty> properties,
    required List<PropertyDefinition> definitions,
  }) async {
    final bytes = await _buildPdf(
      entry: entry,
      tags: tags,
      properties: properties,
      definitions: definitions,
    );

    final rawName = (entry.title?.isNotEmpty == true)
        ? entry.title!
        : 'BiNo_Eintrag';
    final safeName = rawName
        .replaceAll(RegExp(r'[^\w\- ]'), '')
        .replaceAll(' ', '_');
    final trimmed = safeName.length > 40 ? safeName.substring(0, 40) : safeName;
    final filename = '${trimmed.isEmpty ? 'BiNo_Eintrag' : trimmed}.pdf';

    final tmpDir = await getTemporaryDirectory();
    final file = File(p.join(tmpDir.path, filename));
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf', name: filename)],
      subject: entry.title ?? 'BiNo-Eintrag',
    );
  }

  Future<List<int>> _buildPdf({
    required Entry entry,
    required List<Tag> tags,
    required List<EntryProperty> properties,
    required List<PropertyDefinition> definitions,
  }) async {
    final doc = pw.Document();
    final fmt = DateFormat('dd.MM.yyyy, HH:mm', 'de_DE');
    final dateStr = fmt.format(entry.createdAt.toLocal());

    // Farben
    const headerColor = PdfColors.blueGrey800;
    const metaColor = PdfColors.blueGrey400;
    const bodyColor = PdfColors.blueGrey900;
    const tagColor = PdfColors.teal700;

    final setProps = properties
        .map((prop) {
          final def = definitions.where((d) => d.id == prop.propertyId).firstOrNull;
          return (def != null && prop.value != null) ? (def, prop) : null;
        })
        .whereType<(PropertyDefinition, EntryProperty)>()
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'BiNo · Bit Notes',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: metaColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  dateStr,
                  style: pw.TextStyle(fontSize: 9, color: metaColor),
                ),
              ],
            ),
            pw.Divider(color: metaColor, thickness: 0.5),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (ctx) => [
          // Titel
          if (entry.title != null && entry.title!.isNotEmpty) ...[
            pw.Text(
              entry.title!,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: headerColor,
              ),
            ),
            pw.SizedBox(height: 8),
          ],

          // Status-Zeile (nur wenn nicht inbox)
          if (entry.status != 'inbox') ...[
            pw.Text(
              'Status: ${_localizedStatus(entry.status)}',
              style: pw.TextStyle(fontSize: 10, color: metaColor),
            ),
            pw.SizedBox(height: 8),
          ],

          // Body
          if (entry.body.isNotEmpty) ...[
            pw.Text(
              entry.body,
              style: pw.TextStyle(fontSize: 12, color: bodyColor),
            ),
            pw.SizedBox(height: 16),
          ],

          // Anmerkungen
          if (entry.notes != null && entry.notes!.isNotEmpty) ...[
            pw.Divider(color: metaColor, thickness: 0.5),
            pw.SizedBox(height: 8),
            pw.Text(
              'Anmerkungen',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: headerColor,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              entry.notes!,
              style: pw.TextStyle(
                fontSize: 11,
                color: bodyColor,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Properties
          if (setProps.isNotEmpty) ...[
            pw.Divider(color: metaColor, thickness: 0.5),
            pw.SizedBox(height: 8),
            pw.Text(
              'Eigenschaften',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: headerColor,
              ),
            ),
            pw.SizedBox(height: 6),
            ...setProps.map((pair) {
              final display = _decodeValue(pair.$2.value!, pair.$1.fieldType);
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 110,
                      child: pw.Text(
                        pair.$1.name,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: metaColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        display,
                        style: pw.TextStyle(fontSize: 10, color: bodyColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 16),
          ],

          // Tags
          if (tags.isNotEmpty) ...[
            pw.Divider(color: metaColor, thickness: 0.5),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags.map((tag) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: pw.BoxDecoration(
                    color: tagColor,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Text(
                    '#${tag.name}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  String _localizedStatus(String status) {
    switch (status) {
      case 'active':
        return 'Aktiv';
      case 'done':
        return 'Fertig';
      case 'archived':
        return 'Archiviert';
      default:
        return status;
    }
  }

  String _decodeValue(String raw, String fieldType) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is String) return decoded;
      if (decoded is num) return decoded.toString();
      if (decoded is bool) return decoded ? 'Ja' : 'Nein';
      if (decoded is List) return decoded.join(', ');
    } catch (_) {}
    return raw;
  }
}
