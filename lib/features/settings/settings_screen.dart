// Datei: lib/features/settings/settings_screen.dart
//
// ZWECK: Einstellungen-Screen mit Backup-Export und -Import.
//        Erreichbar über das Zahnrad-Icon im Feed-Screen.
// ABHÄNGIGKEITEN: BackupService, FilePicker, SystemNavigator.
// PHASE: 2 – Datensicherung.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../services/backup_service.dart';

/// Einstellungen-Screen mit Backup/Restore-Funktion.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);

    final result = await ref.read(backupServiceProvider).exportBackup();

    if (!mounted) return;
    setState(() => _isExporting = false);

    switch (result) {
      case BackupSuccess(:final path):
        _showExportSuccessDialog(path);
      case BackupError(:final message):
        _showErrorSnackBar(message);
    }
  }

  void _showExportSuccessDialog(String path) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup erstellt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Die Backup-Datei wurde gespeichert unter:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                path,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Du findest die Datei im Dateimanager unter:\n'
              'Interner Speicher → Android → data → '
              'com.fenron.bino_bit_notes → files',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: path));
              Navigator.of(ctx).pop();
            },
            child: const Text('Pfad kopieren'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<void> _importBackup() async {
    // Datei auswählen.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: 'BiNo-Backup auswählen',
    );

    if (result == null || result.files.single.path == null) return;
    final zipPath = result.files.single.path!;

    // Sicherheitsbestätigung: Alle aktuellen Daten werden überschrieben.
    if (!mounted) return;
    final confirmed = await _showImportConfirmDialog();
    if (!confirmed) return;

    setState(() => _isImporting = true);

    // DB schließen, bevor Dateien überschrieben werden.
    await ref.read(databaseProvider).close();

    final importResult =
        await ref.read(backupServiceProvider).importBackup(zipPath);

    if (!mounted) return;
    setState(() => _isImporting = false);

    switch (importResult) {
      case BackupSuccess():
        _showRestartDialog();
      case BackupError(:final message):
        _showErrorSnackBar(message);
    }
  }

  Future<bool> _showImportConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Backup wiederherstellen?'),
            content: const Text(
              'Alle aktuellen Einträge und Anhänge werden durch den '
              'Backup-Stand ersetzt.\n\n'
              'Dieser Vorgang kann nicht rückgängig gemacht werden.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Wiederherstellen'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showRestartDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup wiederhergestellt'),
        content: const Text(
          'Das Backup wurde erfolgreich eingespielt.\n\n'
          'Bitte starte BiNo jetzt neu, damit die wiederhergestellten '
          'Daten geladen werden.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // App beenden – der Nutzer startet sie manuell neu.
              SystemNavigator.pop();
            },
            child: const Text('App beenden'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          // ── Datensicherung ─────────────────────────────────────────────
          _SectionHeader(title: 'Datensicherung'),

          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Backup exportieren'),
            subtitle: const Text('Einträge + Anhänge als ZIP speichern'),
            trailing: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            enabled: !_isExporting && !_isImporting,
            onTap: _exportBackup,
          ),

          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Backup importieren'),
            subtitle: const Text(
              'Backup-ZIP auswählen und wiederherstellen\n'
              '⚠ Aktuelle Daten werden ersetzt',
            ),
            isThreeLine: true,
            trailing: _isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            enabled: !_isExporting && !_isImporting,
            onTap: _importBackup,
          ),

          const Divider(),

          // ── Info ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Info'),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text('0.1.0 – Phase 2'),
            enabled: false,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(
              'Das Backup enthält alle Einträge, Tags und Anhänge (Bilder, Audio). '
              'Es wird als ZIP-Datei im App-Verzeichnis des externen Speichers gespeichert '
              'und ist über die Dateimanager-App zugänglich.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Abschnittsüberschrift in der Einstellungsliste.
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
