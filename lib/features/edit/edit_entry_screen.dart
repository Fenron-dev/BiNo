// Datei: lib/features/edit/edit_entry_screen.dart
//
// ZWECK: Bearbeitungsmaske für einen bestehenden Eintrag.
//        Ermöglicht das Ändern von Titel, Body und Notizen sowie das
//        Verwalten von Properties (EAV-Schema, Obsidian-Style).
// ABHÄNGIGKEITEN: entryRepositoryProvider, propertyDaoProvider,
//                 activeWorkspaceProvider, go_router.
// PHASE: 3 – Edit-Screen und Properties-Panel.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:drift/drift.dart' show Value;

import '../../core/di.dart';
import '../../data/db/database.dart' hide Container;
import '../../data/db/tables/property_definitions.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

final _editEntryProvider = StreamProvider.autoDispose
    .family<Entry?, String>((ref, id) {
  return ref.watch(entryRepositoryProvider).watchEntryById(id);
});

final _definitionsProvider = StreamProvider.autoDispose
    .family<List<PropertyDefinition>, String>((ref, workspaceId) {
  return ref.watch(propertyDaoProvider).watchDefinitionsForWorkspace(workspaceId);
});

final _entryPropertiesProvider = StreamProvider.autoDispose
    .family<List<EntryProperty>, String>((ref, entryId) {
  return ref.watch(propertyDaoProvider).watchPropertiesForEntry(entryId);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class EditEntryScreen extends ConsumerStatefulWidget {
  final String entryId;

  const EditEntryScreen({super.key, required this.entryId});

  @override
  ConsumerState<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends ConsumerState<EditEntryScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _initFields(Entry entry) {
    if (_initialized) return;
    _titleCtrl.text = entry.title ?? '';
    _bodyCtrl.text = entry.body;
    _notesCtrl.text = entry.notes ?? '';
    _initialized = true;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await ref.read(entryRepositoryProvider).updateEntry(
      id: widget.entryId,
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      body: _bodyCtrl.text,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final entryAsync = ref.watch(_editEntryProvider(widget.entryId));

    return entryAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Eintrag nicht gefunden.')),
      ),
      data: (entry) {
        if (entry == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Eintrag nicht gefunden.')),
          );
        }
        _initFields(entry);
        return _EditView(
          entryId: widget.entryId,
          titleCtrl: _titleCtrl,
          bodyCtrl: _bodyCtrl,
          notesCtrl: _notesCtrl,
          isSaving: _isSaving,
          onSave: _save,
        );
      },
    );
  }
}

// ── Edit-Hauptansicht ─────────────────────────────────────────────────────────

class _EditView extends ConsumerWidget {
  final String entryId;
  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;
  final TextEditingController notesCtrl;
  final bool isSaving;
  final VoidCallback onSave;

  const _EditView({
    required this.entryId,
    required this.titleCtrl,
    required this.bodyCtrl,
    required this.notesCtrl,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bearbeiten'),
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: onSave,
              child: Text(
                'Speichern',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Titel ──────────────────────────────────────────────────────────
          TextField(
            controller: titleCtrl,
            decoration: InputDecoration(
              hintText: 'Titel hinzufügen...',
              border: InputBorder.none,
              hintStyle: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(80),
              ),
            ),
            style: theme.textTheme.headlineSmall,
            textCapitalization: TextCapitalization.sentences,
          ),

          // ── Body ───────────────────────────────────────────────────────────
          TextField(
            controller: bodyCtrl,
            decoration: InputDecoration(
              hintText: 'Inhalt...',
              border: InputBorder.none,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(80),
              ),
            ),
            style: theme.textTheme.bodyLarge,
            maxLines: null,
            minLines: 5,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
          ),

          const SizedBox(height: 8),

          // ── Notizen (kollabierbar) ─────────────────────────────────────────
          _NotesSection(notesCtrl: notesCtrl),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // ── Properties ─────────────────────────────────────────────────────
          _PropertiesSection(
            entryId: entryId,
            workspaceId: workspaceId,
          ),

          // Platz für die Tastatur
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

// ── Notizen-Sektion ───────────────────────────────────────────────────────────

class _NotesSection extends StatefulWidget {
  final TextEditingController notesCtrl;

  const _NotesSection({required this.notesCtrl});

  @override
  State<_NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<_NotesSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.notesCtrl.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Persönliche Anmerkungen',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextField(
              controller: widget.notesCtrl,
              decoration: InputDecoration(
                hintText: 'Eigene Gedanken, Zusammenfassungen...',
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withAlpha(160),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: null,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
            ),
          ),
      ],
    );
  }
}

