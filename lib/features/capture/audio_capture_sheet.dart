// Datei: lib/features/capture/audio_capture_sheet.dart
//
// ZWECK: Bottom-Sheet für Audio-Aufnahmen. Wird via Long-Press auf den FAB
//        geöffnet. Zeigt Aufnahme-Timer und STT-Transkription in Echtzeit.
// ABHÄNGIGKEITEN: record, speech_to_text, attachmentRepositoryProvider,
//                 entryRepositoryProvider, sttServiceProvider.
// MUSTER: ConsumerStatefulWidget, dart:async Timer für Aufnahmedauer.
// PHASE: 2 – Audio-Capture mit On-Device STT.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/di.dart';
import '../../data/db/tables/entries.dart';

/// Bottom-Sheet für Audio-Aufnahme + automatische Transkription.
///
/// WARUM eigenes Sheet statt Integration in CaptureSheet?
/// Audio-Aufnahme hat einen eigenen Lebenszyks (Start/Stop/Abbrechen)
/// und braucht eine dedizierte UI mit Timer und Wellenform-Platzhalter.
/// Die Trennung hält CaptureSheet übersichtlich.
class AudioCaptureSheet extends ConsumerStatefulWidget {
  const AudioCaptureSheet({super.key});

  @override
  ConsumerState<AudioCaptureSheet> createState() => _AudioCaptureSheetState();
}

class _AudioCaptureSheetState extends ConsumerState<AudioCaptureSheet> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;

  /// Laufende Aufnahmedauer in Sekunden.
  int _seconds = 0;

  /// Ob die Aufnahme gerade läuft.
  bool _isRecording = false;

  /// Pfad zur aktuell aufgenommenen Datei.
  String? _recordingPath;

  /// Vom STT erkannter Text (wird während der Aufnahme aktualisiert).
  String _transcription = '';

  /// true während der Eintrag gespeichert wird.
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // addPostFrameCallback: Der Android-Berechtigungsdialog kann erst
    // angezeigt werden, wenn das Widget vollständig in den Widget-Tree
    // eingehängt ist. Ohne diesen Delay schlägt hasPermission() fehl.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startRecording();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  /// Startet die Audioaufnahme und die parallele STT-Transkription.
  Future<void> _startRecording() async {
    // permission_handler statt record.hasPermission(): Gibt volle Kontrolle über
    // den Berechtigungsstatus und erlaubt "Einstellungen öffnen" bei dauerhafter Ablehnung.
    final status = await Permission.microphone.status;
    final result = status.isGranted ? status : await Permission.microphone.request();

    if (!result.isGranted) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Mikrofon-Berechtigung fehlt'),
            content: const Text(
              'BiNo benötigt Zugriff auf das Mikrofon für Audioaufnahmen.',
            ),
            actions: [
              if (result.isPermanentlyDenied)
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await openAppSettings();
                  },
                  child: const Text('Einstellungen öffnen'),
                ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.of(context).pop();
      }
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _recordingPath = '${dir.path}/rec_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: _recordingPath!,
    );

    // STT parallel zur Aufnahme starten. Fehler (z. B. kein Sprachpaket
    // installiert) dürfen die Audio-Aufnahme nicht blockieren.
    try {
      final sttService = ref.read(sttServiceProvider);
      await sttService.startListening(
        onResult: (text, isFinal) {
          if (mounted) setState(() => _transcription = text);
        },
      );
    } catch (_) {
      // STT nicht verfügbar – Aufnahme läuft ohne Transkription weiter.
    }

    setState(() => _isRecording = true);

    // Sekunden-Timer für die Anzeige der Aufnahmedauer.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  /// Stoppt die Aufnahme und speichert den Eintrag.
  Future<void> _stopAndSave() async {
    _timer?.cancel();

    final sttService = ref.read(sttServiceProvider);
    await sttService.stopListening();

    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isSaving = true;
    });

    if (path == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    try {
      final entryRepo = ref.read(entryRepositoryProvider);
      final attachmentRepo = ref.read(attachmentRepositoryProvider);

      // Eintrag mit Transkription als Body erstellen.
      final entryId = await entryRepo.createEntry(
        body: _transcription,
        type: EntryType.audio,
      );

      final durationMs = _seconds * 1000;
      await attachmentRepo.saveAudio(
        entryId: entryId,
        audioFile: File(path),
        durationMs: durationMs,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).pop();
      }
    }
  }

  /// Bricht die Aufnahme ab ohne zu speichern.
  Future<void> _cancel() async {
    _timer?.cancel();
    final sttService = ref.read(sttServiceProvider);
    await sttService.stopListening();
    await _recorder.stop();

    // Temp-Datei löschen.
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) await file.delete();
    }

    if (mounted) Navigator.of(context).pop();
  }

  /// Formatiert Sekunden als MM:SS.
  String get _timerLabel {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // viewInsets.bottom: Sheet über Tastatur (falls sie aufgeht).
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 8),

          // Timer-Anzeige.
          Text(
            _timerLabel,
            style: theme.textTheme.displaySmall?.copyWith(
              color: _isRecording ? theme.colorScheme.error : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),

          // Aufnahme-Indikator (pulsierende Farbe wenn aktiv).
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording
                  ? theme.colorScheme.error
                  : theme.colorScheme.surfaceContainerHighest,
            ),
          ),

          // Echtzeit-Transkription.
          if (_transcription.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Text(
                _transcription,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(180),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Steuer-Buttons: Abbrechen | Stopp & Speichern.
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: CircularProgressIndicator(),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Abbrechen.
                  OutlinedButton.icon(
                    onPressed: _cancel,
                    icon: const Icon(Icons.close),
                    label: const Text('Abbrechen'),
                  ),
                  // Stopp & Speichern.
                  FilledButton.icon(
                    onPressed: _isRecording ? _stopAndSave : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Speichern'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Drag-Handle oben am Sheet.
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
