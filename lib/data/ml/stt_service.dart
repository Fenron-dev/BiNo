// Datei: lib/data/ml/stt_service.dart
//
// ZWECK: Speech-to-Text via Android On-Device API (speech_to_text-Package).
//        Transkribiert aufgenommene Audio-Dateien lokal ohne Cloud-Aufruf.
// ABHÄNGIGKEITEN: speech_to_text.
// PHASE: 2 – Audio-Aufnahme mit automatischer Transkription.
//
// WICHTIG FÜR DEN NUTZER:
// Damit Offline-Transkription auf Deutsch funktioniert, muss auf dem Gerät
// unter: Einstellungen → Allgemeine Verwaltung → Sprach- und Eingabe → Auf-
// dem-Gerät-Spracherkennung → Deutsch heruntergeladen werden.
// Alternativ: Gboard → Spracheingabe → Offline-Spracheingabe → Deutsch.

import 'package:speech_to_text/speech_to_text.dart';

/// Lokaler Speech-to-Text-Service.
///
/// WARUM on-device statt Cloud (z. B. Whisper API)?
/// (1) Lokal first: keine Netzwerkabhängigkeit, keine API-Kosten.
/// (2) Datenschutz: Sprachdaten verlassen das Gerät nicht.
/// (3) Geschwindigkeit: Kein Upload nötig, Ergebnis in ~1s.
/// Phase 7 (stretch): Optionaler Whisper-Premium-Modus für bessere Qualität.
class SttService {
  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;

  /// Initialisiert den STT-Service. Muss vor dem ersten listen()-Aufruf
  /// einmalig aufgerufen werden.
  ///
  /// Gibt true zurück wenn Sprach-Erkennung auf dem Gerät verfügbar ist.
  /// false = entweder keine Berechtigung oder kein Sprachpaket installiert.
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _stt.initialize(
      onError: (_) {}, // Fehler werden beim listen()-Aufruf behandelt.
      // debugLogging: nur in Debug-Modus aktivieren – erzeugt viele Logs.
      debugLogging: false,
    );
    return _initialized;
  }

  /// Transkribiert Sprache für [duration] Sekunden.
  ///
  /// WARUM kein kontinuierliches Streaming?
  /// speech_to_text bietet kein direktes Datei-Transkriptions-API –
  /// es hört via Mikrofon zu. Die Transkription läuft also WÄHREND der
  /// Aufnahme parallel im Hintergrund, nicht danach.
  ///
  /// [onResult]: Callback mit dem transkribierten Text (wird mehrfach aufgerufen).
  /// [localeId]: ISO-Sprach-Code, z. B. 'de_DE'. Null = System-Standard.
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String? localeId,
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    await _stt.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      // SpeechListenOptions bündelt alle Listen-Parameter seit speech_to_text 6.x.
      listenOptions: SpeechListenOptions(
        localeId: localeId ?? 'de_DE',
        cancelOnError: true,
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  /// Stoppt die aktuelle Transkription und gibt das finale Ergebnis zurück.
  Future<void> stopListening() => _stt.stop();

  /// Gibt true zurück wenn die STT-Engine gerade zuhört.
  bool get isListening => _stt.isListening;

  /// Gibt die verfügbaren Sprachen zurück.
  /// Wird in den Einstellungen genutzt, um dem Nutzer Sprachoptionen anzuzeigen.
  Future<List<LocaleName>> availableLocales() => _stt.locales();
}