// ── Properties-Sektion ────────────────────────────────────────────────────────

class _PropertiesSection extends ConsumerWidget {
  final String entryId;
  final String workspaceId;

  const _PropertiesSection({
    required this.entryId,
    required this.workspaceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final defsAsync = ref.watch(_definitionsProvider(workspaceId));
    final propsAsync = ref.watch(_entryPropertiesProvider(entryId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Eigenschaften', style: theme.textTheme.titleSmall),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddDefinitionDialog(context, ref),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Neu'),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        defsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (defs) {
            if (defs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Noch keine Eigenschaften definiert. Tippe auf „Neu" um eine hinzuzufügen.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            return propsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (props) => Column(
                children: defs.map((def) {
                  final existing = props
                      .where((p) => p.propertyId == def.id)
                      .firstOrNull;
                  return _PropertyField(
                    definition: def,
                    entryId: entryId,
                    existingProperty: existing,
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAddDefinitionDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) =>
          _AddPropertyDefinitionDialog(workspaceId: workspaceId),
    );
  }
}

// ── Property-Feld ─────────────────────────────────────────────────────────────

class _PropertyField extends ConsumerWidget {
  final PropertyDefinition definition;
  final String entryId;
  final EntryProperty? existingProperty;

  const _PropertyField({
    required this.definition,
    required this.entryId,
    required this.existingProperty,
  });

  PropertyFieldType get _type {
    try {
      return PropertyFieldType.values.byName(definition.fieldType);
    } catch (_) {
      return PropertyFieldType.text;
    }
  }

  Future<void> _setValue(WidgetRef ref, String? jsonValue) async {
    final dao = ref.read(propertyDaoProvider);
    if (existingProperty != null) {
      if (jsonValue == null) {
        await dao.deleteProperty(existingProperty!.id);
      } else {
        await dao.updateProperty(existingProperty!.id, jsonValue);
      }
    } else if (jsonValue != null) {
      await dao.insertProperty(
        EntryPropertiesCompanion.insert(
          id: const Uuid().v4(),
          entryId: entryId,
          propertyId: definition.id,
          value: Value(jsonValue),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              definition.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildInput(context, ref, theme)),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context, WidgetRef ref, ThemeData theme) {
    final currentValue = existingProperty?.value;

    switch (_type) {
      // ── Ja/Nein ────────────────────────────────────────────────────────────
      case PropertyFieldType.boolean:
        final val = currentValue == 'true';
        return Align(
          alignment: Alignment.centerLeft,
          child: Switch(
            value: val,
            onChanged: (v) => _setValue(ref, v.toString()),
          ),
        );

      // ── Bewertung ──────────────────────────────────────────────────────────
      case PropertyFieldType.rating:
        final rating = int.tryParse(currentValue ?? '0') ?? 0;
        return Row(
          children: List.generate(5, (i) {
            return GestureDetector(
              onTap: () => _setValue(
                ref,
                // Nochmal auf denselben Stern tippen → zurücksetzen
                i + 1 == rating ? '0' : '${i + 1}',
              ),
              child: Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 28,
                color: i < rating
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            );
          }),
        );

      // ── Datum ──────────────────────────────────────────────────────────────
      case PropertyFieldType.date:
        String? dateStr;
        try {
          if (currentValue != null) {
            dateStr = jsonDecode(currentValue) as String?;
          }
        } catch (_) {}
        return InkWell(
          onTap: () async {
            final now = DateTime.now();
            final initial =
                dateStr != null ? DateTime.tryParse(dateStr) ?? now : now;
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              final s =
                  '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              await _setValue(ref, jsonEncode(s));
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  dateStr ?? 'Datum wählen...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: dateStr != null
                        ? null
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );

      // ── Auswahl (Einfach) ─────────────────────────────────────────────────
      case PropertyFieldType.select:
        final options = _parseOptions();
        String? current;
        try {
          if (currentValue != null) current = jsonDecode(currentValue) as String?;
        } catch (_) {}
        return DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: options.contains(current) ? current : null,
          hint: const Text('Auswählen...'),
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('— keine Auswahl —'),
            ),
            ...options.map(
              (o) => DropdownMenuItem<String>(value: o, child: Text(o)),
            ),
          ],
          onChanged: (v) => _setValue(ref, v != null ? jsonEncode(v) : null),
        );

      // ── Auswahl (Mehrfach) ────────────────────────────────────────────────
      case PropertyFieldType.multiselect:
        final options = _parseOptions();
        List<String> selected = [];
        try {
          if (currentValue != null) {
            selected = List<String>.from(jsonDecode(currentValue));
          }
        } catch (_) {}
        return Wrap(
          spacing: 6,
          runSpacing: 4,
          children: options.map((o) {
            final isSelected = selected.contains(o);
            return FilterChip(
              label: Text(o),
              selected: isSelected,
              onSelected: (v) {
                final updated = List<String>.from(selected);
                v ? updated.add(o) : updated.remove(o);
                _setValue(ref, updated.isEmpty ? null : jsonEncode(updated));
              },
            );
          }).toList(),
        );

      // ── Tags (kommagetrennt) ──────────────────────────────────────────────
      case PropertyFieldType.tags:
        String initial = '';
        try {
          if (currentValue != null) {
            final list = List<String>.from(jsonDecode(currentValue));
            initial = list.join(', ');
          }
        } catch (_) {}
        return _FocusBlurTextField(
          initialValue: initial,
          hint: 'Tag1, Tag2, Tag3...',
          onCommit: (v) {
            final tags = v
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();
            _setValue(ref, tags.isEmpty ? null : jsonEncode(tags));
          },
        );

      // ── Zahl ───────────────────────────────────────────────────────────────
      case PropertyFieldType.number:
        return _FocusBlurTextField(
          initialValue: currentValue,
          hint: '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onCommit: (v) => _setValue(ref, v.isEmpty ? null : v),
        );

      // ── Text / URL / Link ──────────────────────────────────────────────────
      case PropertyFieldType.text:
      case PropertyFieldType.url:
      case PropertyFieldType.link:
        String? initial;
        try {
          if (currentValue != null) initial = jsonDecode(currentValue) as String?;
        } catch (_) {
          initial = currentValue;
        }
        return _FocusBlurTextField(
          initialValue: initial,
          hint: _type == PropertyFieldType.url
              ? 'https://...'
              : _type == PropertyFieldType.link
                  ? 'URL oder Eintrags-ID...'
                  : 'Wert eingeben...',
          keyboardType: (_type == PropertyFieldType.url ||
                  _type == PropertyFieldType.link)
              ? TextInputType.url
              : TextInputType.text,
          onCommit: (v) => _setValue(ref, v.isEmpty ? null : jsonEncode(v)),
        );
    }
  }

  List<String> _parseOptions() {
    try {
      if (definition.options != null) {
        return List<String>.from(jsonDecode(definition.options!));
      }
    } catch (_) {}
    return [];
  }
}

// ── Textfeld mit Speichern bei Fokusverlust ───────────────────────────────────

/// TextField das seinen Wert erst bei `onSubmitted` oder Fokusverlust
/// persistiert – verhindert einen DB-Write pro Tastendruck.
class _FocusBlurTextField extends StatefulWidget {
  final String? initialValue;
  final String hint;
  final TextInputType keyboardType;
  final ValueChanged<String> onCommit;

  const _FocusBlurTextField({
    this.initialValue,
    required this.hint,
    this.keyboardType = TextInputType.text,
    required this.onCommit,
  });

  @override
  State<_FocusBlurTextField> createState() => _FocusBlurTextFieldState();
}

class _FocusBlurTextFieldState extends State<_FocusBlurTextField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue ?? '');
    _focus = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_FocusBlurTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Externe Aktualisierung (z. B. durch Stream) nur übernehmen wenn
    // das Feld nicht fokussiert ist – verhindert Überschreiben laufender Eingaben.
    if (!_focus.hasFocus && oldWidget.initialValue != widget.initialValue) {
      _ctrl.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) widget.onCommit(_ctrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      decoration: InputDecoration(
        hintText: widget.hint,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: widget.keyboardType,
      onSubmitted: (_) => widget.onCommit(_ctrl.text),
    );
  }
}

// ── Dialog: Neue Property-Definition ─────────────────────────────────────────

class _AddPropertyDefinitionDialog extends ConsumerStatefulWidget {
  final String workspaceId;

  const _AddPropertyDefinitionDialog({required this.workspaceId});

  @override
  ConsumerState<_AddPropertyDefinitionDialog> createState() =>
      _AddPropertyDefinitionDialogState();
}

class _AddPropertyDefinitionDialogState
    extends ConsumerState<_AddPropertyDefinitionDialog> {
  final _nameCtrl = TextEditingController();
  final _optionsCtrl = TextEditingController();
  PropertyFieldType _type = PropertyFieldType.text;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _optionsCtrl.dispose();
    super.dispose();
  }

  bool get _needsOptions =>
      _type == PropertyFieldType.select ||
      _type == PropertyFieldType.multiselect;

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);

    String? optionsJson;
    if (_needsOptions && _optionsCtrl.text.isNotEmpty) {
      final opts = _optionsCtrl.text
          .split(',')
          .map((o) => o.trim())
          .where((o) => o.isNotEmpty)
          .toList();
      if (opts.isNotEmpty) optionsJson = jsonEncode(opts);
    }

    await ref.read(propertyDaoProvider).insertDefinition(
          PropertyDefinitionsCompanion.insert(
            id: const Uuid().v4(),
            workspaceId: Value(widget.workspaceId),
            name: name,
            fieldType: _type.name,
            options: Value(optionsJson),
          ),
        );

    if (mounted) Navigator.of(context).pop();
  }

  String _typeName(PropertyFieldType t) {
    switch (t) {
      case PropertyFieldType.text:
        return 'Text';
      case PropertyFieldType.number:
        return 'Zahl';
      case PropertyFieldType.date:
        return 'Datum';
      case PropertyFieldType.boolean:
        return 'Ja / Nein';
      case PropertyFieldType.url:
        return 'URL';
      case PropertyFieldType.tags:
        return 'Tags';
      case PropertyFieldType.link:
        return 'Link';
      case PropertyFieldType.select:
        return 'Auswahl (Einfach)';
      case PropertyFieldType.multiselect:
        return 'Auswahl (Mehrfach)';
      case PropertyFieldType.rating:
        return 'Bewertung (1–5)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neue Eigenschaft'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'z. B. Quelle, Status, Bewertung',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PropertyFieldType>(
              // ignore: deprecated_member_use
              value: _type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Typ'),
              items: PropertyFieldType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(_typeName(t)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            if (_needsOptions) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _optionsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Optionen',
                  hintText: 'Option A, Option B, Option C',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _create,
          child: const Text('Erstellen'),
        ),
      ],
    );
  }
}
