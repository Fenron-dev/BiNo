// Datei: lib/features/capture/capture_sheet.dart
//
// ZWECK: Modales Bottom-Sheet für Schnelleingabe von Text, Bildern und Links.
//        Öffnet sich beim Tap auf den FAB; Tastatur erscheint automatisch.
// ABHÄNGIGKEITEN: captureControllerProvider, image_picker.
// MUSTER: ConsumerStatefulWidget mit CaptureController.
// PHASE: 2 – Text + Bilder + URL-Vorschau. Action-Leiste über dem Textfeld.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../data/db/tables/entries.dart';
import '../../services/url_metadata_service.dart';
import 'capture_controller.dart';

/// Quick-Capture Bottom-Sheet.
class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({super.key});

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet> {
  final TextEditingController _textController = TextEditingController();
  String _prevBody = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleSend(BuildContext context) async {
    final controller = ref.read(captureControllerProvider.notifier);
    final success = await controller.saveEntry(_textController.text);
    if (success && context.mounted) Navigator.of(context).pop();
  }

  Future<void> _insertWikilink() async {
    final workspaceId = ref.read(activeWorkspaceProvider);
    final entries =
        await ref.read(entryDaoProvider).getEntriesWithTitles(workspaceId);

    if (!mounted) return;

    final title = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _WikilinkPickerSheet(entries: entries),
    );

    if (title == null || !mounted) return;

    final pos = _textController.selection.isValid
        ? _textController.selection.baseOffset
        : _textController.text.length;
    final text = _textController.text;
    final insert = '[[$title]]';
    final newText = text.substring(0, pos) + insert + text.substring(pos);
    final newOffset = pos + insert.length;

    _textController.value = _textController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    _prevBody = newText;
    ref.read(captureControllerProvider.notifier).onBodyChanged(newText);
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureControllerProvider);
    final controller = ref.read(captureControllerProvider.notifier);
    final theme = Theme.of(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),

          if (captureState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                captureState.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),

          if (captureState.pendingImages.isNotEmpty)
            _ImagePreviewStrip(
              images: captureState.pendingImages
                  .map((f) => File(f.path))
                  .toList(),
              onRemove: (index) => controller.removePendingImage(index),
            ),

          if (captureState.isFetchingUrl)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Link wird geladen…'),
              ]),
            )
          else if (captureState.detectedUrl != null)
            _UrlPreviewCard(metadata: captureState.detectedUrl!),

          // Typ-Chips (Typ-Override)
          _TypeChips(
            selected: captureState.typeOverride,
            onChanged: (t) => controller.setTypeOverride(t),
          ),

          // Action-Leiste
          _ActionBar(
            onGallery: () => controller.pickImageFromGallery(),
            onCamera: () => controller.pickImageFromCamera(),
            onWikilink: _insertWikilink,
          ),

          // Eingabezeile
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    autofocus: true,
                    maxLines: null,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    onChanged: (text) {
                      // Auto-close [[ → [[]]
                      if (text.length > _prevBody.length &&
                          text.endsWith('[[')) {
                        final newText = '$text]]';
                        _textController.value =
                            _textController.value.copyWith(
                          text: newText,
                          selection: TextSelection.collapsed(
                              offset: text.length),
                        );
                        _prevBody = newText;
                        controller.onBodyChanged(newText);
                        return;
                      }
                      _prevBody = text;
                      controller.onBodyChanged(text);
                    },
                    decoration: InputDecoration(
                      hintText: 'Notiz eingeben… [[Wikilink]] #tag',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SendButton(
                  isSaving: captureState.isSaving,
                  onPressed: () => _handleSend(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typ-Chips ─────────────────────────────────────────────────────────────────

class _TypeChips extends StatelessWidget {
  final EntryType? selected;
  final void Function(EntryType?) onChanged;

  const _TypeChips({required this.selected, required this.onChanged});

  static const _types = <(EntryType, String, IconData)>[
    (EntryType.text, 'Text', Icons.text_fields_outlined),
    (EntryType.link, 'Link', Icons.link_outlined),
    (EntryType.image, 'Bild', Icons.image_outlined),
    (EntryType.audio, 'Audio', Icons.mic_none_outlined),
    (EntryType.mixed, 'Gemischt', Icons.layers_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        children: [
          // "Auto"-Chip
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: const Text('Auto'),
              selected: selected == null,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => onChanged(null),
            ),
          ),
          ..._types.map(
            (t) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                avatar: Icon(t.$3, size: 14),
                label: Text(t.$2),
                selected: selected == t.$1,
                visualDensity: VisualDensity.compact,
                onSelected: (v) => onChanged(v ? t.$1 : null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hilfsdwidgets ──────────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onWikilink;

  const _ActionBar({
    required this.onGallery,
    required this.onCamera,
    required this.onWikilink,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.photo_library_outlined,
            label: 'Galerie',
            onTap: onGallery,
          ),
          _ActionButton(
            icon: Icons.camera_alt_outlined,
            label: 'Kamera',
            onTap: onCamera,
          ),
          _ActionButton(
            icon: Icons.link,
            label: '[[Link]]',
            onTap: onWikilink,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviewStrip extends StatelessWidget {
  final List<File> images;
  final void Function(int index) onRemove;

  const _ImagePreviewStrip({required this.images, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(images[index],
                      width: 64, height: 64, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => onRemove(index),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UrlPreviewCard extends StatelessWidget {
  final UrlMetadata metadata;

  const _UrlPreviewCard({required this.metadata});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.hardEdge,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: theme.colorScheme.primary),
              if (metadata.imageUrl != null)
                Image.network(
                  metadata.imageUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        metadata.domain,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                      if (metadata.title != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          metadata.title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onPressed;

  const _SendButton({required this.isSaving, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: FilledButton(
        onPressed: isSaving ? null : onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.send),
      ),
    );
  }
}

// ── Wikilink-Picker ───────────────────────────────────────────────────────────

class _WikilinkPickerSheet extends StatefulWidget {
  final List<dynamic> entries; // Entry-Objekte mit id, title, body

  const _WikilinkPickerSheet({required this.entries});

  @override
  State<_WikilinkPickerSheet> createState() => _WikilinkPickerSheetState();
}

class _WikilinkPickerSheetState extends State<_WikilinkPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtered = widget.entries.where((e) {
      final title = e.title as String? ?? '';
      return _query.isEmpty ||
          title.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.link, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Wikilink einfügen',
                    style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Titel suchen oder neu eingeben…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Option: eingetippten Begriff als neuen Platzhalter einfügen
          if (_query.isNotEmpty &&
              !filtered.any(
                  (e) => (e.title as String?)?.toLowerCase() ==
                      _query.toLowerCase()))
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text('„$_query" als neuen Wikilink einfügen'),
              onTap: () => Navigator.of(context).pop(_query),
            ),
          // Bestehende Einträge
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final title = filtered[i].title as String;
                return ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: Text(title),
                  onTap: () => Navigator.of(context).pop(title),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
