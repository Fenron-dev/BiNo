// Datei: lib/features/capture/capture_controller.dart
//
// ZWECK: Steuert den Speicher-Vorgang im CaptureSheet. Hält den UI-Zustand
//        (speichert gerade / Fehler) und delegiert die Persistenz an das Repository.
// ABHÄNGIGKEITEN: entryRepositoryProvider aus di.dart.
// MUSTER: StateNotifier via Riverpod StateNotifierProvider.
// PHASE: 1 – Nur Text. Phase 2 erweitert CaptureState um isRecording, attachedImages etc.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../data/repositories/entry_repository.dart';

/// Unveränderlicher Zustand des Capture-Sheets.
///
/// WARUM eine eigene State-Klasse statt nur einem bool?
/// Phase 2 fügt isRecording, attachedImages, detectedUrl und weitere Felder
/// hinzu. Eine dedizierte Klasse vermeidet spätere API-Änderungen am Provider.
@immutable
class CaptureState {
  /// true während der Eintrag in die Datenbank geschrieben wird.
  final bool isSaving;

  /// Fehlermeldung für den Nutzer. Null wenn kein Fehler vorliegt.
  final String? error;

  const CaptureState({
    this.isSaving = false,
    this.error,
  });

  CaptureState copyWith({bool? isSaving, String? error}) {
    return CaptureState(
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

/// Controller für das Capture-Sheet.
///
/// MUSTER: StateNotifier – kapselt zustandsbehaftete Logik und stellt
/// Methoden für die UI bereit.
class CaptureController extends StateNotifier<CaptureState> {
  final EntryRepository _repository;

  CaptureController(this._repository) : super(const CaptureState());

  /// Speichert einen neuen Texteintrag.
  ///
  /// Gibt true zurück bei Erfolg (Sheet kann geschlossen werden),
  /// false bei Fehler (Fehlermeldung wird im State gesetzt).
  Future<bool> saveEntry(String body) async {
    if (body.trim().isEmpty) return false;

    state = state.copyWith(isSaving: true);

    try {
      await _repository.createEntry(body: body.trim());
      // Zustand zurücksetzen nach erfolgreichem Speichern.
      state = const CaptureState();
      return true;
    } catch (e, stackTrace) {
      state = state.copyWith(
        isSaving: false,
        error: 'Fehler beim Speichern: $e',
      );
      // Im Debug-Modus auf der Konsole ausgeben. Phase 7: Sentry.
      debugPrint('CaptureController.saveEntry Fehler: $e\n$stackTrace');
      return false;
    }
  }
}

/// Provider für den CaptureController.
///
/// WARUM StateNotifierProvider statt StateProvider?
/// Der Controller hat asynchrone Methoden (saveEntry), die den Zustand
/// mehrfach aktualisieren. StateNotifier eignet sich besser als StateProvider,
/// der nur einfache Zustandsersetzungen unterstützt.
///
/// autoDispose: Controller wird freigegeben, wenn das Sheet geschlossen wird.
/// So wird isSaving=true nicht beim nächsten Sheet-Öffnen weitergegeben.
final captureControllerProvider =
    StateNotifierProvider.autoDispose<CaptureController, CaptureState>((ref) {
  return CaptureController(ref.watch(entryRepositoryProvider));
}, name: 'captureControllerProvider');
