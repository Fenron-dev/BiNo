// Datei: lib/features/capture/capture_sheet.dart
//
// ZWECK: Modales Bottom-Sheet für Schnelleingabe von Text, Bildern und Links.
//        Öffnet sich beim Tap auf den FAB; Tastatur erscheint automatisch.
// ABHÄNGIGKEITEN: captureControllerProvider, image_picker.
// MUSTER: ConsumerStatefulWidget mit CaptureController.
// PHASE: 2 – Text + Bilder + URL-Vorschau. Action-Leiste über dem Textfeld.

import 'dart:io';
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../data/db/database.dart' hide Container;
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
        await ref.read(entryDaoProvider).getRecentEntries(workspaceId);

    if (!mounted) return;

    // Dialog statt verschachteltem Bottom-Sheet – verhindert, dass
    // Navigator.pop() versehentlich das CaptureSheet schließt.
    final result = await showDialog<_WikilinkResult>(
      context: context,
      builder: (ctx) => _WikilinkPickerDialog(entries: entries),
    );

    if (result == null || !mounted) return;

    // Wenn der gewählte Eintrag noch keinen Titel hat, wird der angezeigte
    // Text als Titel gesetzt, damit der Wikilink später aufgelöst werden kann.
    if (result.entryId != null) {
      final entry = entries.firstWhere((e) => e.id == result.entryId,
          orElse: () => entries.first);
      if (entry.title == null || entry.title!.isEmpty) {
        await ref.read(entryDaoProvider).updateEntryFields(
              id: result.entryId!,
              title: result.text,
              body: entry.body,
              notes: entry.notes,
              updatedAt: DateTime.now().toUtc(),
            );
      }
    }

    final pos = _textController.selection.isValid
        ? _textController.selection.baseOffset
        : _textController.text.length;
    final text = _textController.text;
    final insert = '[[${result.text}]]';
    final newText = text.substring(0, pos) + insert + text.substring(pos);

    _textController.value = _textController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + insert.length),
    );
    ref.read(captureControllerProvider.notifier).onBodyChanged(newText);
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty || !mounted) return;

    final pos = _textController.selection.isValid
        ? _textController.selection.baseOffset
        : _textController.text.length;
    final current = _textController.text;
    final newText =
        current.substring(0, pos) + text.trim() + current.substring(pos);

    _textController.value = _textController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + text.trim().length),
    );
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

          // Typ-Chips (manueller Override)
          _TypeChips(
            selected: captureState.typeOverride,
            onChanged: (t) => controller.setTypeOverride(t),
          ),

          // Action-Leiste
          _ActionBar(
            onGallery: () => controller.pickImageFromGallery(),
            onCamera: () => controller.pickImageFromCamera(),
            onWikilink: _insertWikilink,
            onPaste: _pasteFromClipboard,
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
                    // TextInputFormatter für Auto-Close [[ → [[]]
                    // Zuverlässiger als onChanged auf Android, weil der
                    // Formatter auf IME-Ebene arbeitet und keinen Desync erzeugt.
                    inputFormatters: [_BracketAutoCloseFormatter()],
                    onChanged: (text) {
                      controller.onBodyChanged(_textController.text);
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

// ── TextInputFormatter: Auto-Close [[ ──────────────────────────────────────────

/// Fügt automatisch ]] nach [[ ein und positioniert den Cursor zwischen den Klammern.
/// Zuverlässiger als onChanged auf Android, weil der IME sofort das formatierte
/// Ergebnis erhält – kein Desync zwischen IME-Buffer und TextEditingController.
class _BracketAutoCloseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.endsWith('[[') && !oldValue.text.endsWith('[[')) {
      final newText = '${newValue.text}]]';
      return newValue.copyWith(
        text: newText,
        selection:
            TextSelection.collapsed(offset: newValue.text.length),
      );
    }
    return newValue;
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
          // "Auto"-Chip: kein Override, Typ wird automatisch erkannt
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

// ── Hilfswidgets ──────────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
        child: const SizedBox(width: 32, height: 4),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onWikilink;
  final VoidCallback onPaste;

  const _ActionBar({
    required this.onGallery,
    required this.onCamera,
    required this.onWikilink,
    required this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
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
            icon: Icons.content_paste_outlined,
            label: 'Einfügen',
            onTap: onPaste,
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
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            Icon(Icons.close, size: 14, color: Colors.white),
                      ),
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                    width: 4,
                    child: ColoredBox(
                        color: theme.colorScheme.primary)),
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

// ── Wikilink-Picker als Dialog ────────────────────────────────────────────────

class _WikilinkResult {
  final String text;
  final String? entryId;

  const _WikilinkResult(this.text, this.entryId);
}

class _WikilinkPickerDialog extends StatefulWidget {
  final List<Entry> entries;

  const _WikilinkPickerDialog({required this.entries});

  @override
  State<_WikilinkPickerDialog> createState() => _WikilinkPickerDialogState();
}

class _WikilinkPickerDialogState extends State<_WikilinkPickerDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Zeigt Titel wenn vorhanden, sonst die erste Zeile des Bodytexts.
  String _displayText(Entry e) {
    if (e.title?.isNotEmpty == true) return e.title!;
    final firstLine = e.body.split('\n').first.trim();
    return firstLine.isEmpty
        ? '(Leerer Eintrag)'
        : firstLine.substring(0, min(60, firstLine.length));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtered = widget.entries.where((e) {
      if (_query.isEmpty) return true;
      final haystack =
          '${e.title ?? ''} ${e.body}'.toLowerCase();
      return haystack.contains(_query.toLowerCase());
    }).toList();

    final queryIsExact = filtered.any(
      (e) => _displayText(e).toLowerCase() == _query.toLowerCase(),
    );

    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
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
                hintText: 'Eintrag suchen oder Titel eingeben…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Option: getippten Begriff als neuen Platzhalter verlinken
          if (_query.isNotEmpty && !queryIsExact)
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text('„$_query" als neuen Link einfügen'),
              subtitle: const Text('Noch kein Eintrag mit diesem Titel'),
              onTap: () => Navigator.of(context)
                  .pop(_WikilinkResult(_query, null)),
            ),
          // Bestehende Einträge
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: widget.entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Noch keine Einträge. Erstelle zuerst einige Notizen.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final entry = filtered[i];
                      final hasTitle = entry.title?.isNotEmpty == true;
                      return ListTile(
                        leading: Icon(
                          hasTitle
                              ? Icons.article_outlined
                              : Icons.notes_outlined,
                          color: hasTitle
                              ? null
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(_displayText(entry)),
                        subtitle: hasTitle
                            ? null
                            : const Text(
                                'Kein Titel – wird automatisch gesetzt'),
                        onTap: () => Navigator.of(context).pop(
                          _WikilinkResult(_displayText(entry), entry.id),
                        ),
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
