// Datei: lib/features/entry_detail/ai_enrich_sheet.dart
//
// ZWECK: Bottom-Sheet mit vier KI-Anreicherungs-Aktionen für einen Eintrag.
//        Ruft den AiEnrichService auf und speichert Ergebnisse als Properties
//        oder aktualisiert Felder des Eintrags direkt.
// ABHÄNGIGKEITEN: aiEnrichServiceProvider, aiSettingsServiceProvider,
//                 propertyDaoProvider, entryRepositoryProvider.
// PHASE: 5 – KI-Anreicherung.

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di.dart';
import '../../data/db/database.dart' hide Container;
import '../../data/db/tables/property_definitions.dart';

/// Öffnet das KI-Anreicherungs-Sheet für [entry] als modales Bottom-Sheet.
Future<void> showAiEnrichSheet(
  BuildContext context,
  WidgetRef ref,
  Entry entry,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AiEnrichSheet(entry: entry),
  );
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

class _AiEnrichSheet extends ConsumerStatefulWidget {
  final Entry entry;

  const _AiEnrichSheet({required this.entry});

  @override
  ConsumerState<_AiEnrichSheet> createState() => _AiEnrichSheetState();
}

class _AiEnrichSheetState extends ConsumerState<_AiEnrichSheet> {
  static const _uuid = Uuid();

  bool _loadingSummarize = false;
  bool _loadingTitle = false;
  bool _loadingTags = false;
  bool _loadingProps = false;

  // Baut den Eintrag-Inhalt als kompakten String für den Prompt.
  String get _content {
    final parts = <String>[];
    if (widget.entry.title != null && widget.entry.title!.isNotEmpty) {
      parts.add('Titel: ${widget.entry.title}');
    }
    if (widget.entry.body.isNotEmpty) parts.add(widget.entry.body);
    if (widget.entry.notes != null && widget.entry.notes!.isNotEmpty) {
      parts.add('Notizen: ${widget.entry.notes}');
    }
    return parts.join('\n\n');
  }

