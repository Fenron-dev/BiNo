// Datei: lib/features/templates/template_picker_sheet.dart
//
// ZWECK: Bottom-Sheet zur Template-Auswahl im CaptureSheet.
//        Gibt den ausgewählten bodyTemplate-Text zurück.
// ABHÄNGIGKEITEN: templateDaoProvider.
// PHASE: 6 – Template-System.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../data/db/database.dart';

/// Öffnet den Template-Picker und gibt den gewählten bodyTemplate-Text zurück.
/// Gibt null zurück wenn abgebrochen oder kein Text vorhanden.
Future<String?> showTemplatePickerSheet(
    BuildContext context, WidgetRef ref) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TemplatePickerSheet(ref: ref),
  );
}

class _TemplatePickerSheet extends ConsumerWidget {
  final WidgetRef ref;

  const _TemplatePickerSheet({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef innerRef) {
    final templatesAsync = innerRef.watch(
      StreamProvider.autoDispose<List<Template>>((r) {
        return r.watch(templateDaoProvider).watchAll();
      }),
    );

    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Text('Vorlage wählen', style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: templatesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Fehler beim Laden der Vorlagen.')),
              data: (templates) {
                if (templates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.description_outlined,
                            size: 48,
                            color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text(
                          'Noch keine Vorlagen.\nLege Vorlagen in den Einstellungen an.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: templates.length,
                  itemBuilder: (context, i) {
                    final t = templates[i];
                    return ListTile(
                      leading: Text(t.icon,
                          style: const TextStyle(fontSize: 24)),
                      title: Text(t.name),
                      subtitle: t.description != null
                          ? Text(
                              t.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : t.bodyTemplate.isNotEmpty
                              ? Text(
                                  t.bodyTemplate,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : null,
                      onTap: () => Navigator.of(context).pop(t.bodyTemplate),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
