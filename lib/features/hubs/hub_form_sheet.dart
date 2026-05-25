// Datei: lib/features/hubs/hub_form_sheet.dart
//
// ZWECK: Modal-BottomSheet zum Erstellen und Bearbeiten von Hub-Tabs.
//        Enthält Name/Icon/Farbe-Felder und einen Filter-Builder
//        (Tags, Eintragstypen, Status).
// ABHÄNGIGKEITEN: containerDaoProvider, tagDaoProvider, FilterDefinition.

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' hide Container;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di.dart';
import '../../data/db/database.dart';
import '../../domain/filters/filter_definition.dart';

/// Öffnet das Hub-Form-Sheet und gibt true zurück, wenn gespeichert wurde.
Future<bool> showHubFormSheet(
  BuildContext context, {
  Container? existing,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => HubFormSheet(existing: existing),
  );
  return result == true;
}

/// Formular für einen Hub-Tab.
class HubFormSheet extends ConsumerStatefulWidget {
  final Container? existing;

  const HubFormSheet({super.key, this.existing});

  @override
  ConsumerState<HubFormSheet> createState() => _HubFormSheetState();
}

class _HubFormSheetState extends ConsumerState<HubFormSheet> {
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedIcon = 'bookmarks';
  String _selectedColor = '#6750A4';