  // Prüft ob ein API-Key gesetzt ist und zeigt ggf. einen Hinweis-Dialog.
  Future<bool> _hasApiKey() async {
    final key = await ref.read(aiSettingsServiceProvider).getApiKey();
    if (key != null) return true;
    if (!mounted) return false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API-Key fehlt'),
        content: const Text(
          'Bitte trage deinen Anthropic-API-Key '
          'in den Einstellungen ein.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return false;
  }

  // Find-or-create einer Property-Definition und upsert des Werts.
  Future<void> _saveProperty({
    required String name,
    required String fieldType,
    required String jsonValue,
  }) async {
    final dao = ref.read(propertyDaoProvider);
    final workspaceId = ref.read(activeWorkspaceProvider);

    var def = await dao.findDefinitionByName(workspaceId, name);
    if (def == null) {
      final defId = _uuid.v4();
      await dao.insertDefinition(
        PropertyDefinitionsCompanion.insert(
          id: defId,
          workspaceId: Value(workspaceId),
          name: name,
          fieldType: fieldType,
        ),
      );
      def = await dao.findDefinitionByName(workspaceId, name);
    }
    if (def == null) return;

    final existing = await dao.findPropertyValue(widget.entry.id, def.id);
    if (existing != null) {
      await dao.updateProperty(existing.id, jsonValue);
    } else {
      await dao.insertProperty(
        EntryPropertiesCompanion.insert(
          id: _uuid.v4(),
          entryId: widget.entry.id,
          propertyId: def.id,
          value: Value(jsonValue),
        ),
      );
    }
  }

  // Generische Action-Methode: laden → Vorschau-Dialog → Speichern.
  Future<void> _run<T>({
    required void Function(bool) setLoading,
    required Future<T> Function() fetch,
    required Widget Function(T) buildPreview,
    required Future<void> Function(T) onAccept,
  }) async {
    if (!await _hasApiKey()) return;
    setLoading(true);
    try {
      final result = await fetch();
      if (!mounted) return;
      setLoading(false);

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ergebnis'),
          content: SingleChildScrollView(child: buildPreview(result)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Verwerfen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Übernehmen'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await onAccept(result);
        if (mounted) {
          Navigator.of(context).pop(); // Sheet schließen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gespeichert')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ── Aktionen ──────────────────────────────────────────────────────────────

  Future<void> _summarize() => _run<String>(
        setLoading: (v) => setState(() => _loadingSummarize = v),
        fetch: () => ref.read(aiEnrichServiceProvider).summarize(_content),
        buildPreview: (r) => Text(r),
        onAccept: (r) => _saveProperty(
          name: 'Zusammenfassung',
          fieldType: PropertyFieldType.text.name,
          jsonValue: jsonEncode(r),
        ),
      );

  Future<void> _generateTitle() => _run<String>(
        setLoading: (v) => setState(() => _loadingTitle = v),
        fetch: () =>
            ref.read(aiEnrichServiceProvider).generateTitle(_content),
        buildPreview: (r) =>
            Text(r, style: const TextStyle(fontWeight: FontWeight.bold)),
        onAccept: (r) => ref.read(entryRepositoryProvider).updateEntry(
              id: widget.entry.id,
              title: r.isEmpty ? null : r,
              body: widget.entry.body,
              notes: widget.entry.notes,
            ),
      );

  Future<void> _suggestTags() => _run<List<String>>(
        setLoading: (v) => setState(() => _loadingTags = v),
        fetch: () =>
            ref.read(aiEnrichServiceProvider).suggestTags(_content),
        buildPreview: (r) => Wrap(
          spacing: 8,
          runSpacing: 4,
          children: r
              .map((t) => Chip(
                    label: Text('#$t'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ))
              .toList(),
        ),
        onAccept: (r) => _saveProperty(
          name: 'KI-Tags',
          fieldType: PropertyFieldType.tags.name,
          jsonValue: jsonEncode(r),
        ),
      );

  Future<void> _extractProperties() => _run<Map<String, String>>(
        setLoading: (v) => setState(() => _loadingProps = v),
        fetch: () =>
            ref.read(aiEnrichServiceProvider).extractProperties(_content),
        buildPreview: (r) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: r.entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: '${e.key}: ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: e.value),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        onAccept: (r) async {
          for (final entry in r.entries) {
            await _saveProperty(
              name: entry.key,
              fieldType: PropertyFieldType.text.name,
              jsonValue: jsonEncode(entry.value),
            );
          }
        },
      );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: SizedBox(
              width: 40,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Titel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.auto_awesome,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Mit KI anreichern',
                    style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Aktionen
          _ActionTile(
            icon: Icons.summarize_outlined,
            title: 'Zusammenfassen',
            subtitle:
                'Generiert 1–3 Sätze als „Zusammenfassung"-Property',
            isLoading: _loadingSummarize,
            onTap: _summarize,
          ),
          _ActionTile(
            icon: Icons.title,
            title: 'Titel generieren',
            subtitle: 'Setzt den Eintragstitel (max. 60 Zeichen)',
            isLoading: _loadingTitle,
            onTap: _generateTitle,
          ),
          _ActionTile(
            icon: Icons.label_outline,
            title: 'Tags vorschlagen',
            subtitle:
                '3–5 Tags erkennen und als „KI-Tags"-Property speichern',
            isLoading: _loadingTags,
            onTap: _suggestTags,
          ),
          _ActionTile(
            icon: Icons.format_list_bulleted,
            title: 'Metadaten extrahieren',
            subtitle: 'Erkennt Autor, Datum, Ort u. a. als Properties',
            isLoading: _loadingProps,
            onTap: _extractProperties,
          ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Nutzt deinen eigenen Anthropic-API-Key. '
              'Daten werden direkt an die Anthropic-API gesendet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Aktions-Kachel ────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      enabled: !isLoading,
      onTap: isLoading ? null : onTap,
    );
  }
}
