// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('inbox'),
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _geoLatMeta = const VerificationMeta('geoLat');
  @override
  late final GeneratedColumn<double> geoLat = GeneratedColumn<double>(
    'geo_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _geoLngMeta = const VerificationMeta('geoLng');
  @override
  late final GeneratedColumn<double> geoLng = GeneratedColumn<double>(
    'geo_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderAtMeta = const VerificationMeta(
    'reminderAt',
  );
  @override
  late final GeneratedColumn<DateTime> reminderAt = GeneratedColumn<DateTime>(
    'reminder_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceAppMeta = const VerificationMeta(
    'sourceApp',
  );
  @override
  late final GeneratedColumn<String> sourceApp = GeneratedColumn<String>(
    'source_app',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _embeddingMeta = const VerificationMeta(
    'embedding',
  );
  @override
  late final GeneratedColumn<Uint8List> embedding = GeneratedColumn<Uint8List>(
    'embedding',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiEnrichedAtMeta = const VerificationMeta(
    'aiEnrichedAt',
  );
  @override
  late final GeneratedColumn<DateTime> aiEnrichedAt = GeneratedColumn<DateTime>(
    'ai_enriched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    type,
    title,
    body,
    status,
    pinned,
    geoLat,
    geoLng,
    reminderAt,
    sourceUrl,
    sourceApp,
    embedding,
    aiEnrichedAt,
    lang,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('geo_lat')) {
      context.handle(
        _geoLatMeta,
        geoLat.isAcceptableOrUnknown(data['geo_lat']!, _geoLatMeta),
      );
    }
    if (data.containsKey('geo_lng')) {
      context.handle(
        _geoLngMeta,
        geoLng.isAcceptableOrUnknown(data['geo_lng']!, _geoLngMeta),
      );
    }
    if (data.containsKey('reminder_at')) {
      context.handle(
        _reminderAtMeta,
        reminderAt.isAcceptableOrUnknown(data['reminder_at']!, _reminderAtMeta),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('source_app')) {
      context.handle(
        _sourceAppMeta,
        sourceApp.isAcceptableOrUnknown(data['source_app']!, _sourceAppMeta),
      );
    }
    if (data.containsKey('embedding')) {
      context.handle(
        _embeddingMeta,
        embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta),
      );
    }
    if (data.containsKey('ai_enriched_at')) {
      context.handle(
        _aiEnrichedAtMeta,
        aiEnrichedAt.isAcceptableOrUnknown(
          data['ai_enriched_at']!,
          _aiEnrichedAtMeta,
        ),
      );
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      geoLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}geo_lat'],
      ),
      geoLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}geo_lng'],
      ),
      reminderAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reminder_at'],
      ),
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
      sourceApp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_app'],
      ),
      embedding: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}embedding'],
      ),
      aiEnrichedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ai_enriched_at'],
      ),
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      ),
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }
}

class Entry extends DataClass implements Insertable<Entry> {
  /// UUID-Primärschlüssel. Wird im Repository via `uuid`-Paket generiert.
  final String id;

  /// Erfassungszeitpunkt (UTC). Wird einmalig beim Erstellen gesetzt.
  /// clientDefault nutzt Dart-seitige Logik – funktioniert ohne DB-Trigger.
  final DateTime createdAt;

  /// Letzter Änderungszeitpunkt (UTC). Wird bei jedem Update manuell gesetzt.
  final DateTime updatedAt;

  /// Eintragstyp als TEXT (z. B. 'text', 'link'). Standard: 'text'.
  final String type;

  /// Optionaler Titel. Wenn leer, generiert die UI eine Vorschau aus dem Body.
  final String? title;

  /// Hauptinhalt als Markdown-String. Unterstützt #tags und [[Wikilinks]].
  /// Nie null – leerer String für Nicht-Text-Typen.
  final String body;

  /// Bearbeitungsstatus. Standard 'inbox' = neu erfasst, noch unbearbeitet.
  final String status;

  /// Angepinnte Einträge erscheinen sticky oben im Feed (max. 5 per UI-Schicht).
  final bool pinned;

  /// Optionaler Standort. Beide Felder sind entweder beide gesetzt oder beide null.
  final double? geoLat;
  final double? geoLng;

  /// Erinnerungszeitpunkt für flutter_local_notifications (Phase 6).
  final DateTime? reminderAt;

  /// Quell-URL bei Link-Einträgen oder Share-Intent (Phase 2).
  final String? sourceUrl;

  /// Herkunfts-App bei Share-Intent, z. B. 'com.google.android.youtube' (Phase 2).
  final String? sourceApp;

  /// 384-dimensionaler float32-Einbettungsvektor (Phase 3: ONNX + sqlite-vec).
  /// Als BLOB gespeichert. Null, bis der Embedding-Service den Eintrag verarbeitet hat.
  final Uint8List? embedding;

  /// Zeitpunkt, wann zuletzt eine Cloud-KI den Eintrag angereichert hat (Phase 5).
  final DateTime? aiEnrichedAt;

