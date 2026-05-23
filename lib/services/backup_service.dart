// Datei: lib/services/backup_service.dart
//
// ZWECK: Exportiert und importiert ein vollständiges App-Backup als ZIP-Datei.
//        Das ZIP enthält die SQLite-Datenbank und den Anhänge-Ordner.
// ABHÄNGIGKEITEN: archive (ZIP), path_provider, AppDatabase (für WAL-Checkpoint).
// PHASE: 2 – Datensicherung und -wiederherstellung.

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/db/database.dart';

/// Backup-Ergebnis: Pfad zur exportierten Datei oder Fehlermeldung.
sealed class BackupResult {
  const BackupResult();
}

class BackupSuccess extends BackupResult {
  final String path;
  const BackupSuccess(this.path);
}

class BackupError extends BackupResult {
  final String message;
  const BackupError(this.message);
}

/// Erstellt und stellt vollständige App-Backups wieder her.
///
/// WARUM ZIP statt nur DB-Datei?
/// Anhänge (Bilder, Audio) liegen als Dateien im Dateisystem, nicht in der DB.
/// Nur die DB zu sichern würde Einträge mit Anhang-Verweisen wiederherstellen,
/// die auf nicht vorhandene Dateien zeigen.
class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  // ── Export ────────────────────────────────────────────────────────────────

  /// Exportiert Datenbank + Anhänge als ZIP in das externe App-Verzeichnis.
  ///
  /// Das externe App-Verzeichnis (Android/data/[packageId]/files/) ist ohne
  /// WRITE_EXTERNAL_STORAGE-Berechtigung zugänglich und über Dateimanager-Apps
  /// erreichbar. Gibt den vollständigen Pfad der Backup-Datei zurück.
  Future<BackupResult> exportBackup() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();

      // WAL-Checkpoint: Ausstehende Schreibvorgänge in die DB-Datei flushen,
      // damit die kopierte DB-Datei vollständig und konsistent ist.
      await _db.customStatement('PRAGMA wal_checkpoint(FULL)');

      final archive = Archive();

      // DB-Datei ins Archiv aufnehmen.
      final dbFile = File(p.join(appDir.path, 'bino_notes.db'));
      if (await dbFile.exists()) {
        final bytes = await dbFile.readAsBytes();
        archive.addFile(ArchiveFile('bino_notes.db', bytes.length, bytes));
      }

      // Gesamten Anhänge-Ordner ins Archiv aufnehmen.
      final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));
      if (await attachmentsDir.exists()) {
        await for (final entity in attachmentsDir.list(recursive: true)) {
          if (entity is File) {
            // Relativer Pfad ab appDir, z. B. 'attachments/img_abc.jpg'.
            final relative = p.relative(entity.path, from: appDir.path);
            final bytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile(relative, bytes.length, bytes));
          }
        }
      }

      // ZIP kodieren und in externem App-Verzeichnis speichern.
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) return const BackupError('ZIP-Kodierung fehlgeschlagen.');

      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final filename = 'bino_backup_$timestamp.zip';

      // Externes App-Verzeichnis ist für Dateimanager-Apps sichtbar.
      final externalDir = await getExternalStorageDirectory() ?? appDir;
      final backupFile = File(p.join(externalDir.path, filename));
      await backupFile.writeAsBytes(zipBytes);

      return BackupSuccess(backupFile.path);
    } catch (e) {
      return BackupError('Export fehlgeschlagen: $e');
    }
  }

  // ── Import ────────────────────────────────────────────────────────────────

  /// Stellt Datenbank + Anhänge aus einem ZIP-Backup wieder her.
  ///
  /// WICHTIG: Nach dem Import muss die App neu gestartet werden, damit Drift
  /// die wiederhergestellte DB-Datei neu öffnet. Der Aufrufer ist für den
  /// Neustart (SystemNavigator.pop()) verantwortlich.
  ///
  /// WARUM kein Live-Reload?
  /// Drift hält die DB-Verbindung auf einem Hintergrund-Isolat. Ein sauberes
  /// Schließen und Wiedereröffnen nach dem Datei-Austausch erfordert den
  /// Neustart des gesamten Isolat-Pools – das entspricht einem App-Neustart.
  Future<BackupResult> importBackup(String zipPath) async {
    try {
      final zipBytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // Validierung: Backup muss eine bino_notes.db enthalten.
      final hasDb = archive.any((f) => f.name == 'bino_notes.db');
      if (!hasDb) {
        return const BackupError(
          'Ungültige Backup-Datei: bino_notes.db nicht gefunden.',
        );
      }

      final appDir = await getApplicationDocumentsDirectory();

      // Alte WAL/SHM-Dateien löschen, damit SQLite die wiederhergestellte DB
      // ohne Journal-Konflikte beim nächsten Start öffnen kann.
      for (final suffix in ['-wal', '-shm']) {
        final sideFile = File(p.join(appDir.path, 'bino_notes.db$suffix'));
        if (await sideFile.exists()) await sideFile.delete();
      }

      // Alle Dateien aus dem Archiv extrahieren.
      for (final file in archive) {
        if (file.isFile) {
          final outFile = File(p.join(appDir.path, file.name));
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      return const BackupSuccess('');
    } catch (e) {
      return BackupError('Import fehlgeschlagen: $e');
    }
  }
}
