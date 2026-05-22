// Datei: lib/services/attachment_service.dart
//
// ZWECK: Verwaltet das Speichern, Abrufen und Löschen von Anhangdateien
//        im App-Dokumentenverzeichnis. Kapselt alle Dateisystem-Operationen.
// ABHÄNGIGKEITEN: path_provider, mime, dart:io.
// PHASE: 2 – Foto- und Audio-Anhänge.

import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Verwaltet Anhangdateien im App-Dokumentenverzeichnis.
///
/// WARUM ein eigener Service statt direkte Dateisystemzugriffe im Repository?
/// Die Pfadlogik (YYYY/MM-Struktur, MIME-zu-Extension-Mapping) soll nicht im
/// Repository leben. Außerdem kann dieser Service in Tests einfach gemockt werden.
class AttachmentService {
  static const _baseFolderName = 'attachments';
  final Uuid _uuid;

  AttachmentService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  /// Gibt das Basis-Verzeichnis für Anhänge zurück: `<docs>/attachments/`.
  Future<Directory> get _baseDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _baseFolderName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Gibt das monatsbasierte Unterverzeichnis zurück: `<docs>/attachments/YYYY/MM/`.
  ///
  /// WARUM YYYY/MM-Struktur?
  /// Verhindert dass ein einzelnes Verzeichnis tausende Dateien enthält,
  /// was auf einigen Dateisystemen die Performance beeinträchtigt.
  Future<Directory> _monthDir(DateTime date) async {
    final base = await _baseDir;
    final dir = Directory(p.join(
      base.path,
      date.year.toString().padLeft(4, '0'),
      date.month.toString().padLeft(2, '0'),
    ));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Speichert eine Datei als Anhang und gibt den relativen Pfad zurück.
  ///
  /// [sourceFile]: Die zu speichernde Quelldatei (temporäre Kamera/Picker-Datei).
  /// [mimeType]: MIME-Typ, z. B. 'image/jpeg', 'audio/m4a'. Wenn null, wird er erkannt.
  ///
  /// Rückgabewert ist der Pfad relativ zu `<docs>/attachments/`, z. B. '2025/05/abc.jpg'.
  /// Dieser relative Pfad wird in der DB gespeichert und ist portabel.
  Future<AttachmentFileInfo> saveFile(File sourceFile,
      {String? mimeType}) async {
    final now = DateTime.now();
    final monthDir = await _monthDir(now);

    // MIME-Typ ermitteln falls nicht übergeben.
    final effectiveMime =
        mimeType ?? lookupMimeType(sourceFile.path) ?? 'application/octet-stream';

    // Dateiextension aus MIME-Typ ableiten.
    final extension = _extensionForMime(effectiveMime);
    final fileName = '${_uuid.v4()}$extension';
    final destFile = File(p.join(monthDir.path, fileName));

    // Datei kopieren (nicht verschieben – sourceFile kann in einem temporären
    // Systemverzeichnis liegen, das nach einem Neustart geleert wird).
    await sourceFile.copy(destFile.path);

    // Relativer Pfad: 'YYYY/MM/filename.ext'
    final base = await _baseDir;
    final relativePath = p.relative(destFile.path, from: base.path);

    return AttachmentFileInfo(
      absolutePath: destFile.path,
      relativePath: relativePath,
      mimeType: effectiveMime,
      size: await destFile.length(),
    );
  }

  /// Gibt die absolute Dateipfad für einen gespeicherten relativen Pfad zurück.
  Future<String> absolutePath(String relativePath) async {
    final base = await _baseDir;
    return p.join(base.path, relativePath);
  }

  /// Löscht eine Anhangdatei aus dem Dateisystem.
  /// Gibt true zurück wenn die Datei gelöscht wurde, false wenn sie nicht existierte.
  Future<bool> deleteFile(String relativePath) async {
    final absPath = await absolutePath(relativePath);
    final file = File(absPath);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  /// Leitet die Dateiextension aus einem MIME-Typ ab.
  String _extensionForMime(String mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/gif':
        return '.gif';
      case 'audio/m4a':
      case 'audio/mp4':
        return '.m4a';
      case 'audio/mpeg':
        return '.mp3';
      case 'audio/wav':
        return '.wav';
      case 'audio/aac':
        return '.aac';
      case 'video/mp4':
        return '.mp4';
      default:
        // Generische Extension aus MIME-Subtyp: 'application/pdf' → '.pdf'
        final parts = mimeType.split('/');
        return parts.length == 2 ? '.${parts[1]}' : '.bin';
    }
  }
}

/// Wertklasse mit Informationen über eine gespeicherte Anhangdatei.
class AttachmentFileInfo {
  /// Absoluter Dateipfad (gerätespezifisch, nicht persistierbar).
  final String absolutePath;

  /// Relativer Pfad innerhalb des attachments-Ordners (wird in DB gespeichert).
  final String relativePath;

  final String mimeType;

  /// Dateigröße in Byte.
  final int size;

  const AttachmentFileInfo({
    required this.absolutePath,
    required this.relativePath,
    required this.mimeType,
    required this.size,
  });
}
