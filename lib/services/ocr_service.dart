// Datei: lib/services/ocr_service.dart
//
// ZWECK: Lokale Texterkennung (OCR) auf Fotos via Google ML Kit.
//        Extrahiert URLs aus dem erkannten Text – vollständig offline,
//        kein API-Key, kein Server.
// ABHÄNGIGKEITEN: google_mlkit_text_recognition (bereits in pubspec.yaml).
// PHASE: 2 – Foto-Capture-Erweiterung.
//
// ERWEITERBARKEIT:
//   OcrResult.rawText enthält den vollständigen Rohtext des Fotos.
//   Dieser kann später an die KI übergeben werden, um Titel, Serie,
//   Beschreibung, Bewertungen usw. strukturiert zu extrahieren.

import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Ergebnis einer OCR-Verarbeitung.
///
/// Enthält den vollständigen Rohtext sowie extrahierte URLs.
/// rawText ist bewusst öffentlich, damit spätere KI-Anreicherung
/// (Titel, Serie, Beschreibung) auf denselben Text zugreifen kann.
class OcrResult {
  final String rawText;
  final List<String> urls;

  const OcrResult({required this.rawText, required this.urls});

  bool get hasUrls => urls.isNotEmpty;
  bool get hasText => rawText.trim().isNotEmpty;
}

/// Lokaler OCR-Service basierend auf Google ML Kit Text Recognition.
///
// WARUM statische Methoden + ein gemeinsamer _recognizer?
// TextRecognizer ist teuer zu erzeugen (lädt das ML-Modell). Ein einzelner
// statischer Recognizer amortisiert diesen Aufwand über alle Aufrufe.
// Das ML-Kit-Modell wird durch das meta-data-Tag in AndroidManifest.xml
// beim App-Install vorgeladen – kein Netzwerk beim ersten Scan nötig.
class OcrService {
  static final _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Erkennt Text in [imageFile] und extrahiert URLs.
  ///
  /// Gibt ein leeres OcrResult zurück wenn das Bild nicht verarbeitet werden
  /// kann (kein Crash, damit der Nutzer eine verständliche Fehlermeldung
  /// statt eines App-Absturzes sieht).
  static Future<OcrResult> processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognized = await _recognizer.processImage(inputImage);
      final rawText = recognized.text;

      final urls = _extractUrls(rawText);
      return OcrResult(rawText: rawText, urls: urls);
    } catch (_) {
      return const OcrResult(rawText: '', urls: []);
    }
  }

  /// Extrahiert und bereinigt URLs aus dem OCR-Text.
  ///
  /// OCR erzeugt häufig Artefakte:
  /// - Leerzeichen mitten in URLs ('https://examp le.com') → werden entfernt
  /// - Satzzeichen am Ende ('https://example.com.') → werden abgeschnitten
  /// - Sehr kurze Treffer → werden ignoriert (zu viele False Positives)
  static List<String> _extractUrls(String text) {
    // Regex matcht http(s)-URLs; eckige Klammern und Klammern ausschließen
    // damit Markdown-Links ([text](url)) korrekt enden.
    final urlRegex = RegExp(r'https?://[^\s\r\n\[\]()]+', caseSensitive: false);

    final seen = <String>{};
    final result = <String>[];

    for (final match in urlRegex.allMatches(text)) {
      var url = match.group(0)!;

      // OCR-Leerzeichen innerhalb der URL entfernen.
      url = url.replaceAll(' ', '');

      // Anhängende Satzzeichen abschneiden.
      url = url.replaceAll(RegExp(r'[.,;:!?\s]+$'), '');

      // Zu kurze oder doppelte URLs ignorieren.
      if (url.length < 12 || seen.contains(url)) continue;

      seen.add(url);
      result.add(url);
    }

    return result;
  }

  // Gibt den TextRecognizer frei. Sollte beim App-Beenden aufgerufen werden.
  static Future<void> close() => _recognizer.close();
}
