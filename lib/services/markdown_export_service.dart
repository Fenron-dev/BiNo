// Datei: lib/services/markdown_export_service.dart
//
// ZWECK: Formatiert einen Eintrag als Markdown-Text (YAML-Frontmatter + Body)
//        und öffnet das System-Share-Sheet als .md-Datei.
// ABHÄNGIGKEITEN: share_plus, intl, path_provider, path, database.dart.
// PHASE: 5 – Export.

import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/db/database.dart';

class MarkdownExportService {
  /// Formatiert [entry] als Markdown und öffnet das Share-Sheet mit einer .md-Datei.
  Future<void> shareEntry({
    required Entry entry,
    required List<Tag> tags,
    required List<EntryProperty> properties,
    required List<PropertyDefinition> definitions,
    required List<Attachment> attachments,
  }) async {
    final text = _format(
      entry: entry,
      tags: tags,
      properties: properties,
      definitions: definitions,
      attachments: attachments,
    );

    // Dateiname aus Titel ableiten und bereinigen.
    final rawName = (entry.title?.isNotEmpty == true)
        ? entry.title!
        : 'BiNo_Eintrag';
    final safeName = rawName
        .replaceAll(RegExp(r'[^\w\- ]'), '')
        .replaceAll(' ', '_');
    final trimmed = safeName.length > 40 ? safeName.substring(0, 40) : safeName;
    final filename = '${trimmed.isEmpty ? 'BiNo_Eintrag' : trimmed}.md';

    final tmpDir = await getTemporaryDirectory();
    final file = File(p.join(tmpDir.path, filename));
    await file.writeAsString(text);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/markdown', name: filename)],
      subject: entry.title ?? 'BiNo-Eintrag',
    );
  }

  String _format({
    required Entry entry,
    required List<Tag> tags,
    required List<EntryProperty> properties,
    required List<PropertyDefinition> definitions,
    required List<Attachment> attachments,
  }) {
    final buf = StringBuffer();
    final fmt = DateFormat('yyyy-MM-dd HH:mm', 'de_DE');

    // YAML-Frontmatter
    buf.writeln('---');
    buf.writeln('id: ${entry.id}');
    buf.writeln('erstellt: ${fmt.format(entry.createdAt.toLocal())}');
    buf.writeln('geändert: ${fmt.format(entry.updatedAt.toLocal())}');
    buf.writeln('typ: ${entry.type}');
    buf.writeln('status: ${entry.status}');
    if (entry.pinned) buf.writeln('angepinnt: true');
    if (tags.isNotEmpty) {
      buf.writeln('tags:');
      for (final tag in tags) {
        buf.writeln('  - ${tag.name}');
      }
    }
    if (entry.sourceUrl != null) buf.writeln('quelle: ${entry.sourceUrl}');
    buf.writeln('---');
    buf.writeln();

    // Titel
    if (entry.title != null && entry.title!.isNotEmpty) {
      buf.writeln('# ${entry.title}');
      buf.writeln();
    }

    // Body
    if (entry.body.isNotEmpty) {
      buf.writeln(entry.body);
      buf.writeln();
    }

    // Anmerkungen
    if (entry.notes != null && entry.notes!.isNotEmpty) {
      buf.writeln('## Anmerkungen');
      buf.writeln();
      buf.writeln(entry.notes!);
      buf.writeln();
    }

    // Properties (nur gesetzte Werte)
    final setProps = properties
        .map((p) {
          final def =
              definitions.where((d) => d.id == p.propertyId).firstOrNull;
          return (def != null && p.value != null) ? (def, p) : null;
        })
        .whereType<(PropertyDefinition, EntryProperty)>()
        .toList();

    if (setProps.isNotEmpty) {
      buf.writeln('## Eigenschaften');
      buf.writeln();
      for (final (def, prop) in setProps) {
        final display = _decodeValue(prop.value!, def.fieldType);
        buf.writeln('- **${def.name}**: $display');
      }
      buf.writeln();
    }

    // Anhänge
    if (attachments.isNotEmpty) {
      buf.writeln('## Anhänge');
      buf.writeln();
      for (final att in attachments) {
        buf.writeln('- ${att.filePath}');
      }
    }

    return buf.toString().trimRight();
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
