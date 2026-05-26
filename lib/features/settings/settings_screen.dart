// Datei: lib/features/settings/settings_screen.dart
//
// ZWECK: Einstellungen-Screen mit Backup-Export/-Import, Theme-Auswahl und
//        KI-Konfiguration (Anthropic, OpenRouter, Ollama/LM-Studio).
// ABHÄNGIGKEITEN: BackupService, FilePicker, AiSettingsService, AiEnrichService.
// PHASE: 5 – KI-Anreicherung + Darstellung.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Container;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/di.dart';
import '../../data/db/daos/tag_dao.dart' show TagWithCount;
import '../../data/db/database.dart';
import '../../services/ai_enrich_service.dart';
import '../../services/ai_settings_service.dart';
import '../../services/app_lock_service.dart';
import '../templates/template_form_sheet.dart';
import '../../services/backup_service.dart';
import '../../services/theme_service.dart';
import '../hubs/hub_form_sheet.dart';
import '../hubs/hub_provider.dart';

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
  String _provider = kProviderAnthropic;

  // Anthropic
  final _anthKeyCtrl = TextEditingController();
  String _anthModel = kAiModels.first.$1;
  bool _obscureAnthKey = true;

  // OpenRouter
  final _orKeyCtrl = TextEditingController();
  String _orModel = '';
  bool _obscureOrKey = true;
  List<OpenRouterModel> _orModels = [];
  bool _isLoadingOrModels = false;
  bool _onlyFreeOrModels = false;

  // Ollama / LM-Studio
  final _ollamaBaseUrlCtrl = TextEditingController();
  final _ollamaModelCtrl = TextEditingController();

  bool _isSavingAi = false;

  @override
  void initState() {
    super.initState();
    _loadAiSettings();
  }

  @override
  void dispose() {
    _anthKeyCtrl.dispose();
    _orKeyCtrl.dispose();
    _ollamaBaseUrlCtrl.dispose();
    _ollamaModelCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAiSettings() async {
    final s = ref.read(aiSettingsServiceProvider);
    final provider = await s.getProvider();
    final anthKey = await s.getAnthropicKey();
    final anthModel = await s.getAnthropicModel();
    final orKey = await s.getOpenRouterKey();
    final orModel = await s.getOpenRouterModel();
    final ollamaUrl = await s.getOllamaBaseUrl();
    final ollamaModel = await s.getOllamaModel();
    if (!mounted) return;
    setState(() {
      _provider = provider;
      _anthKeyCtrl.text = anthKey ?? '';
      _anthModel = anthModel;
      _orKeyCtrl.text = orKey ?? '';
      _orModel = orModel;
      _ollamaBaseUrlCtrl.text = ollamaUrl;
      _ollamaModelCtrl.text = ollamaModel;
    });
    if (provider == kProviderOpenRouter) _loadOrModels();
  }

  Future<void> _loadOrModels() async {
    setState(() => _isLoadingOrModels = true);
    final models = await AiEnrichService.fetchOpenRouterModels();
    if (!mounted) return;
    setState(() {
      _orModels = models;
      _isLoadingOrModels = false;
      // Wenn das gespeicherte Modell nicht in der neuen Liste ist → erstes auswählen.
      if (models.isNotEmpty && models.every((m) => m.id != _orModel)) {
        _orModel = models.first.id;
      }
    });
  }

  Future<void> _saveAiSettings() async {
    setState(() => _isSavingAi = true);
    await ref.read(aiSettingsServiceProvider).save(
          provider: _provider,
          anthropicKey: _anthKeyCtrl.text,
          anthropicModel: _anthModel,
          openRouterKey: _orKeyCtrl.text,
          openRouterModel: _orModel,
          ollamaBaseUrl: _ollamaBaseUrlCtrl.text,
          ollamaModel: _ollamaModelCtrl.text,
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: 'BiNo-Backup auswählen',
    );

    if (result == null || result.files.single.path == null) return;
    final zipPath = result.files.single.path!;

    if (!mounted) return;
    final confirmed = await _showImportConfirmDialog();
    if (!confirmed) return;

    setState(() => _isImporting = true);

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
            onPressed: () => exit(0),
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
    // Gefilterte OpenRouter-Modelle (nur kostenlose wenn Toggle aktiv)
    final filteredOrModels = _onlyFreeOrModels
        ? _orModels.where((m) => m.isFree).toList()
        : _orModels;

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          // ── Datensicherung ─────────────────────────────────────────────
          _SectionHeader(title: 'Datensicherung'),

          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Backup exportieren'),
            subtitle: const Text(
                'Einträge + Anhänge als ZIP – Speicherort frei wählbar'),
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

          // ── Hub-Tabs ──────────────────────────────────────────────────
          _SectionHeader(title: 'Hub-Tabs'),
          _HubTabsManager(),

          const Divider(),

          // ── Tags ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Tags'),
          _TagsManager(),

          const Divider(),

          // ── Vorlagen ────────────────────────────────────────────────────
          _SectionHeader(title: 'Vorlagen'),
          _TemplatesManager(),

          const Divider(),

          // ── Darstellung ────────────────────────────────────────────────
          _SectionHeader(title: 'Darstellung'),
          _ThemeSelector(),

          const Divider(),

          // ── KI (AI-Anreicherung) ───────────────────────────────────────
          _SectionHeader(title: 'KI – Anreicherung'),

          // Provider-Auswahl: Claude / OpenRouter / Lokal (Ollama)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: kProviderAnthropic,
                  label: Text('Claude'),
                  icon: Icon(Icons.hub_outlined),
                ),
                ButtonSegment(
                  value: kProviderOpenRouter,
                  label: Text('OpenRouter'),
                  icon: Icon(Icons.share_outlined),
                ),
                ButtonSegment(
                  value: kProviderOllama,
                  label: Text('Lokal'),
                  icon: Icon(Icons.computer_outlined),
                ),
              ],
              selected: {_provider},
              onSelectionChanged: (s) {
                setState(() => _provider = s.first);
                if (s.first == kProviderOpenRouter && _orModels.isEmpty) {
                  _loadOrModels();
                }
              },
            ),
          ),

          // ── Anthropic ──────────────────────────────────────────────────
          if (_provider == kProviderAnthropic) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _anthKeyCtrl,
                obscureText: _obscureAnthKey,
                decoration: InputDecoration(
                  labelText: 'Anthropic API-Key',
                  hintText: 'sk-ant-...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureAnthKey
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureAnthKey = !_obscureAnthKey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: DropdownButtonFormField<String>(
                initialValue: _anthModel,
                decoration: const InputDecoration(
                  labelText: 'Modell',
                  border: OutlineInputBorder(),
                ),
                items: kAiModels
                    .map((m) => DropdownMenuItem(
                          value: m.$1,
                          child: Text(m.$2),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _anthModel = v);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(
                'API-Key unter console.anthropic.com erstellen '
                '(separates Konto, nicht das claude.ai-Abo).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],

          // ── OpenRouter ─────────────────────────────────────────────────
          if (_provider == kProviderOpenRouter) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _orKeyCtrl,
                obscureText: _obscureOrKey,
                decoration: InputDecoration(
                  labelText: 'OpenRouter API-Key',
                  hintText: 'sk-or-...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOrKey
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureOrKey = !_obscureOrKey),
                  ),
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: const Text('Nur kostenlose Modelle anzeigen'),
              secondary: const Icon(Icons.star_outline),
              value: _onlyFreeOrModels,
              dense: true,
              onChanged: (v) => setState(() => _onlyFreeOrModels = v),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _isLoadingOrModels
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<String>(
                            initialValue:
                                filteredOrModels.any((m) => m.id == _orModel)
                                    ? _orModel
                                    : null,
                            decoration: const InputDecoration(
                              labelText: 'Modell',
                              border: OutlineInputBorder(),
                            ),
                            isExpanded: true,
                            hint: Text(_orModel.isEmpty
                                ? 'Modelle laden…'
                                : _orModel),
                            items: filteredOrModels
                                .map((m) => DropdownMenuItem(
                                      value: m.id,
                                      child: Text(
                                        '${m.isFree ? '✦ ' : ''}${m.name}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _orModel = v);
                            },
                          ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Modelle neu laden',
                    onPressed: _isLoadingOrModels ? null : _loadOrModels,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(
                'API-Key unter openrouter.ai erstellen. '
                'Kostenlose Modelle (✦) sind gratis nutzbar.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],

          // ── Ollama / LM-Studio ─────────────────────────────────────────
          if (_provider == kProviderOllama) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _ollamaBaseUrlCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Server-URL',
                  hintText: 'http://10.0.2.2:11434',
                  border: OutlineInputBorder(),
                  helperText: 'Emulator: 10.0.2.2  |  Gerät: LAN-IP',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _ollamaModelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Modell-Name',
                  hintText: 'llama3.2',
                  border: OutlineInputBorder(),
                  helperText:
                      'LM-Studio: Modell-ID aus dem UI kopieren',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(
                'Ollama und LM-Studio laufen lokal auf deinem Computer. '
                'Kein API-Key nötig. '
                'Für echte Geräte: LAN-IP statt 10.0.2.2 eintragen '
                '(z. B. 192.168.1.42:11434). '
                'LM-Studio nutzt Port 1234.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],

          // Speichern-Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSavingAi ? null : _saveAiSettings,
                child: _isSavingAi
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('KI-Einstellungen speichern'),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Text(
              'API-Keys werden ausschließlich lokal gespeichert und '
              'direkt an den gewählten Anbieter gesendet – kein eigener Server.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),

          const Divider(),

          // ── App-Sperre ─────────────────────────────────────────────────
          _SectionHeader(title: 'Datenschutz'),
          _AppLockTile(),

          const Divider(),

          // ── Info ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Info'),

          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('0.1.0 – Phase 5'),
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
    (ThemeService.kSystem, 'System', 'Folgt dem Gerätemodus',
        Icons.brightness_auto_outlined),
    (ThemeService.kLight, 'Hell', null, Icons.light_mode_outlined),
    (ThemeService.kDark, 'Dunkel', null, Icons.dark_mode_outlined),
    (ThemeService.kOled, 'OLED-Dunkel',
        'Schwarze Pixel – spart Akku auf AMOLED', Icons.smartphone_outlined),
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

// ── Hub-Tab-Verwaltung ─────────────────────────────────────────────────────────

/// Listet alle Hub-Tabs auf und erlaubt Erstellen, Bearbeiten und Löschen.
class _HubTabsManager extends ConsumerWidget {
  const _HubTabsManager();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubsAsync = ref.watch(hubTabsProvider);

    return hubsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const ListTile(
        leading: Icon(Icons.error_outline),
        title: Text('Fehler beim Laden der Hub-Tabs'),
      ),
      data: (hubs) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hubs.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Noch keine Hub-Tabs. Erstelle einen gefilterten Tab für Tags, '
                'Typen oder Status.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ...hubs.map(
            (hub) => ListTile(
              leading: const Icon(Icons.bookmarks_outlined),
              title: Text(hub.name),
              subtitle: hub.filterJson != null ? const Text('Gefiltert') : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Bearbeiten',
                    onPressed: () => showHubFormSheet(context, existing: hub),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Löschen',
                    onPressed: () =>
                        _confirmDelete(context, ref, hub),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Neuen Hub-Tab erstellen'),
            onTap: () => showHubFormSheet(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Container hub,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hub-Tab löschen?'),
        content: Text(
          '„${hub.name}" wird unwiderruflich entfernt.\n'
          'Einträge bleiben erhalten.',
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
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(containerDaoProvider).archiveContainer(hub.id);
    }
  }
}

// ── Tag-Verwaltung ────────────────────────────────────────────────────────────

final _tagsWithCountsProvider = StreamProvider<List<TagWithCount>>((ref) {
  return ref.watch(tagDaoProvider).watchTagsWithCounts();
});

class _TagsManager extends ConsumerWidget {
  const _TagsManager();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_tagsWithCountsProvider);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (tags) {
        if (tags.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              'Noch keine Tags vorhanden. Erstelle Einträge mit #tag.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          );
        }
        return Column(
          children: tags.map((twc) => _TagTile(twc: twc)).toList(),
        );
      },
    );
  }
}

class _TagTile extends ConsumerWidget {
  final TagWithCount twc;

  const _TagTile({required this.twc});

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: twc.tag.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tag umbenennen'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Umbenennen'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != twc.tag.name) {
      await ref.read(tagDaoProvider).renameTag(twc.tag.id, newName);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tag löschen?'),
        content: Text(
          '„#${twc.tag.name}" wird aus allen ${twc.count} Einträgen entfernt.\n'
          'Die #-Erwähnung im Text bleibt erhalten.',
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
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(tagDaoProvider).deleteTagAndLinks(twc.tag.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.label_outline, size: 20),
      title: Text('#${twc.tag.name}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${twc.count}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Umbenennen',
            visualDensity: VisualDensity.compact,
            onPressed: () => _rename(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Löschen',
            visualDensity: VisualDensity.compact,
            color: Theme.of(context).colorScheme.error,
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
    );
  }
}

// ── Vorlagen-Verwaltung ───────────────────────────────────────────────────────

final _templatesProvider = StreamProvider.autoDispose<List<Template>>((ref) {
  return ref.watch(templateDaoProvider).watchAll();
});

/// Zeigt alle Vorlagen an und erlaubt Erstellen, Bearbeiten und Löschen.
class _TemplatesManager extends ConsumerWidget {
  const _TemplatesManager();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_templatesProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (templates) => Column(
        children: [
          ...templates.map(
            (t) => ListTile(
              leading: Text(t.icon, style: const TextStyle(fontSize: 24)),
              title: Text(t.name),
              subtitle: t.description != null
                  ? Text(
                      t.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Bearbeiten',
                    onPressed: () =>
                        showTemplateFormSheet(context, ref, existing: t),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    tooltip: 'Löschen',
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Vorlage löschen?'),
                          content: Text(
                              '„${t.name}" wird dauerhaft gelöscht.'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(ctx).pop(false),
                              child: const Text('Abbrechen'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () =>
                                  Navigator.of(ctx).pop(true),
                              child: const Text('Löschen'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ref
                            .read(templateDaoProvider)
                            .deleteTemplate(t.id);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Neue Vorlage'),
            onTap: () => showTemplateFormSheet(context, ref),
          ),
        ],
      ),
    );
  }
}

// ── App-Sperre ────────────────────────────────────────────────────────────────

/// Toggle für die biometrische App-Sperre.
///
/// Aktivieren und Deaktivieren erfordert jeweils eine erfolgreiche Authentifizierung,
/// damit niemand die Sperre ohne Berechtigung entfernen kann.
class _AppLockTile extends ConsumerStatefulWidget {
  const _AppLockTile();

  @override
  ConsumerState<_AppLockTile> createState() => _AppLockTileState();
}

class _AppLockTileState extends ConsumerState<_AppLockTile> {
  bool _busy = false;

  Future<void> _toggle(bool newValue) async {
    if (_busy) return;

    // Prüfen ob überhaupt Biometrie / Gerätesperre vorhanden ist.
    final canAuth = await AppLockService.canAuthenticate();
    if (!canAuth && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Keine Bildschirmsperre eingerichtet. Bitte zuerst PIN oder Biometrie einrichten.',
          ),
        ),
      );
      return;
    }

    setState(() => _busy = true);

    // Vor jeder Änderung authentifizieren.
    final authenticated = await AppLockService.authenticate();
    if (!authenticated) {
      if (mounted) setState(() => _busy = false);
      return;
    }

    await AppLockService.setEnabled(newValue);
    ref.invalidate(appLockEnabledProvider);

    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue ? 'App-Sperre aktiviert.' : 'App-Sperre deaktiviert.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockAsync = ref.watch(appLockEnabledProvider);
    final enabled = lockAsync.value ?? false;

    return SwitchListTile(
      secondary: const Icon(Icons.lock_outline),
      title: const Text('App-Sperre'),
      subtitle: const Text('Biometrie oder PIN beim Öffnen verlangen'),
      value: enabled,
      onChanged: _busy ? null : _toggle,
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
