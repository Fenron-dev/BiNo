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

import '../../services/url_metadata_service.dart';
import 'capture_controller.dart';

/// Quick-Capture Bottom-Sheet.
///
/// WARUM ConsumerStatefulWidget?
/// TextEditingController muss in dispose() freigegeben werden, und wir
/// brauchen Zugriff auf den captureControllerProvider.
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

    // context.mounted verhindert Zugriff nach async-Lücke falls Widget entfernt.
    if (success && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureControllerProvider);
    final controller = ref.read(captureControllerProvider.notifier);
    final theme = Theme.of(context);

    // MediaQuery.viewInsets.bottom: Höhe der Bildschirmtastatur.
    // Padding verschiebt das Sheet nach oben, sodass das Textfeld sichtbar bleibt.
    // Funktioniert zusammen mit isScrollControlled: true im showModalBottomSheet-Aufruf.
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),

          // Fehlermeldung – nur sichtbar wenn ein Fehler vorliegt.
          if (captureState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                captureState.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),

          // Bild-Vorschaustreifen – nur wenn Bilder ausgewählt sind.
          if (captureState.pendingImages.isNotEmpty)
            _ImagePreviewStrip(
              images: captureState.pendingImages
                  .map((f) => File(f.path))
                  .toList(),
              onRemove: (index) => controller.removePendingImage(index),
            ),

          // URL-Vorschaukarte – nur wenn eine URL erkannt wurde.
          if (captureState.isFetchingUrl)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Link wird geladen…'),
                ],
              ),
            )
          else if (captureState.detectedUrl != null)
            _UrlPreviewCard(metadata: captureState.detectedUrl!),

          // Horizontale Action-Leiste: Foto, Kamera, (Audio via Long-Press).
          _ActionBar(
            onGallery: () => controller.pickImageFromGallery(),
            onCamera: () => controller.pickImageFromCamera(),
          ),

          // Eingabezeile: Textfeld + Senden-Button.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    // autofocus: Tastatur öffnet sich sofort beim Sheet-Öffnen.
                    autofocus: true,
                    maxLines: null,
                    minLines: 1,
                    // TextInputAction.newline: Enter fügt Zeilenumbruch ein.
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    onChanged: (text) => controller.onBodyChanged(text),
                    decoration: InputDecoration(
                      hintText: 'Notiz eingeben…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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

// ── Hilfsdwidgets ──────────────────────────────────────────────────────────────

/// Drag-Handle oben am Sheet (Material 3 Standard).
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

/// Horizontale Action-Leiste mit Foto- und Kamera-Schaltflächen.
class _ActionBar extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _ActionBar({required this.onGallery, required this.onCamera});

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
        ],
      ),
    );
  }
}

/// Einzelne Action-Schaltfläche in der Leiste.
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
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontaler Streifen mit Bildvorschau-Thumbnails.
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
                  child: Image.file(
                    images[index],
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                // Löschen-Button oben rechts auf dem Thumbnail.
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
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
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

/// Vorschaukarte für eine erkannte URL mit Open-Graph-Daten.
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
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Farbiger linker Streifen als visueller Anker für Links.
              Container(
                width: 4,
                color: theme.colorScheme.primary,
              ),
              // Vorschaubild – nur wenn vorhanden.
              if (metadata.imageUrl != null)
                Image.network(
                  metadata.imageUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              // Titel und Domain.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        metadata.domain,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (metadata.title != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          metadata.title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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

/// Runder Senden-Button – deaktiviert während des Speicherns.
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
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send),
      ),
    );
  }
}
