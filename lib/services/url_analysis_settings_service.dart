// Datei: lib/services/url_analysis_settings_service.dart
//
// ZWECK: Persistiert die Konfiguration der URL-Analyse-Funktion.
//        Speichert Enabled-Status, YouTube-Toggle und AI-Provider-Wahl.
// ABHÄNGIGKEITEN: path_provider, path, dart:convert.
// MUSTER: Service – zustandslos, nur Datei-I/O.
// PHASE: 6 – URL-Analyse mit KI.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class UrlAnalysisConfig {
  final bool enabled;

  /// YouTube-Transkript laden und in die Analyse einbeziehen.
  final bool youtubeTranscriptEnabled;

  /// Welcher AI-Provider soll die URL-Analyse durchführen?
  /// kSame = gleiche Konfiguration wie „KI – Anreicherung".
  /// kProviderAnthropic / kProviderOpenRouter / kProviderOllama = eigene Wahl.
  final String provider;

  const UrlAnalysisConfig({
    this.enabled = false,
    this.youtubeTranscriptEnabled = true,
    this.provider = UrlAnalysisSettingsService.kSame,
  });

  factory UrlAnalysisConfig.fromJson(Map<String, dynamic> json) =>
      UrlAnalysisConfig(
        enabled: json['enabled'] as bool? ?? false,
        youtubeTranscriptEnabled:
            json['youtubeTranscriptEnabled'] as bool? ?? true,
        provider: json['provider'] as String? ??
            UrlAnalysisSettingsService.kSame,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'youtubeTranscriptEnabled': youtubeTranscriptEnabled,
        'provider': provider,
      };

  UrlAnalysisConfig copyWith({
    bool? enabled,
    bool? youtubeTranscriptEnabled,
    String? provider,
  }) =>
      UrlAnalysisConfig(
        enabled: enabled ?? this.enabled,
        youtubeTranscriptEnabled:
            youtubeTranscriptEnabled ?? this.youtubeTranscriptEnabled,
        provider: provider ?? this.provider,
      );
}

class UrlAnalysisSettingsService {
  static const _fileName = 'url_analysis_settings.json';

  /// Nutzt dieselbe AI-Konfiguration wie „KI – Anreicherung".
  static const kSame = 'same';

  Future<UrlAnalysisConfig> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const UrlAnalysisConfig();
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return UrlAnalysisConfig.fromJson(json);
    } catch (_) {
      return const UrlAnalysisConfig();
    }
  }

  Future<void> save(UrlAnalysisConfig config) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(config.toJson()));
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }
}
