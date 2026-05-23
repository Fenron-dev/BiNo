// Datei: lib/features/settings/settings_screen.dart
//
// ZWECK: Einstellungen-Screen mit Backup-Export und -Import.
//        Erreichbar über das Zahnrad-Icon im Feed-Screen.
// ABHÄNGIGKEITEN: BackupService, FilePicker, SystemNavigator.
// PHASE: 2 – Datensicherung.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/di.dart';
import '../../services/ai_settings_service.dart';
import '../../services/backup_service.dart';
import '../../services/theme_service.dart';

/// Einstellungen-Screen mit Backup/Restore-Funktion.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  // ── KI-Einstellungen ──────────────────────────────────────────────────────
  final _apiKeyCtrl = TextEditingController();
  String _selectedModel = kAiModels.first.$1;
  bool _obscureKey = true;
  bool _isSavingAi = false;

  @override
  void initState() {
    super.initState();
    _loadAiSettings();
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAiSettings() async {
    final service = ref.read(aiSettingsServiceProvider);
    final key = await service.getApiKey();
    final model = await service.getModel();
    if (mounted) {
      setState(() {
        _apiKeyCtrl.text = key ?? '';
        _selectedModel = model;
      });
    }
  }

  Future<void> _saveAiSettings() async {
    setState(() => _isSavingAi = true);
    await ref.read(aiSettingsServiceProvider).save(
          apiKey: _apiKeyCtrl.text,
          model: _selectedModel,
        );
    if (!mounted) return;
    setState(() => _isSavingAi = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('KI-Einstellungen gespeichert')),
    );
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);

    final result = await ref.read(backupServiceProvider).exportBackup();

    if (!mounted) return;
    setState(() => _isExporting = false);

    switch (result) {
      case BackupSuccess(:final path):
        // Android-Share-Sheet öffnen: Nutzer wählt selbst den Speicherort
        // (Dateien-App, Google Drive, USB, E-Mail, WhatsApp …).
        await Share.shareXFiles(
          [XFile(path, mimeType: 'application/zip')],
          subject: 'BiNo – Bit Notes Backup',
        );
      case BackupError(:final message):
        _showErrorSnackBar(message);
    }
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
              // exit(0) beendet den gesamten Dart-Prozess sofort.
              // SystemNavigator.pop() reicht nicht: Der Prozess kann im
              // Hintergrund weiterlaufen und Drift greift auf die
              // ausgetauschte DB mit dem alten Handle zu → Datenverlust.
              exit(0);
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
            subtitle: const Text('Einträge + Anhänge als ZIP – Speicherort frei wählbar'),
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

          // ── Darstellung ────────────────────────────────────────────────
          _SectionHeader(title: 'Darstellung'),
          _ThemeSelector(),

          const Divider(),

          // ── KI (AI-Anreicherung) ───────────────────────────────────────
          _SectionHeader(title: 'KI – Anreicherung'),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _apiKeyCtrl,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                labelText: 'Anthropic API-Key',
                hintText: 'sk-ant-...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _selectedModel,
              decoration: const InputDecoration(
                labelText: 'Modell',
                border: OutlineInputBorder(),
              ),
              items: kAiModels
                  .map(
                    (m) => DropdownMenuItem(
                      value: m.$1,
                      child: Text(m.$2),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedModel = v);
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSavingAi ? null : _saveAiSettings,
                child: _isSavingAi
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('KI-Einstellungen speichern'),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Dein API-Key wird ausschließlich lokal auf dem Gerät gespeichert '
              'und direkt an die Anthropic-API gesendet – kein eigener Server, '
              'kein Tracking. Schlüssel unter console.anthropic.com erstellen.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
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
              'Beim Export öffnet sich das Android-Share-Sheet – du kannst das ZIP '
              'direkt in Google Drive, auf USB, per E-Mail oder an einem anderen '
              'Ort deiner Wahl speichern.',
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

// ── Theme-Auswahl ──────────────────────────────────────────────────────────────

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  static const _options = [
    (ThemeService.kSystem, 'System', 'Folgt dem Gerätemodus', Icons.brightness_auto_outlined),
    (ThemeService.kLight, 'Hell', null, Icons.light_mode_outlined),
    (ThemeService.kDark, 'Dunkel', null, Icons.dark_mode_outlined),
    (ThemeService.kOled, 'OLED-Dunkel', 'Schwarze Pixel – spart Akku auf AMOLED', Icons.smartphone_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    return RadioGroup<String>(
      groupValue: current,
      onChanged: (v) async {
        if (v == null) return;
        ref.read(themeModeProvider.notifier).state = v;
        await ref.read(themeServiceProvider).save(v);
      },
      child: Column(
        children: _options.map((opt) {
          final (value, label, subtitle, icon) = opt;
          return RadioListTile<String>(
            secondary: Icon(icon),
            title: Text(label),
            subtitle: subtitle != null ? Text(subtitle) : null,
            value: value,
          );
        }).toList(),
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
