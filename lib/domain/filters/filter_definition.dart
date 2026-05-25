// Datei: lib/domain/filters/filter_definition.dart
//
// ZWECK: Datenmodell für die Filter-Konfiguration eines Hub-Tabs.
//        Wird als JSON in containers.filter_json gespeichert.
// ABHÄNGIGKEITEN: dart:convert.

import 'dart:convert';

/// Beschreibt, welche Einträge ein Hub-Tab anzeigen soll.
///
/// Alle Listen sind additiv (AND-Logik zwischen Feldern, OR-Logik innerhalb
/// einer Liste). Ein leeres FilterDefinition-Objekt zeigt alle Einträge.
class FilterDefinition {
  /// Einträge mit MINDESTENS EINEM dieser Tags werden angezeigt.
  final List<String> tagsAny;

  /// Nur Einträge dieser Typen ('text', 'link', 'image', 'audio', 'mixed').
  final List<String> typeIn;

  /// Nur Einträge mit diesen Status-Werten ('inbox', 'active', 'done', 'archived').
  final List<String> statusIn;

  /// Nur Einträge, die dem Container mit dieser ID zugewiesen sind.
  final String? containerId;

  const FilterDefinition({
    this.tagsAny = const [],
    this.typeIn = const [],
    this.statusIn = const [],
    this.containerId,
  });

  factory FilterDefinition.fromJson(Map<String, dynamic> json) {
    return FilterDefinition(
      tagsAny: List<String>.from(json['tags_any'] as List? ?? []),
      typeIn: List<String>.from(json['type_in'] as List? ?? []),
      statusIn: List<String>.from(json['status_in'] as List? ?? []),
      containerId: json['container_id'] as String?,
    );
  }

  factory FilterDefinition.fromJsonString(String jsonStr) {
    return FilterDefinition.fromJson(
      jsonDecode(jsonStr) as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {
        'tags_any': tagsAny,
        'type_in': typeIn,
        'status_in': statusIn,
        'container_id': containerId,
      };

  String toJsonString() => jsonEncode(toJson());

  bool get isEmpty =>
      tagsAny.isEmpty &&
      typeIn.isEmpty &&
      statusIn.isEmpty &&
      containerId == null;

  FilterDefinition copyWith({
    List<String>? tagsAny,
    List<String>? typeIn,
    List<String>? statusIn,
    String? containerId,
    bool clearContainerId = false,
  }) {
    return FilterDefinition(
      tagsAny: tagsAny ?? this.tagsAny,
      typeIn: typeIn ?? this.typeIn,
      statusIn: statusIn ?? this.statusIn,
      containerId: clearContainerId ? null : (containerId ?? this.containerId),
    );
  }
}
