// Datei: lib/features/capture/capture_controller.dart
//
// ZWECK: Steuert den Speicher-Vorgang im CaptureSheet. Verwaltet Text-,
//        Bild- und URL-Erfassung. Audio-Erfassung ist im AudioCaptureSheet.
// ABHÄNGIGKEITEN: entryRepositoryProvider, attachmentRepositoryProvider,
//                 urlMetadataServiceProvider, image_picker.
// MUSTER: StateNotifier via Riverpod StateNotifierProvider.
// PHASE: 1 – Text. Phase 2: Bild + URL.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di.dart';
import '../../data/repositories/entry_repository.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../data/db/tables/entries.dart';
import '../../services/url_metadata_service.dart';

/// Unveränderlicher Zustand des Capture-Sheets.
@immutable
class CaptureState {
  /// true während der Eintrag gespeichert wird.
  final bool isSaving;

  /// Ausgewählte Bilder (noch nicht gespeichert – nur für Vorschau im Sheet).
  final List<XFile> pendingImages;

  /// URL-Metadaten, wenn im Body eine URL erkannt wurde.
  final UrlMetadata? detectedUrl;

  /// true während Open-Graph-Metadaten für eine URL geladen werden.
  final bool isFetchingUrl;

  /// Fehlermeldung. Null wenn kein Fehler.
  final String? error;

  /// Manuell gesetzter Typ-Override. Null = Auto-Erkennung.
  final EntryType? typeOverride;

  const CaptureState({
    this.isSaving = false,
    this.pendingImages = const [],
    this.detectedUrl,
    this.isFetchingUrl = false,
    this.error,
    this.typeOverride,
  });

  CaptureState copyWith({
    bool? isSaving,
    List<XFile>? pendingImages,
    UrlMetadata? detectedUrl,
    bool clearUrl = false,
    bool? isFetchingUrl,
    String? error,
    EntryType? typeOverride,
    bool clearTypeOverride = false,
  }) {
    return CaptureState(
      isSaving: isSaving ?? this.isSaving,
      pendingImages: pendingImages ?? this.pendingImages,
      detectedUrl: clearUrl ? null : (detectedUrl ?? this.detectedUrl),
      isFetchingUrl: isFetchingUrl ?? this.isFetchingUrl,
      error: error,
      typeOverride:
          clearTypeOverride ? null : (typeOverride ?? this.typeOverride),
    );
  }
}

/// Controller für Text- und Bild-Erfassung im CaptureSheet.
class CaptureController extends StateNotifier<CaptureState> {
  final EntryRepository _entryRepo;
  final AttachmentRepository _attachmentRepo;
  final UrlMetadataService _urlService;
  final ImagePicker _picker;

  CaptureController({
    required EntryRepository entryRepo,
    required AttachmentRepository attachmentRepo,
    required UrlMetadataService urlService,
    ImagePicker? picker,
  })  : _entryRepo = entryRepo,
        _attachmentRepo = attachmentRepo,
        _urlService = urlService,
        _picker = picker ?? ImagePicker(),
        super(const CaptureState());

  // ── Typ-Override ──────────────────────────────────────────────────────

  /// Setzt den Typ manuell. null = Auto-Erkennung.
  void setTypeOverride(EntryType? type) {
    state = state.copyWith(
      typeOverride: type,
      clearTypeOverride: type == null,
    );
  }

  // ── Bild-Auswahl ──────────────────────────────────────────────────────