  // Filter-Zustand
  final Set<String> _selectedTags = {};
  final Set<String> _selectedTypes = {};
  final Set<String> _selectedStatuses = {};

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final hub = widget.existing;
    if (hub != null) {
      _nameCtrl.text = hub.name;
      _selectedIcon = hub.icon;
      _selectedColor = hub.color;
      if (hub.filterJson != null) {
        final filter = FilterDefinition.fromJsonString(hub.filterJson!);
        _selectedTags.addAll(filter.tagsAny);
        _selectedTypes.addAll(filter.typeIn);
        _selectedStatuses.addAll(filter.statusIn);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  FilterDefinition _buildFilter() => FilterDefinition(
        tagsAny: _selectedTags.toList(),
        typeIn: _selectedTypes.toList(),
        statusIn: _selectedStatuses.toList(),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final filter = _buildFilter();
    final filterJson = filter.isEmpty ? null : filter.toJsonString();
    final dao = ref.read(containerDaoProvider);

    if (widget.existing == null) {
      await dao.insertContainer(
        ContainersCompanion.insert(
          id: const Uuid().v4(),
          kind: 'hub',
          name: _nameCtrl.text.trim(),
          icon: Value(_selectedIcon),
          color: Value(_selectedColor),
          filterJson: Value(filterJson),
        ),
      );
    } else {
      await dao.updateContainerFull(
        id: widget.existing!.id,
        name: _nameCtrl.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        filterJson: filterJson,
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final allTagsAsync =
        ref.watch(_allTagsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle ──────────────────────────────────────────────────
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const SizedBox(width: 36, height: 4),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                widget.existing == null ? 'Hub-Tab erstellen' : 'Hub-Tab bearbeiten',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),

              // ── Name ────────────────────────────────────────────────────
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'z.B. Bücher, Inbox, Ideen …',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name darf nicht leer sein' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // ── Icon-Auswahl ─────────────────────────────────────────────
              _SectionLabel('Icon'),
              _IconPicker(
                selected: _selectedIcon,
                onChanged: (v) => setState(() => _selectedIcon = v),
              ),
              const SizedBox(height: 16),

              // ── Farb-Auswahl ─────────────────────────────────────────────
              _SectionLabel('Akzentfarbe'),
              _ColorPicker(
                selected: _selectedColor,
                onChanged: (v) => setState(() => _selectedColor = v),
              ),
              const SizedBox(height: 20),

              // ── Filter: Tags ─────────────────────────────────────────────
              _SectionLabel('Filter: Tags (mind. einer)'),
              const SizedBox(height: 4),
              allTagsAsync.when(
                loading: () => const SizedBox(
                  height: 36,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, __) => const Text('Tags konnten nicht geladen werden.'),
                data: (tags) {
                  if (tags.isEmpty) {
                    return Text(
                      'Noch keine Tags vorhanden. Erstelle Einträge mit #tag.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    );
                  }
                  return Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags
                        .map(
                          (tag) => FilterChip(
                            label: Text('#${tag.name}'),
                            selected: _selectedTags.contains(tag.name),
                            onSelected: (v) => setState(() {
                              if (v) {
                                _selectedTags.add(tag.name);
                              } else {
                                _selectedTags.remove(tag.name);
                              }
                            }),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Filter: Typen ────────────────────────────────────────────
              _SectionLabel('Filter: Eintragstypen'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _kTypes.map((t) {
                  return FilterChip(
                    avatar: Icon(t.$3, size: 16),
                    label: Text(t.$2),
                    selected: _selectedTypes.contains(t.$1),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedTypes.add(t.$1);
                      } else {
                        _selectedTypes.remove(t.$1);
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ── Filter: Status ───────────────────────────────────────────
              _SectionLabel('Filter: Status'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _kStatuses.map((s) {
                  return FilterChip(
                    label: Text(s.$2),
                    selected: _selectedStatuses.contains(s.$1),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedStatuses.add(s.$1);
                      } else {
                        _selectedStatuses.remove(s.$1);
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              if (_selectedTags.isEmpty && _selectedTypes.isEmpty && _selectedStatuses.isEmpty)
                Text(
                  'Kein Filter gesetzt → Hub zeigt alle Einträge.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              const SizedBox(height: 24),

              // ── Speichern-Button ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(widget.existing == null ? 'Erstellen' : 'Speichern'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Icon-Picker ────────────────────────────────────────────────────────────────

class _IconPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _IconPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: kHubIconOptions.map((entry) {
        final isSelected = selected == entry.$1;
        final colorScheme = Theme.of(context).colorScheme;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(entry.$1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : null,
            ),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                entry.$2,
                size: 20,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Farb-Picker ────────────────────────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ColorPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kColorOptions.map((hex) {
        final color = Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
        final isSelected = selected == hex;
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onChanged(hex),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
            ),
            child: SizedBox(
              width: 32,
              height: 32,
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Hilfs-Widget ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final _allTagsProvider = StreamProvider((ref) {
  return ref.watch(tagDaoProvider).watchAllTags();
});

// ── Konstanten ────────────────────────────────────────────────────────────────

// (name, label, icon)
const _kTypes = [
  ('text', 'Text', Icons.notes),
  ('link', 'Link', Icons.link),
  ('image', 'Bild', Icons.image_outlined),
  ('audio', 'Audio', Icons.mic_outlined),
  ('mixed', 'Gemischt', Icons.auto_awesome_outlined),
];

// (value, label)
const _kStatuses = [
  ('inbox', 'Inbox'),
  ('active', 'Aktiv'),
  ('done', 'Fertig'),
  ('archived', 'Archiviert'),
];

// (name, iconData) – öffentlich, damit AppShell + HubScreen dieselbe Map nutzen.
const kHubIconOptions = [
  ('bookmarks', Icons.bookmarks),
  ('bookmark', Icons.bookmark),
  ('menu_book', Icons.menu_book),
  ('label', Icons.label),
  ('star', Icons.star),
  ('favorite', Icons.favorite),
  ('link', Icons.link),
  ('image', Icons.image),
  ('mic', Icons.mic),
  ('note', Icons.note),
  ('idea', Icons.lightbulb),
  ('todo', Icons.checklist),
  ('inbox', Icons.inbox),
  ('archive', Icons.archive),
  ('folder', Icons.folder),
  ('work', Icons.work),
  ('home', Icons.home),
  ('school', Icons.school),
  ('code', Icons.code),
  ('travel', Icons.flight),
  ('music', Icons.music_note),
  ('movie', Icons.movie),
  ('food', Icons.restaurant),
  ('health', Icons.health_and_safety),
  ('shopping', Icons.shopping_bag),
  ('fitness', Icons.fitness_center),
];

/// Icon-Name → IconData Lookup für alle Hub-bezogenen Widgets.
const kHubIconMap = <String, IconData>{
  'bookmarks': Icons.bookmarks,
  'bookmark': Icons.bookmark,
  'menu_book': Icons.menu_book,
  'label': Icons.label,
  'star': Icons.star,
  'favorite': Icons.favorite,
  'link': Icons.link,
  'image': Icons.image,
  'mic': Icons.mic,
  'note': Icons.note,
  'idea': Icons.lightbulb,
  'todo': Icons.checklist,
  'inbox': Icons.inbox,
  'archive': Icons.archive,
  'folder': Icons.folder,
  'work': Icons.work,
  'home': Icons.home,
  'school': Icons.school,
  'code': Icons.code,
  'travel': Icons.flight,
  'music': Icons.music_note,
  'movie': Icons.movie,
  'food': Icons.restaurant,
  'health': Icons.health_and_safety,
  'shopping': Icons.shopping_bag,
  'fitness': Icons.fitness_center,
};

const _kColorOptions = [
  '#6750A4', // Material Primary
  '#B5264C', // Rot
  '#006874', // Teal
  '#386A20', // Grün
  '#A24C00', // Orange
  '#1B6CA8', // Blau
  '#7B5800', // Gelb-Braun
  '#984061', // Pink
  '#4A6741', // Salbei
  '#625B71', // Grau-Lila
  '#1A1C1E', // Fast Schwarz
];
