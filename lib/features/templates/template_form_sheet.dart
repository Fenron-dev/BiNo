// Datei: lib/features/templates/template_form_sheet.dart
//
// ZWECK: Bottom-Sheet zum Erstellen und Bearbeiten von Vorlagen (Templates).
// ABHÄNGIGKEITEN: templateDaoProvider, uuid.
// PHASE: 6 – Template-System.

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di.dart';
import '../../data/db/database.dart' hide Container;

/// Öffnet das Template-Formular als modales Bottom-Sheet.
Future<void> showTemplateFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Template? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TemplateFormSheet(existing: existing, ref: ref),
  );
}

class _TemplateFormSheet extends StatefulWidget {
  final Template? existing;
  final WidgetRef ref;

  const _TemplateFormSheet({this.existing, required this.ref});

  @override
  State<_TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends State<_TemplateFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _bodyCtrl;
  late String _icon;
  bool _saving = false;

  static const _kIcons = [
    '📋', '📝', '💡', '📚', '🎯', '🔖', '⭐', '🗒️',
    '📌', '🧠', '💼', '🎤', '🔗', '📷', '🎬', '🗓️',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _bodyCtrl = TextEditingController(text: widget.existing?.bodyTemplate ?? '');
    _icon = widget.existing?.icon ?? '📋';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    final dao = widget.ref.read(templateDaoProvider);

    if (widget.existing != null) {
      await dao.updateTemplate(
        TemplatesCompanion(
          id: Value(widget.existing!.id),
          name: Value(name),
          icon: Value(_icon),
          description: Value(_descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim()),
          bodyTemplate: Value(_bodyCtrl.text),
        ),
      );
    } else {
      await dao.insertTemplate(
        TemplatesCompanion.insert(
          id: const Uuid().v4(),
          name: name,
          icon: Value(_icon),
          description: Value(_descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim()),
          bodyTemplate: Value(_bodyCtrl.text),
        ),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Griff
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Titel
            Text(
              widget.existing == null ? 'Neue Vorlage' : 'Vorlage bearbeiten',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            // Icon-Auswahl
            Text('Icon', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kIcons.map((emoji) {
                final selected = emoji == _icon;
                return GestureDetector(
                  onTap: () => setState(() => _icon = emoji),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: selected
                          ? Border.all(
                              color: theme.colorScheme.primary, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Name
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'z. B. Meeting, Buchnotiz, Idee…',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),

            // Beschreibung
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Beschreibung (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            // Body-Template
            TextField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'Vorausgefüllter Text (optional)',
                hintText: '## Tagesordnung\n\n## Notizen\n\n## Nächste Schritte',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Speichern
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving || _nameCtrl.text.trim().isEmpty
                    ? null
                    : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Speichern'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
