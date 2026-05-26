// Datei: lib/data/db/daos/template_dao.dart
//
// ZWECK: Datenzugriffsobjekt für Vorlagen (Templates).
// ABHÄNGIGKEITEN: database.g.dart (generiert).
// MUSTER: DAO.
// PHASE: 6 – Template-System.

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/templates.dart';

part 'template_dao.g.dart';

@DriftAccessor(tables: [Templates])
class TemplateDao extends DatabaseAccessor<AppDatabase> with _$TemplateDaoMixin {
  TemplateDao(super.db);

  /// Beobachtet alle Templates als reaktiven Stream.
  Stream<List<Template>> watchAll() =>
      (select(templates)..orderBy([(t) => OrderingTerm(expression: t.name)]))
          .watch();

  /// Gibt alle Templates einmalig zurück.
  Future<List<Template>> getAll() =>
      (select(templates)..orderBy([(t) => OrderingTerm(expression: t.name)]))
          .get();

  /// Legt ein neues Template an.
  Future<void> insertTemplate(TemplatesCompanion template) =>
      into(templates).insert(template);

  /// Aktualisiert ein bestehendes Template.
  Future<void> updateTemplate(TemplatesCompanion template) =>
      (update(templates)..where((t) => t.id.equals(template.id.value)))
          .write(template);

  /// Löscht ein Template anhand seiner ID.
  Future<int> deleteTemplate(String id) =>
      (delete(templates)..where((t) => t.id.equals(id))).go();
}