  /// Öffnet den System-Galerie-Picker für ein oder mehrere Bilder.
  Future<void> pickImageFromGallery() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isNotEmpty) {
        state = state.copyWith(
          pendingImages: [...state.pendingImages, ...images],
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Fehler beim Öffnen der Galerie: $e');
    }
  }

  /// Öffnet die Kamera für ein neues Foto.
  Future<void> pickImageFromCamera() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        state = state.copyWith(
          pendingImages: [...state.pendingImages, image],
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Fehler beim Öffnen der Kamera: $e');
    }
  }

  /// Entfernt ein Bild aus der Auswahl (vor dem Speichern).
  void removePendingImage(int index) {
    final updated = List<XFile>.from(state.pendingImages)..removeAt(index);
    state = state.copyWith(pendingImages: updated);
  }

  // ── URL-Erkennung ──────────────────────────────────────────────────────

  /// Wird aufgerufen wenn der Nutzer im Textfeld tippt.
  /// Erkennt URLs und lädt Open-Graph-Metadaten im Hintergrund.
  Future<void> onBodyChanged(String text) async {
    // URL im Text suchen.
    final urlRegex = RegExp(r'https?://\S+', caseSensitive: false);
    final match = urlRegex.firstMatch(text);

    if (match == null) {
      // Keine URL: Vorherige URL-Vorschau löschen.
      if (state.detectedUrl != null || state.isFetchingUrl) {
        state = state.copyWith(clearUrl: true, isFetchingUrl: false);
      }
      return;
    }

    final url = match.group(0)!;

    // URL schon bekannt? Nicht erneut laden.
    if (state.detectedUrl?.url == url) return;

    state = state.copyWith(isFetchingUrl: true, clearUrl: true);

    final metadata = await _urlService.fetch(url);
    // Nur aktualisieren wenn der Controller noch mounted ist und
    // der Nutzer die URL nicht zwischenzeitlich entfernt hat.
    if (mounted) {
      state = state.copyWith(
        detectedUrl: metadata,
        isFetchingUrl: false,
      );
    }
  }

  // ── Speichern ──────────────────────────────────────────────────────────

  /// Speichert den Eintrag mit Text, Bildern und (falls erkannt) als Link-Typ.
  Future<bool> saveEntry(String body) async {
    if (body.trim().isEmpty && state.pendingImages.isEmpty) return false;

    state = state.copyWith(isSaving: true);

    try {
      // Typ bestimmen: Link wenn URL erkannt, Mixed wenn Text + Bilder,
      // Image wenn nur Bilder, Text wenn nur Text.
      final type = _determineType(body);

      // sourceUrl: priorisiert detectedUrl (enthält OG-Metadaten).
      // Fallback: URL direkt aus dem Body extrahieren, damit auch Links
      // ohne Open-Graph-Metadaten (z. B. MP3-Direktlinks) korrekt gespeichert
      // und als Link-Typ angezeigt werden.
      String? sourceUrl = state.detectedUrl?.url;
      if (sourceUrl == null && type == EntryType.link) {
        final m = RegExp(r'https?://\S+').firstMatch(body.trim());
        sourceUrl = m?.group(0);
      }

      final entryId = await _entryRepo.createEntry(
        body: body.trim(),
        type: type,
        sourceUrl: sourceUrl,
      );

      // Bilder speichern (parallel für bessere Performance).
      final imageFutures = state.pendingImages.map((xFile) async {
        await _attachmentRepo.saveImage(
          entryId: entryId,
          imageFile: File(xFile.path),
        );
      });
      await Future.wait(imageFutures);

      state = const CaptureState(); // Reset.
      return true;
    } catch (e, st) {
      state = state.copyWith(
        isSaving: false,
        error: 'Fehler beim Speichern: $e',
      );
      debugPrint('CaptureController.saveEntry Fehler: $e\n$st');
      return false;
    }
  }

  /// Bestimmt den Eintragstyp. Manueller Override hat Vorrang vor Auto-Erkennung.
  EntryType _determineType(String body) {
    if (state.typeOverride != null) return state.typeOverride!;

    final hasImages = state.pendingImages.isNotEmpty;
    final hasUrl = state.detectedUrl != null;
    final hasText = body.trim().isNotEmpty;

    if (hasUrl && !hasImages) return EntryType.link;
    if (hasImages && !hasText) return EntryType.image;
    if (hasImages && hasText) return EntryType.mixed;
    return EntryType.text;
  }
}

/// Provider für CaptureController.
/// autoDispose: wird freigegeben wenn das Sheet geschlossen wird.
final captureControllerProvider =
    StateNotifierProvider.autoDispose<CaptureController, CaptureState>((ref) {
  return CaptureController(
    entryRepo: ref.watch(entryRepositoryProvider),
    attachmentRepo: ref.watch(attachmentRepositoryProvider),
    urlService: ref.watch(urlMetadataServiceProvider),
  );
}, name: 'captureControllerProvider');
