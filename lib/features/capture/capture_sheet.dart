// Datei: lib/features/capture/capture_sheet.dart
//
// ZWECK: Modales Bottom-Sheet für die Schnelleingabe von Text-Notizen.
//        Öffnet sich beim Tap auf den FAB; Tastatur erscheint automatisch.
// ABHÄNGIGKEITEN: captureControllerProvider.
// PHASE: 1 – Nur Text + Senden. Phase 2 fügt die horizontale Action-Button-
//        Leiste (Foto, Audio, URL, Tag) über dem Textfeld hinzu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capture_controller.dart';

/// Quick-Capture Bottom-Sheet.
///
/// WARUM ConsumerStatefulWidget?
/// Wir brauchen einen TextEditingController (wird in dispose() freigegeben)
/// und müssen auf den captureControllerProvider reagieren.
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

  /// Speichert den Eintrag und schließt das Sheet bei Erfolg.
  Future<void> _handleSend(BuildContext context) async {
    final controller = ref.read(captureControllerProvider.notifier);
    final success = await controller.saveEntry(_textController.text);

    // context.mounted: verhindert Zugriff auf BuildContext nach async-Lücke
    // wenn das Widget zwischenzeitlich aus dem Baum entfernt wurde.
    if (success && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureControllerProvider);
    final theme = Theme.of(context);

    // MediaQuery.viewInsets.bottom: Höhe der eingeblendeten Bildschirmtastatur.
    // Durch Padding um diesen Wert wird das Sheet nach oben verschoben,
    // sodass das Textfeld nicht hinter der Tastatur verborgen liegt.
    // Funktioniert zusammen mit isScrollControlled: true in showModalBottomSheet.
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Column(
        // mainAxisSize.min: Sheet passt sich der Inhaltshöhe an.
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

          // Phase 2: Hier kommt die horizontale Action-Button-Leiste.

          // Eingabezeile: Textfeld + Senden-Button.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    // autofocus: Tastatur öffnet sich sofort beim Sheet-Öffnen.
                    autofocus: true,
                    // maxLines: null + minLines: 1 = wächst dynamisch bis zur Grenze.
                    maxLines: null,
                    minLines: 1,
                    // TextInputAction.newline: Enter-Taste fügt Zeilenumbruch ein
                    // statt das Formular abzuschicken (Nutzer tippt auf Senden-Button).
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
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

/// Drag-Handle oben am Sheet (Material 3 Standard).
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
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