  /// ISO-639-1-Sprachcode, erkannt von ML Kit Language ID (Phase 3).
  final String? lang;
  const Entry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    this.title,
    required this.body,
    required this.status,
    required this.pinned,
    this.geoLat,
    this.geoLng,
    this.reminderAt,
    this.sourceUrl,
    this.sourceApp,
    this.embedding,
    this.aiEnrichedAt,
    this.lang,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['body'] = Variable<String>(body);
    map['status'] = Variable<String>(status);
    map['pinned'] = Variable<bool>(pinned);
    if (!nullToAbsent || geoLat != null) {
      map['geo_lat'] = Variable<double>(geoLat);
    }
    if (!nullToAbsent || geoLng != null) {
      map['geo_lng'] = Variable<double>(geoLng);
    }
    if (!nullToAbsent || reminderAt != null) {
      map['reminder_at'] = Variable<DateTime>(reminderAt);
    }
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    if (!nullToAbsent || sourceApp != null) {
      map['source_app'] = Variable<String>(sourceApp);
    }
    if (!nullToAbsent || embedding != null) {
      map['embedding'] = Variable<Uint8List>(embedding);
    }
    if (!nullToAbsent || aiEnrichedAt != null) {
      map['ai_enriched_at'] = Variable<DateTime>(aiEnrichedAt);
    }
    if (!nullToAbsent || lang != null) {
      map['lang'] = Variable<String>(lang);
    }
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      type: Value(type),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      body: Value(body),
      status: Value(status),
      pinned: Value(pinned),
      geoLat: geoLat == null && nullToAbsent
          ? const Value.absent()
          : Value(geoLat),
      geoLng: geoLng == null && nullToAbsent
          ? const Value.absent()
          : Value(geoLng),
      reminderAt: reminderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderAt),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      sourceApp: sourceApp == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceApp),
      embedding: embedding == null && nullToAbsent
          ? const Value.absent()
          : Value(embedding),
      aiEnrichedAt: aiEnrichedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(aiEnrichedAt),
      lang: lang == null && nullToAbsent ? const Value.absent() : Value(lang),
    );
  }

  factory Entry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String?>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      status: serializer.fromJson<String>(json['status']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      geoLat: serializer.fromJson<double?>(json['geoLat']),
      geoLng: serializer.fromJson<double?>(json['geoLng']),
      reminderAt: serializer.fromJson<DateTime?>(json['reminderAt']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      sourceApp: serializer.fromJson<String?>(json['sourceApp']),
      embedding: serializer.fromJson<Uint8List?>(json['embedding']),
      aiEnrichedAt: serializer.fromJson<DateTime?>(json['aiEnrichedAt']),
      lang: serializer.fromJson<String?>(json['lang']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String?>(title),
      'body': serializer.toJson<String>(body),
      'status': serializer.toJson<String>(status),
      'pinned': serializer.toJson<bool>(pinned),
      'geoLat': serializer.toJson<double?>(geoLat),
      'geoLng': serializer.toJson<double?>(geoLng),
      'reminderAt': serializer.toJson<DateTime?>(reminderAt),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'sourceApp': serializer.toJson<String?>(sourceApp),
      'embedding': serializer.toJson<Uint8List?>(embedding),
      'aiEnrichedAt': serializer.toJson<DateTime?>(aiEnrichedAt),
      'lang': serializer.toJson<String?>(lang),
    };
  }

  Entry copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? type,
    Value<String?> title = const Value.absent(),
    String? body,
    String? status,
    bool? pinned,
    Value<double?> geoLat = const Value.absent(),
    Value<double?> geoLng = const Value.absent(),
    Value<DateTime?> reminderAt = const Value.absent(),
    Value<String?> sourceUrl = const Value.absent(),
    Value<String?> sourceApp = const Value.absent(),
    Value<Uint8List?> embedding = const Value.absent(),
    Value<DateTime?> aiEnrichedAt = const Value.absent(),
    Value<String?> lang = const Value.absent(),
  }) => Entry(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    type: type ?? this.type,
    title: title.present ? title.value : this.title,
    body: body ?? this.body,
    status: status ?? this.status,
    pinned: pinned ?? this.pinned,
    geoLat: geoLat.present ? geoLat.value : this.geoLat,
    geoLng: geoLng.present ? geoLng.value : this.geoLng,
    reminderAt: reminderAt.present ? reminderAt.value : this.reminderAt,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    sourceApp: sourceApp.present ? sourceApp.value : this.sourceApp,
    embedding: embedding.present ? embedding.value : this.embedding,
    aiEnrichedAt: aiEnrichedAt.present ? aiEnrichedAt.value : this.aiEnrichedAt,
    lang: lang.present ? lang.value : this.lang,
  );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      status: data.status.present ? data.status.value : this.status,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      geoLat: data.geoLat.present ? data.geoLat.value : this.geoLat,
      geoLng: data.geoLng.present ? data.geoLng.value : this.geoLng,
      reminderAt: data.reminderAt.present
          ? data.reminderAt.value
          : this.reminderAt,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      sourceApp: data.sourceApp.present ? data.sourceApp.value : this.sourceApp,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
      aiEnrichedAt: data.aiEnrichedAt.present
          ? data.aiEnrichedAt.value
          : this.aiEnrichedAt,
      lang: data.lang.present ? data.lang.value : this.lang,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('status: $status, ')
          ..write('pinned: $pinned, ')
          ..write('geoLat: $geoLat, ')
          ..write('geoLng: $geoLng, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceApp: $sourceApp, ')
          ..write('embedding: $embedding, ')
          ..write('aiEnrichedAt: $aiEnrichedAt, ')
          ..write('lang: $lang')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    type,
    title,
    body,
    status,
    pinned,
    geoLat,
    geoLng,
    reminderAt,
    sourceUrl,
    sourceApp,
    $driftBlobEquality.hash(embedding),
    aiEnrichedAt,
    lang,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.type == this.type &&
          other.title == this.title &&
          other.body == this.body &&
          other.status == this.status &&
          other.pinned == this.pinned &&
          other.geoLat == this.geoLat &&
          other.geoLng == this.geoLng &&
          other.reminderAt == this.reminderAt &&
          other.sourceUrl == this.sourceUrl &&
          other.sourceApp == this.sourceApp &&
          $driftBlobEquality.equals(other.embedding, this.embedding) &&
          other.aiEnrichedAt == this.aiEnrichedAt &&
          other.lang == this.lang);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> type;
  final Value<String?> title;
  final Value<String> body;
  final Value<String> status;
  final Value<bool> pinned;
  final Value<double?> geoLat;
  final Value<double?> geoLng;
  final Value<DateTime?> reminderAt;
  final Value<String?> sourceUrl;
  final Value<String?> sourceApp;
  final Value<Uint8List?> embedding;
  final Value<DateTime?> aiEnrichedAt;
  final Value<String?> lang;
  final Value<int> rowid;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.status = const Value.absent(),
    this.pinned = const Value.absent(),
    this.geoLat = const Value.absent(),
    this.geoLng = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.sourceApp = const Value.absent(),
    this.embedding = const Value.absent(),
    this.aiEnrichedAt = const Value.absent(),
    this.lang = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntriesCompanion.insert({
    required String id,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.status = const Value.absent(),
    this.pinned = const Value.absent(),
    this.geoLat = const Value.absent(),
    this.geoLng = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.sourceApp = const Value.absent(),
    this.embedding = const Value.absent(),
    this.aiEnrichedAt = const Value.absent(),
    this.lang = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Entry> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? status,
    Expression<bool>? pinned,
    Expression<double>? geoLat,
    Expression<double>? geoLng,
    Expression<DateTime>? reminderAt,
    Expression<String>? sourceUrl,
    Expression<String>? sourceApp,
    Expression<Uint8List>? embedding,
    Expression<DateTime>? aiEnrichedAt,
    Expression<String>? lang,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (status != null) 'status': status,
      if (pinned != null) 'pinned': pinned,
      if (geoLat != null) 'geo_lat': geoLat,
      if (geoLng != null) 'geo_lng': geoLng,
      if (reminderAt != null) 'reminder_at': reminderAt,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (sourceApp != null) 'source_app': sourceApp,
      if (embedding != null) 'embedding': embedding,
      if (aiEnrichedAt != null) 'ai_enriched_at': aiEnrichedAt,
      if (lang != null) 'lang': lang,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? type,
    Value<String?>? title,
    Value<String>? body,
    Value<String>? status,
    Value<bool>? pinned,
    Value<double?>? geoLat,
    Value<double?>? geoLng,
    Value<DateTime?>? reminderAt,
    Value<String?>? sourceUrl,
    Value<String?>? sourceApp,
    Value<Uint8List?>? embedding,
    Value<DateTime?>? aiEnrichedAt,
    Value<String?>? lang,
    Value<int>? rowid,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      status: status ?? this.status,
      pinned: pinned ?? this.pinned,
      geoLat: geoLat ?? this.geoLat,
      geoLng: geoLng ?? this.geoLng,
      reminderAt: reminderAt ?? this.reminderAt,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceApp: sourceApp ?? this.sourceApp,
      embedding: embedding ?? this.embedding,
      aiEnrichedAt: aiEnrichedAt ?? this.aiEnrichedAt,
      lang: lang ?? this.lang,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (geoLat.present) {
      map['geo_lat'] = Variable<double>(geoLat.value);
    }
    if (geoLng.present) {
      map['geo_lng'] = Variable<double>(geoLng.value);
    }
    if (reminderAt.present) {
      map['reminder_at'] = Variable<DateTime>(reminderAt.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (sourceApp.present) {
      map['source_app'] = Variable<String>(sourceApp.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<Uint8List>(embedding.value);
    }
    if (aiEnrichedAt.present) {
      map['ai_enriched_at'] = Variable<DateTime>(aiEnrichedAt.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('status: $status, ')
          ..write('pinned: $pinned, ')
          ..write('geoLat: $geoLat, ')
          ..write('geoLng: $geoLng, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceApp: $sourceApp, ')
          ..write('embedding: $embedding, ')
          ..write('aiEnrichedAt: $aiEnrichedAt, ')
          ..write('lang: $lang, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, parentId, color, icon];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  /// UUID-Primärschlüssel.
  final String id;

  /// Vollständiger hierarchischer Tag-Name, z. B. 'buch/sachbuch/psychologie'.
  final String name;

  /// Referenz auf den Eltern-Tag. Null = Root-Tag.
  /// Keine Drift-FK-Referenz hier, da Drift DSL-FKs das Schema verkomplizieren.
  /// Die Integrität wird im Repository via _findOrCreateTag sichergestellt.
  final String? parentId;

  /// Hex-Farbe, z. B. '#FF5733'. Null = Theme-Standard.
  final String? color;

  /// Material-Icon-Name oder eigener Bezeichner. Null = Standard-Tag-Icon.
  final String? icon;
  const Tag({
    required this.id,
    required this.name,
    this.parentId,
    this.color,
    this.icon,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      color: serializer.fromJson<String?>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'color': serializer.toJson<String?>(color),
      'icon': serializer.toJson<String?>(icon),
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    Value<String?> parentId = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<String?> icon = const Value.absent(),
  }) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    color: color.present ? color.value : this.color,
    icon: icon.present ? icon.value : this.icon,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('color: $color, ')
          ..write('icon: $icon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, parentId, color, icon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.color == this.color &&
          other.icon == this.icon);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<String?> color;
  final Value<String?> icon;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    this.parentId = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? parentId,
    Value<String?>? color,
    Value<String?>? icon,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntryTagsTable extends EntryTags
    with TableInfo<$EntryTagsTable, EntryTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entryId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId, tagId};
  @override
  EntryTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryTag(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $EntryTagsTable createAlias(String alias) {
    return $EntryTagsTable(attachedDatabase, alias);
  }
}

class EntryTag extends DataClass implements Insertable<EntryTag> {
  /// Referenz auf entries.id
  final String entryId;

  /// Referenz auf tags.id
  final String tagId;
  const EntryTag({required this.entryId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  EntryTagsCompanion toCompanion(bool nullToAbsent) {
    return EntryTagsCompanion(entryId: Value(entryId), tagId: Value(tagId));
  }

  factory EntryTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryTag(
      entryId: serializer.fromJson<String>(json['entryId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<String>(entryId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  EntryTag copyWith({String? entryId, String? tagId}) =>
      EntryTag(entryId: entryId ?? this.entryId, tagId: tagId ?? this.tagId);
  EntryTag copyWithCompanion(EntryTagsCompanion data) {
    return EntryTag(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryTag(')
          ..write('entryId: $entryId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entryId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryTag &&
          other.entryId == this.entryId &&
          other.tagId == this.tagId);
}

class EntryTagsCompanion extends UpdateCompanion<EntryTag> {
  final Value<String> entryId;
  final Value<String> tagId;
  final Value<int> rowid;
  const EntryTagsCompanion({
    this.entryId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryTagsCompanion.insert({
    required String entryId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       tagId = Value(tagId);
  static Insertable<EntryTag> custom({
    Expression<String>? entryId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryTagsCompanion copyWith({
    Value<String>? entryId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return EntryTagsCompanion(
      entryId: entryId ?? this.entryId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryTagsCompanion(')
          ..write('entryId: $entryId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContainersTable extends Containers
    with TableInfo<$ContainersTable, Container> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContainersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('folder'),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#6750A4'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _filterJsonMeta = const VerificationMeta(
    'filterJson',
  );
  @override
  late final GeneratedColumn<String> filterJson = GeneratedColumn<String>(
    'filter_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    name,
    description,
    icon,
    color,
    createdAt,
    archived,
    filterJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'containers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Container> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('filter_json')) {
      context.handle(
        _filterJsonMeta,
        filterJson.isAcceptableOrUnknown(data['filter_json']!, _filterJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Container map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Container(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      filterJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_json'],
      ),
    );
  }

  @override
  $ContainersTable createAlias(String alias) {
    return $ContainersTable(attachedDatabase, alias);
  }
}

class Container extends DataClass implements Insertable<Container> {
  /// UUID-Primärschlüssel.
  final String id;

  /// Art des Containers:
  /// - 'project': zeitlich begrenztes Vorhaben
  /// - 'area':    dauerhafter Lebensbereich (Arbeit, Hobby, ...)
  /// - 'hub':     dynamischer Filter-Tab (Phase 4), verknüpft mit filter_json
  final String kind;
  final String name;
  final String? description;

  /// Material-Icon-Name als String, z. B. 'folder' oder 'book'.
  /// Pflichtfeld – jeder Container braucht eine visuelle Identität.
  final String icon;

  /// Hex-Akzentfarbe, z. B. '#6750A4'. Pflichtfeld für die Karten-Darstellung.
  final String color;
  final DateTime createdAt;

  /// WARUM 'archived' statt Löschen?
  /// Archivierte Container werden in der UI ausgeblendet, aber verknüpfte
  /// Einträge behalten ihre Container-Zuweisungen. Das verhindert verwaiste
  /// Einträge und ermöglicht Restore.
  final bool archived;

  /// JSON-Filter-Definition für Hub-Tabs (Phase 4).
  /// Null für 'project' und 'area'. Bei 'hub': JSON gemäß FilterDefinition-Schema.
  final String? filterJson;
  const Container({
    required this.id,
    required this.kind,
    required this.name,
    this.description,
    required this.icon,
    required this.color,
    required this.createdAt,
    required this.archived,
    this.filterJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['icon'] = Variable<String>(icon);
    map['color'] = Variable<String>(color);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || filterJson != null) {
      map['filter_json'] = Variable<String>(filterJson);
    }
    return map;
  }

  ContainersCompanion toCompanion(bool nullToAbsent) {
    return ContainersCompanion(
      id: Value(id),
      kind: Value(kind),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      icon: Value(icon),
      color: Value(color),
      createdAt: Value(createdAt),
      archived: Value(archived),
      filterJson: filterJson == null && nullToAbsent
          ? const Value.absent()
          : Value(filterJson),
    );
  }

  factory Container.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Container(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<String>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archived: serializer.fromJson<bool>(json['archived']),
      filterJson: serializer.fromJson<String?>(json['filterJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<String>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archived': serializer.toJson<bool>(archived),
      'filterJson': serializer.toJson<String?>(filterJson),
    };
  }

  Container copyWith({
    String? id,
    String? kind,
    String? name,
    Value<String?> description = const Value.absent(),
    String? icon,
    String? color,
    DateTime? createdAt,
    bool? archived,
    Value<String?> filterJson = const Value.absent(),
  }) => Container(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    createdAt: createdAt ?? this.createdAt,
    archived: archived ?? this.archived,
    filterJson: filterJson.present ? filterJson.value : this.filterJson,
  );
  Container copyWithCompanion(ContainersCompanion data) {
    return Container(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archived: data.archived.present ? data.archived.value : this.archived,
      filterJson: data.filterJson.present
          ? data.filterJson.value
          : this.filterJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Container(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('archived: $archived, ')
          ..write('filterJson: $filterJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    name,
    description,
    icon,
    color,
    createdAt,
    archived,
    filterJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Container &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.description == this.description &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.createdAt == this.createdAt &&
          other.archived == this.archived &&
          other.filterJson == this.filterJson);
}

class ContainersCompanion extends UpdateCompanion<Container> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> icon;
  final Value<String> color;
  final Value<DateTime> createdAt;
  final Value<bool> archived;
  final Value<String?> filterJson;
  final Value<int> rowid;
  const ContainersCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archived = const Value.absent(),
    this.filterJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContainersCompanion.insert({
    required String id,
    required String kind,
    required String name,
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archived = const Value.absent(),
    this.filterJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       name = Value(name);
  static Insertable<Container> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<DateTime>? createdAt,
    Expression<bool>? archived,
    Expression<String>? filterJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
      if (archived != null) 'archived': archived,
      if (filterJson != null) 'filter_json': filterJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContainersCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? icon,
    Value<String>? color,
    Value<DateTime>? createdAt,
    Value<bool>? archived,
    Value<String?>? filterJson,
    Value<int>? rowid,
  }) {
    return ContainersCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      archived: archived ?? this.archived,
      filterJson: filterJson ?? this.filterJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (filterJson.present) {
      map['filter_json'] = Variable<String>(filterJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContainersCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('archived: $archived, ')
          ..write('filterJson: $filterJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntryContainersTable extends EntryContainers
    with TableInfo<$EntryContainersTable, EntryContainer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryContainersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _containerIdMeta = const VerificationMeta(
    'containerId',
  );
  @override
  late final GeneratedColumn<String> containerId = GeneratedColumn<String>(
    'container_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entryId, containerId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_containers';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryContainer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('container_id')) {
      context.handle(
        _containerIdMeta,
        containerId.isAcceptableOrUnknown(
          data['container_id']!,
          _containerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_containerIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId, containerId};
  @override
  EntryContainer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryContainer(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      containerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_id'],
      )!,
    );
  }

  @override
  $EntryContainersTable createAlias(String alias) {
    return $EntryContainersTable(attachedDatabase, alias);
  }
}

class EntryContainer extends DataClass implements Insertable<EntryContainer> {
  final String entryId;
  final String containerId;
  const EntryContainer({required this.entryId, required this.containerId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['container_id'] = Variable<String>(containerId);
    return map;
  }

  EntryContainersCompanion toCompanion(bool nullToAbsent) {
    return EntryContainersCompanion(
      entryId: Value(entryId),
      containerId: Value(containerId),
    );
  }

  factory EntryContainer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryContainer(
      entryId: serializer.fromJson<String>(json['entryId']),
      containerId: serializer.fromJson<String>(json['containerId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<String>(entryId),
      'containerId': serializer.toJson<String>(containerId),
    };
  }

  EntryContainer copyWith({String? entryId, String? containerId}) =>
      EntryContainer(
        entryId: entryId ?? this.entryId,
        containerId: containerId ?? this.containerId,
      );
  EntryContainer copyWithCompanion(EntryContainersCompanion data) {
    return EntryContainer(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      containerId: data.containerId.present
          ? data.containerId.value
          : this.containerId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryContainer(')
          ..write('entryId: $entryId, ')
          ..write('containerId: $containerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entryId, containerId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryContainer &&
          other.entryId == this.entryId &&
          other.containerId == this.containerId);
}

class EntryContainersCompanion extends UpdateCompanion<EntryContainer> {
  final Value<String> entryId;
  final Value<String> containerId;
  final Value<int> rowid;
  const EntryContainersCompanion({
    this.entryId = const Value.absent(),
    this.containerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryContainersCompanion.insert({
    required String entryId,
    required String containerId,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       containerId = Value(containerId);
  static Insertable<EntryContainer> custom({
    Expression<String>? entryId,
    Expression<String>? containerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (containerId != null) 'container_id': containerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryContainersCompanion copyWith({
    Value<String>? entryId,
    Value<String>? containerId,
    Value<int>? rowid,
  }) {
    return EntryContainersCompanion(
      entryId: entryId ?? this.entryId,
      containerId: containerId ?? this.containerId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (containerId.present) {
      map['container_id'] = Variable<String>(containerId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryContainersCompanion(')
          ..write('entryId: $entryId, ')
          ..write('containerId: $containerId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transcriptionMeta = const VerificationMeta(
    'transcription',
  );
  @override
  late final GeneratedColumn<String> transcription = GeneratedColumn<String>(
    'transcription',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ocrTextMeta = const VerificationMeta(
    'ocrText',
  );
  @override
  late final GeneratedColumn<String> ocrText = GeneratedColumn<String>(
    'ocr_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    filePath,
    mimeType,
    size,
    width,
    height,
    durationMs,
    transcription,
    ocrText,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('transcription')) {
      context.handle(
        _transcriptionMeta,
        transcription.isAcceptableOrUnknown(
          data['transcription']!,
          _transcriptionMeta,
        ),
      );
    }
    if (data.containsKey('ocr_text')) {
      context.handle(
        _ocrTextMeta,
        ocrText.isAcceptableOrUnknown(data['ocr_text']!, _ocrTextMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      transcription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcription'],
      ),
      ocrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_text'],
      ),
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  /// UUID-Primärschlüssel.
  final String id;

  /// Referenz auf den zugehörigen Eintrag. Löschen des Eintrags muss
  /// im EntryDao die Anhänge mitlöschen (kaskadierend, Phase 2).
  final String entryId;

  /// Relativer Pfad zum Anhang, z. B. '2025/05/audio_abc123.m4a'.
  final String filePath;

  /// MIME-Typ, z. B. 'image/jpeg', 'audio/mp4', 'video/mp4'.
  final String mimeType;

  /// Dateigröße in Byte.
  final int size;

  /// Bildbreite in Pixeln. Null bei Nicht-Bild-Typen.
  final int? width;

  /// Bildhöhe in Pixeln. Null bei Nicht-Bild-Typen.
  final int? height;

  /// Audio-/Videolänge in Millisekunden. Null bei Nicht-Audio/Video-Typen.
  final int? durationMs;

  /// Transkriptionstext (Phase 2: speech_to_text). Null bis verarbeitet.
  final String? transcription;

  /// OCR-Text (Phase 2: google_mlkit_text_recognition). Null bis verarbeitet.
  /// Wird Teil des FTS5-Index, aber NICHT automatisch in den Entry-Body übernommen.
  /// Der Nutzer entscheidet via "Text übernehmen"-Aktion, ob er den Text im Body sehen will.
  final String? ocrText;
  const Attachment({
    required this.id,
    required this.entryId,
    required this.filePath,
    required this.mimeType,
    required this.size,
    this.width,
    this.height,
    this.durationMs,
    this.transcription,
    this.ocrText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['file_path'] = Variable<String>(filePath);
    map['mime_type'] = Variable<String>(mimeType);
    map['size'] = Variable<int>(size);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || transcription != null) {
      map['transcription'] = Variable<String>(transcription);
    }
    if (!nullToAbsent || ocrText != null) {
      map['ocr_text'] = Variable<String>(ocrText);
    }
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      filePath: Value(filePath),
      mimeType: Value(mimeType),
      size: Value(size),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      transcription: transcription == null && nullToAbsent
          ? const Value.absent()
          : Value(transcription),
      ocrText: ocrText == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrText),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      size: serializer.fromJson<int>(json['size']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      transcription: serializer.fromJson<String?>(json['transcription']),
      ocrText: serializer.fromJson<String?>(json['ocrText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'filePath': serializer.toJson<String>(filePath),
      'mimeType': serializer.toJson<String>(mimeType),
      'size': serializer.toJson<int>(size),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'durationMs': serializer.toJson<int?>(durationMs),
      'transcription': serializer.toJson<String?>(transcription),
      'ocrText': serializer.toJson<String?>(ocrText),
    };
  }

  Attachment copyWith({
    String? id,
    String? entryId,
    String? filePath,
    String? mimeType,
    int? size,
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    Value<String?> transcription = const Value.absent(),
    Value<String?> ocrText = const Value.absent(),
  }) => Attachment(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    filePath: filePath ?? this.filePath,
    mimeType: mimeType ?? this.mimeType,
    size: size ?? this.size,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    transcription: transcription.present
        ? transcription.value
        : this.transcription,
    ocrText: ocrText.present ? ocrText.value : this.ocrText,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      size: data.size.present ? data.size.value : this.size,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      transcription: data.transcription.present
          ? data.transcription.value
          : this.transcription,
      ocrText: data.ocrText.present ? data.ocrText.value : this.ocrText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('filePath: $filePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('size: $size, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationMs: $durationMs, ')
          ..write('transcription: $transcription, ')
          ..write('ocrText: $ocrText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entryId,
    filePath,
    mimeType,
    size,
    width,
    height,
    durationMs,
    transcription,
    ocrText,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.filePath == this.filePath &&
          other.mimeType == this.mimeType &&
          other.size == this.size &&
          other.width == this.width &&
          other.height == this.height &&
          other.durationMs == this.durationMs &&
          other.transcription == this.transcription &&
          other.ocrText == this.ocrText);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> id;
  final Value<String> entryId;
  final Value<String> filePath;
  final Value<String> mimeType;
  final Value<int> size;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> durationMs;
  final Value<String?> transcription;
  final Value<String?> ocrText;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.size = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.transcription = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String entryId,
    required String filePath,
    required String mimeType,
    required int size,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.transcription = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       filePath = Value(filePath),
       mimeType = Value(mimeType),
       size = Value(size);
  static Insertable<Attachment> custom({
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<String>? filePath,
    Expression<String>? mimeType,
    Expression<int>? size,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? durationMs,
    Expression<String>? transcription,
    Expression<String>? ocrText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (filePath != null) 'file_path': filePath,
      if (mimeType != null) 'mime_type': mimeType,
      if (size != null) 'size': size,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (durationMs != null) 'duration_ms': durationMs,
      if (transcription != null) 'transcription': transcription,
      if (ocrText != null) 'ocr_text': ocrText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? entryId,
    Value<String>? filePath,
    Value<String>? mimeType,
    Value<int>? size,
    Value<int?>? width,
    Value<int?>? height,
    Value<int?>? durationMs,
    Value<String?>? transcription,
    Value<String?>? ocrText,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      width: width ?? this.width,
      height: height ?? this.height,
      durationMs: durationMs ?? this.durationMs,
      transcription: transcription ?? this.transcription,
      ocrText: ocrText ?? this.ocrText,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (transcription.present) {
      map['transcription'] = Variable<String>(transcription.value);
    }
    if (ocrText.present) {
      map['ocr_text'] = Variable<String>(ocrText.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('filePath: $filePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('size: $size, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationMs: $durationMs, ')
          ..write('transcription: $transcription, ')
          ..write('ocrText: $ocrText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $EntryTagsTable entryTags = $EntryTagsTable(this);
  late final $ContainersTable containers = $ContainersTable(this);
  late final $EntryContainersTable entryContainers = $EntryContainersTable(
    this,
  );
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final EntryDao entryDao = EntryDao(this as AppDatabase);
  late final TagDao tagDao = TagDao(this as AppDatabase);
  late final ContainerDao containerDao = ContainerDao(this as AppDatabase);
  late final AttachmentDao attachmentDao = AttachmentDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    entries,
    tags,
    entryTags,
    containers,
    entryContainers,
    attachments,
  ];
}

typedef $$EntriesTableCreateCompanionBuilder =
    EntriesCompanion Function({
      required String id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> type,
      Value<String?> title,
      Value<String> body,
      Value<String> status,
      Value<bool> pinned,
      Value<double?> geoLat,
      Value<double?> geoLng,
      Value<DateTime?> reminderAt,
      Value<String?> sourceUrl,
      Value<String?> sourceApp,
      Value<Uint8List?> embedding,
      Value<DateTime?> aiEnrichedAt,
      Value<String?> lang,
      Value<int> rowid,
    });
typedef $$EntriesTableUpdateCompanionBuilder =
    EntriesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> type,
      Value<String?> title,
      Value<String> body,
      Value<String> status,
      Value<bool> pinned,
      Value<double?> geoLat,
      Value<double?> geoLng,
      Value<DateTime?> reminderAt,
      Value<String?> sourceUrl,
      Value<String?> sourceApp,
      Value<Uint8List?> embedding,
      Value<DateTime?> aiEnrichedAt,
      Value<String?> lang,
      Value<int> rowid,
    });

class $$EntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get geoLat => $composableBuilder(
    column: $table.geoLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get geoLng => $composableBuilder(
    column: $table.geoLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceApp => $composableBuilder(
    column: $table.sourceApp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get aiEnrichedAt => $composableBuilder(
    column: $table.aiEnrichedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get geoLat => $composableBuilder(
    column: $table.geoLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get geoLng => $composableBuilder(
    column: $table.geoLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceApp => $composableBuilder(
    column: $table.sourceApp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get aiEnrichedAt => $composableBuilder(
    column: $table.aiEnrichedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<double> get geoLat =>
      $composableBuilder(column: $table.geoLat, builder: (column) => column);

  GeneratedColumn<double> get geoLng =>
      $composableBuilder(column: $table.geoLng, builder: (column) => column);

  GeneratedColumn<DateTime> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get sourceApp =>
      $composableBuilder(column: $table.sourceApp, builder: (column) => column);

  GeneratedColumn<Uint8List> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  GeneratedColumn<DateTime> get aiEnrichedAt => $composableBuilder(
    column: $table.aiEnrichedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntriesTable,
          Entry,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (Entry, BaseReferences<_$AppDatabase, $EntriesTable, Entry>),
          Entry,
          PrefetchHooks Function()
        > {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<double?> geoLat = const Value.absent(),
                Value<double?> geoLng = const Value.absent(),
                Value<DateTime?> reminderAt = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> sourceApp = const Value.absent(),
                Value<Uint8List?> embedding = const Value.absent(),
                Value<DateTime?> aiEnrichedAt = const Value.absent(),
                Value<String?> lang = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                type: type,
                title: title,
                body: body,
                status: status,
                pinned: pinned,
                geoLat: geoLat,
                geoLng: geoLng,
                reminderAt: reminderAt,
                sourceUrl: sourceUrl,
                sourceApp: sourceApp,
                embedding: embedding,
                aiEnrichedAt: aiEnrichedAt,
                lang: lang,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<double?> geoLat = const Value.absent(),
                Value<double?> geoLng = const Value.absent(),
                Value<DateTime?> reminderAt = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> sourceApp = const Value.absent(),
                Value<Uint8List?> embedding = const Value.absent(),
                Value<DateTime?> aiEnrichedAt = const Value.absent(),
                Value<String?> lang = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                type: type,
                title: title,
                body: body,
                status: status,
                pinned: pinned,
                geoLat: geoLat,
                geoLng: geoLng,
                reminderAt: reminderAt,
                sourceUrl: sourceUrl,
                sourceApp: sourceApp,
                embedding: embedding,
                aiEnrichedAt: aiEnrichedAt,
                lang: lang,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntriesTable,
      Entry,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (Entry, BaseReferences<_$AppDatabase, $EntriesTable, Entry>),
      Entry,
      PrefetchHooks Function()
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String name,
      Value<String?> parentId,
      Value<String?> color,
      Value<String?> icon,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> parentId,
      Value<String?> color,
      Value<String?> icon,
      Value<int> rowid,
    });

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
          Tag,
          PrefetchHooks Function()
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                parentId: parentId,
                color: color,
                icon: icon,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> parentId = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                parentId: parentId,
                color: color,
                icon: icon,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
      Tag,
      PrefetchHooks Function()
    >;
typedef $$EntryTagsTableCreateCompanionBuilder =
    EntryTagsCompanion Function({
      required String entryId,
      required String tagId,
      Value<int> rowid,
    });
typedef $$EntryTagsTableUpdateCompanionBuilder =
    EntryTagsCompanion Function({
      Value<String> entryId,
      Value<String> tagId,
      Value<int> rowid,
    });

class $$EntryTagsTableFilterComposer
    extends Composer<_$AppDatabase, $EntryTagsTable> {
  $$EntryTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntryTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $EntryTagsTable> {
  $$EntryTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntryTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntryTagsTable> {
  $$EntryTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);
}

class $$EntryTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntryTagsTable,
          EntryTag,
          $$EntryTagsTableFilterComposer,
          $$EntryTagsTableOrderingComposer,
          $$EntryTagsTableAnnotationComposer,
          $$EntryTagsTableCreateCompanionBuilder,
          $$EntryTagsTableUpdateCompanionBuilder,
          (EntryTag, BaseReferences<_$AppDatabase, $EntryTagsTable, EntryTag>),
          EntryTag,
          PrefetchHooks Function()
        > {
  $$EntryTagsTableTableManager(_$AppDatabase db, $EntryTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryTagsCompanion(
                entryId: entryId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => EntryTagsCompanion.insert(
                entryId: entryId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntryTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntryTagsTable,
      EntryTag,
      $$EntryTagsTableFilterComposer,
      $$EntryTagsTableOrderingComposer,
      $$EntryTagsTableAnnotationComposer,
      $$EntryTagsTableCreateCompanionBuilder,
      $$EntryTagsTableUpdateCompanionBuilder,
      (EntryTag, BaseReferences<_$AppDatabase, $EntryTagsTable, EntryTag>),
      EntryTag,
      PrefetchHooks Function()
    >;
typedef $$ContainersTableCreateCompanionBuilder =
    ContainersCompanion Function({
      required String id,
      required String kind,
      required String name,
      Value<String?> description,
      Value<String> icon,
      Value<String> color,
      Value<DateTime> createdAt,
      Value<bool> archived,
      Value<String?> filterJson,
      Value<int> rowid,
    });
typedef $$ContainersTableUpdateCompanionBuilder =
    ContainersCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> name,
      Value<String?> description,
      Value<String> icon,
      Value<String> color,
      Value<DateTime> createdAt,
      Value<bool> archived,
      Value<String?> filterJson,
      Value<int> rowid,
    });

class $$ContainersTableFilterComposer
    extends Composer<_$AppDatabase, $ContainersTable> {
  $$ContainersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterJson => $composableBuilder(
    column: $table.filterJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContainersTableOrderingComposer
    extends Composer<_$AppDatabase, $ContainersTable> {
  $$ContainersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterJson => $composableBuilder(
    column: $table.filterJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContainersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContainersTable> {
  $$ContainersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get filterJson => $composableBuilder(
    column: $table.filterJson,
    builder: (column) => column,
  );
}

class $$ContainersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContainersTable,
          Container,
          $$ContainersTableFilterComposer,
          $$ContainersTableOrderingComposer,
          $$ContainersTableAnnotationComposer,
          $$ContainersTableCreateCompanionBuilder,
          $$ContainersTableUpdateCompanionBuilder,
          (
            Container,
            BaseReferences<_$AppDatabase, $ContainersTable, Container>,
          ),
          Container,
          PrefetchHooks Function()
        > {
  $$ContainersTableTableManager(_$AppDatabase db, $ContainersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContainersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContainersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContainersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> filterJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContainersCompanion(
                id: id,
                kind: kind,
                name: name,
                description: description,
                icon: icon,
                color: color,
                createdAt: createdAt,
                archived: archived,
                filterJson: filterJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> filterJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContainersCompanion.insert(
                id: id,
                kind: kind,
                name: name,
                description: description,
                icon: icon,
                color: color,
                createdAt: createdAt,
                archived: archived,
                filterJson: filterJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContainersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContainersTable,
      Container,
      $$ContainersTableFilterComposer,
      $$ContainersTableOrderingComposer,
      $$ContainersTableAnnotationComposer,
      $$ContainersTableCreateCompanionBuilder,
      $$ContainersTableUpdateCompanionBuilder,
      (Container, BaseReferences<_$AppDatabase, $ContainersTable, Container>),
      Container,
      PrefetchHooks Function()
    >;
typedef $$EntryContainersTableCreateCompanionBuilder =
    EntryContainersCompanion Function({
      required String entryId,
      required String containerId,
      Value<int> rowid,
    });
typedef $$EntryContainersTableUpdateCompanionBuilder =
    EntryContainersCompanion Function({
      Value<String> entryId,
      Value<String> containerId,
      Value<int> rowid,
    });

class $$EntryContainersTableFilterComposer
    extends Composer<_$AppDatabase, $EntryContainersTable> {
  $$EntryContainersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerId => $composableBuilder(
    column: $table.containerId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntryContainersTableOrderingComposer
    extends Composer<_$AppDatabase, $EntryContainersTable> {
  $$EntryContainersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerId => $composableBuilder(
    column: $table.containerId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntryContainersTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntryContainersTable> {
  $$EntryContainersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get containerId => $composableBuilder(
    column: $table.containerId,
    builder: (column) => column,
  );
}

class $$EntryContainersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntryContainersTable,
          EntryContainer,
          $$EntryContainersTableFilterComposer,
          $$EntryContainersTableOrderingComposer,
          $$EntryContainersTableAnnotationComposer,
          $$EntryContainersTableCreateCompanionBuilder,
          $$EntryContainersTableUpdateCompanionBuilder,
          (
            EntryContainer,
            BaseReferences<
              _$AppDatabase,
              $EntryContainersTable,
              EntryContainer
            >,
          ),
          EntryContainer,
          PrefetchHooks Function()
        > {
  $$EntryContainersTableTableManager(
    _$AppDatabase db,
    $EntryContainersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryContainersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryContainersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryContainersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String> containerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryContainersCompanion(
                entryId: entryId,
                containerId: containerId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required String containerId,
                Value<int> rowid = const Value.absent(),
              }) => EntryContainersCompanion.insert(
                entryId: entryId,
                containerId: containerId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntryContainersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntryContainersTable,
      EntryContainer,
      $$EntryContainersTableFilterComposer,
      $$EntryContainersTableOrderingComposer,
      $$EntryContainersTableAnnotationComposer,
      $$EntryContainersTableCreateCompanionBuilder,
      $$EntryContainersTableUpdateCompanionBuilder,
      (
        EntryContainer,
        BaseReferences<_$AppDatabase, $EntryContainersTable, EntryContainer>,
      ),
      EntryContainer,
      PrefetchHooks Function()
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String id,
      required String entryId,
      required String filePath,
      required String mimeType,
      required int size,
      Value<int?> width,
      Value<int?> height,
      Value<int?> durationMs,
      Value<String?> transcription,
      Value<String?> ocrText,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> id,
      Value<String> entryId,
      Value<String> filePath,
      Value<String> mimeType,
      Value<int> size,
      Value<int?> width,
      Value<int?> height,
      Value<int?> durationMs,
      Value<String?> transcription,
      Value<String?> ocrText,
      Value<int> rowid,
    });

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transcription => $composableBuilder(
    column: $table.transcription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcription => $composableBuilder(
    column: $table.transcription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transcription => $composableBuilder(
    column: $table.transcription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ocrText =>
      $composableBuilder(column: $table.ocrText, builder: (column) => column);
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          Attachment,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (
            Attachment,
            BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment>,
          ),
          Attachment,
          PrefetchHooks Function()
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String?> transcription = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                entryId: entryId,
                filePath: filePath,
                mimeType: mimeType,
                size: size,
                width: width,
                height: height,
                durationMs: durationMs,
                transcription: transcription,
                ocrText: ocrText,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entryId,
                required String filePath,
                required String mimeType,
                required int size,
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String?> transcription = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                entryId: entryId,
                filePath: filePath,
                mimeType: mimeType,
                size: size,
                width: width,
                height: height,
                durationMs: durationMs,
                transcription: transcription,
                ocrText: ocrText,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      Attachment,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (
        Attachment,
        BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment>,
      ),
      Attachment,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$EntryTagsTableTableManager get entryTags =>
      $$EntryTagsTableTableManager(_db, _db.entryTags);
  $$ContainersTableTableManager get containers =>
      $$ContainersTableTableManager(_db, _db.containers);
  $$EntryContainersTableTableManager get entryContainers =>
      $$EntryContainersTableTableManager(_db, _db.entryContainers);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
}
