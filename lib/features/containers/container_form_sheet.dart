// Datei: lib/features/containers/container_form_sheet.dart
//
// ZWECK: Bottom-Sheet zum Erstellen und Bearbeiten von Containern (Projekte/Bereiche).
//        Bietet Name, Beschreibung, Icon-Picker und Farb-Picker.
// ABHÄNGIGKEITEN: Keine externen Packages; nur Flutter Material.
// PHASE: 4 – Projekte & Bereiche CRUD.

import 'package:flutter/material.dart' hide Container;

import '../../data/db/database.dart';

// ── Icon-Palette ──────────────────────────────────────────────────────────────

/// Unterstützte Icons für Container (Name → IconData).
const _kIcons = <(String, IconData)>[
  ('folder', Icons.folder_outlined),
  ('article', Icons.article_outlined),
  ('book', Icons.menu_book_outlined),
  ('work', Icons.work_outline),
  ('home', Icons.home_outlined),
  ('star', Icons.star_outline),
  ('favorite', Icons.favorite_outline),
  ('fitness_center', Icons.fitness_center),
  ('sports_esports', Icons.sports_esports_outlined),
  ('coffee', Icons.local_cafe_outlined),
  ('music_note', Icons.music_note_outlined),
  ('code', Icons.code),
  ('camera_alt', Icons.camera_alt_outlined),
  ('school', Icons.school_outlined),
  ('travel', Icons.travel_explore),
  ('health', Icons.health_and_safety_outlined),
  ('calendar', Icons.calendar_month_outlined),
  ('edit', Icons.edit_outlined),
];

/// Gibt IconData für einen gespeicherten Icon-Namen zurück.
IconData containerIconData(String name) {
  for (final pair in _kIcons) {
    if (pair.$1 == name) return pair.$2;
  }
  return Icons.folder_outlined;
}

// ── Farb-Palette ──────────────────────────────────────────────────────────────

const _kColorHexes = <String>[
  '#6750A4', // Purple (Standard)
  '#0061A4', // Blue
  '#006E1C', // Green
  '#9C4146', // Crimson
  '#E07B39', // Orange
  '#006C51', // Teal
  '#515C6A', // Blue-grey
  '#7B3800', // Brown
  '#B5005B', // Pink
  '#1E6C00', // Forest
];

/// Parst einen '#RRGGBB'-String in eine Flutter-Color.
Color hexToColor(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return const Color(0xFF6750A4);
  }
}

// ── Bottom-Sheet-Funktion ─────────────────────────────────────────────────────

/// Öffnet das Formular als modales Bottom-Sheet.
///
/// [existing] – wenn gesetzt, werden die Felder vorausgefüllt (Edit-Modus).
/// Gibt null zurück wenn der Nutzer abbricht, sonst eine Map mit
/// 'name', 'description', 'icon', 'color'.
Future<Map<String, String>?> showContainerFormSheet(
  BuildContext context, {
  // ignore: avoid_shadowing_type_parameters
  Container? existing,
}) {
  return showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ContainerFormSheet(existing: existing),
  );
}

// ── Sheet-Widget ──────────────────────────────────────────────────────────────

class _ContainerFormSheet extends StatefulWidget {
  final Container? existing;

  const _ContainerFormSheet({this.existing});

  @override
  State<_ContainerFormSheet> createState() => _ContainerFormSheetState();
}

class _ContainerFormSheetState extends State<_ContainerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String _selectedIcon;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.existing?.description ?? '');
    _selectedIcon = widget.existing?.icon ?? _kIcons.first.$1;
    _selectedColor = widget.existing?.color ?? _kColorHexes.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop({
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'icon': _selectedIcon,
      'color': _selectedColor,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(
              isEdit ? 'Bearbeiten' : 'Neu erstellen',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            // Name
            TextFormField(
              controller: _nameCtrl,
              autofocus: !isEdit,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name erforderlich' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // Beschreibung
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Beschreibung (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),

            // Icon-Picker
            Text('Icon', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _kIcons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (name, icon) = _kIcons[i];
                  final selected = name == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? hexToColor(_selectedColor).withAlpha(40)
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? hexToColor(_selectedColor)
                              : theme.colorScheme.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: selected
                            ? hexToColor(_selectedColor)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Farb-Picker
            Text('Farbe', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: _kColorHexes.map((hex) {
                final color = hexToColor(hex);
                final selected = hex == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 10),
                    width: selected ? 36 : 30,
                    height: selected ? 36 : 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: selected
                          ? Border.all(
                              color: theme.colorScheme.outline,
                              width: 2.5,
                            )
                          : null,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withAlpha(100),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Speichern
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(isEdit ? 'Speichern' : 'Erstellen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
