// Datei: lib/data/ml/ocr_service.dart
//
// ZWECK: Erkennt Text in Bilddateien via Google ML Kit Text Recognition.
//        Läuft lokal auf dem Gerät (kein Cloud-Aufruf).
// ABHÄNGIGKEITEN: google_mlkit_text_recognition.
// PHASE: 2 – Foto-Capture mit OCR.

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Lokaler OCR-Service via Google ML Kit.
///
/// WARUM lokale OCR statt Cloud-API?
/// (1) Lokal first: kein Netzwerk nötig, kein Datenschutzproblem.
/// (2) ML Kit ist kostenlos und liefert auf modernen Android-Geräten
///     sehr gute Erkennungsraten für Lateinschrift.
/// (3) Für handgeschriebenen Text oder exotische Schriften gibt es später
///     optional eine Cloud-Fallback-Option (Phase 5).
class OcrService {
  // TextRecognizer-Instanz: einmalig erstellen und wiederverwenden.
  // WARUM Wiederverwendung? Das Laden des ML-Kit-Modells kostet ~200 ms.
  // Als Singleton-ähnliches Objekt amortisiert sich dieser Aufwand.
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Erkennt Text in [imageFile] und gibt ihn zurück.
  ///
  /// Gibt null zurück wenn kein Text gefunden wurde oder ein Fehler auftrat.
  /// Der erkannte Text wird NUR in attachments.ocr_text gespeichert –
  /// nicht automatisch in den Entry-Body (Nutzer entscheidet via UI-Aktion).
  Future<String?> recognizeText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _recognizer.processImage(inputImage);

      final text = recognizedText.text.trim();
      return text.isEmpty ? null : text;
    } catch (e) {
      // Fehler beim OCR-Lauf: nicht kritisch, Eintrag wurde bereits gespeichert.
      // Der Nutzer sieht kein OCR-Ergebnis, aber der Eintrag ist noch nutzbar.
      return null;
    }
  }

  /// Gibt Ressourcen frei. Muss aufgerufen werden wenn der Service nicht mehr
  /// gebraucht wird (z. B. beim App-Lifecycle-Event onDetach).
  Future<void> dispose() => _recognizer.close();
}
