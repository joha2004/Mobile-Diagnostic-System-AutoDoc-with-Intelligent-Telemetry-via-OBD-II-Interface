// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DiagnosticSessionsTable extends DiagnosticSessions
    with TableInfo<$DiagnosticSessionsTable, DiagnosticSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiagnosticSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _healthScoreMeta = const VerificationMeta(
    'healthScore',
  );
  @override
  late final GeneratedColumn<int> healthScore = GeneratedColumn<int>(
    'health_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dtcCodesJsonMeta = const VerificationMeta(
    'dtcCodesJson',
  );
  @override
  late final GeneratedColumn<String> dtcCodesJson = GeneratedColumn<String>(
    'dtc_codes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiSummaryMeta = const VerificationMeta(
    'aiSummary',
  );
  @override
  late final GeneratedColumn<String> aiSummary = GeneratedColumn<String>(
    'ai_summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    healthScore,
    dtcCodesJson,
    severity,
    aiSummary,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diagnostic_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiagnosticSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('health_score')) {
      context.handle(
        _healthScoreMeta,
        healthScore.isAcceptableOrUnknown(
          data['health_score']!,
          _healthScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_healthScoreMeta);
    }
    if (data.containsKey('dtc_codes_json')) {
      context.handle(
        _dtcCodesJsonMeta,
        dtcCodesJson.isAcceptableOrUnknown(
          data['dtc_codes_json']!,
          _dtcCodesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dtcCodesJsonMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    }
    if (data.containsKey('ai_summary')) {
      context.handle(
        _aiSummaryMeta,
        aiSummary.isAcceptableOrUnknown(data['ai_summary']!, _aiSummaryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiagnosticSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiagnosticSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      healthScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}health_score'],
      )!,
      dtcCodesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dtc_codes_json'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      ),
      aiSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_summary'],
      ),
    );
  }

  @override
  $DiagnosticSessionsTable createAlias(String alias) {
    return $DiagnosticSessionsTable(attachedDatabase, alias);
  }
}

class DiagnosticSession extends DataClass
    implements Insertable<DiagnosticSession> {
  final int id;
  final DateTime timestamp;
  final int healthScore;
  final String dtcCodesJson;
  final String? severity;
  final String? aiSummary;
  const DiagnosticSession({
    required this.id,
    required this.timestamp,
    required this.healthScore,
    required this.dtcCodesJson,
    this.severity,
    this.aiSummary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['health_score'] = Variable<int>(healthScore);
    map['dtc_codes_json'] = Variable<String>(dtcCodesJson);
    if (!nullToAbsent || severity != null) {
      map['severity'] = Variable<String>(severity);
    }
    if (!nullToAbsent || aiSummary != null) {
      map['ai_summary'] = Variable<String>(aiSummary);
    }
    return map;
  }

  DiagnosticSessionsCompanion toCompanion(bool nullToAbsent) {
    return DiagnosticSessionsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      healthScore: Value(healthScore),
      dtcCodesJson: Value(dtcCodesJson),
      severity: severity == null && nullToAbsent
          ? const Value.absent()
          : Value(severity),
      aiSummary: aiSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(aiSummary),
    );
  }

  factory DiagnosticSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiagnosticSession(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      healthScore: serializer.fromJson<int>(json['healthScore']),
      dtcCodesJson: serializer.fromJson<String>(json['dtcCodesJson']),
      severity: serializer.fromJson<String?>(json['severity']),
      aiSummary: serializer.fromJson<String?>(json['aiSummary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'healthScore': serializer.toJson<int>(healthScore),
      'dtcCodesJson': serializer.toJson<String>(dtcCodesJson),
      'severity': serializer.toJson<String?>(severity),
      'aiSummary': serializer.toJson<String?>(aiSummary),
    };
  }

  DiagnosticSession copyWith({
    int? id,
    DateTime? timestamp,
    int? healthScore,
    String? dtcCodesJson,
    Value<String?> severity = const Value.absent(),
    Value<String?> aiSummary = const Value.absent(),
  }) => DiagnosticSession(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    healthScore: healthScore ?? this.healthScore,
    dtcCodesJson: dtcCodesJson ?? this.dtcCodesJson,
    severity: severity.present ? severity.value : this.severity,
    aiSummary: aiSummary.present ? aiSummary.value : this.aiSummary,
  );
  DiagnosticSession copyWithCompanion(DiagnosticSessionsCompanion data) {
    return DiagnosticSession(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      healthScore: data.healthScore.present
          ? data.healthScore.value
          : this.healthScore,
      dtcCodesJson: data.dtcCodesJson.present
          ? data.dtcCodesJson.value
          : this.dtcCodesJson,
      severity: data.severity.present ? data.severity.value : this.severity,
      aiSummary: data.aiSummary.present ? data.aiSummary.value : this.aiSummary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiagnosticSession(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('healthScore: $healthScore, ')
          ..write('dtcCodesJson: $dtcCodesJson, ')
          ..write('severity: $severity, ')
          ..write('aiSummary: $aiSummary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    healthScore,
    dtcCodesJson,
    severity,
    aiSummary,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiagnosticSession &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.healthScore == this.healthScore &&
          other.dtcCodesJson == this.dtcCodesJson &&
          other.severity == this.severity &&
          other.aiSummary == this.aiSummary);
}

class DiagnosticSessionsCompanion extends UpdateCompanion<DiagnosticSession> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<int> healthScore;
  final Value<String> dtcCodesJson;
  final Value<String?> severity;
  final Value<String?> aiSummary;
  const DiagnosticSessionsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.healthScore = const Value.absent(),
    this.dtcCodesJson = const Value.absent(),
    this.severity = const Value.absent(),
    this.aiSummary = const Value.absent(),
  });
  DiagnosticSessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    required int healthScore,
    required String dtcCodesJson,
    this.severity = const Value.absent(),
    this.aiSummary = const Value.absent(),
  }) : timestamp = Value(timestamp),
       healthScore = Value(healthScore),
       dtcCodesJson = Value(dtcCodesJson);
  static Insertable<DiagnosticSession> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<int>? healthScore,
    Expression<String>? dtcCodesJson,
    Expression<String>? severity,
    Expression<String>? aiSummary,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (healthScore != null) 'health_score': healthScore,
      if (dtcCodesJson != null) 'dtc_codes_json': dtcCodesJson,
      if (severity != null) 'severity': severity,
      if (aiSummary != null) 'ai_summary': aiSummary,
    });
  }

  DiagnosticSessionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<int>? healthScore,
    Value<String>? dtcCodesJson,
    Value<String?>? severity,
    Value<String?>? aiSummary,
  }) {
    return DiagnosticSessionsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      healthScore: healthScore ?? this.healthScore,
      dtcCodesJson: dtcCodesJson ?? this.dtcCodesJson,
      severity: severity ?? this.severity,
      aiSummary: aiSummary ?? this.aiSummary,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (healthScore.present) {
      map['health_score'] = Variable<int>(healthScore.value);
    }
    if (dtcCodesJson.present) {
      map['dtc_codes_json'] = Variable<String>(dtcCodesJson.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (aiSummary.present) {
      map['ai_summary'] = Variable<String>(aiSummary.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiagnosticSessionsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('healthScore: $healthScore, ')
          ..write('dtcCodesJson: $dtcCodesJson, ')
          ..write('severity: $severity, ')
          ..write('aiSummary: $aiSummary')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DiagnosticSessionsTable diagnosticSessions =
      $DiagnosticSessionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [diagnosticSessions];
}

typedef $$DiagnosticSessionsTableCreateCompanionBuilder =
    DiagnosticSessionsCompanion Function({
      Value<int> id,
      required DateTime timestamp,
      required int healthScore,
      required String dtcCodesJson,
      Value<String?> severity,
      Value<String?> aiSummary,
    });
typedef $$DiagnosticSessionsTableUpdateCompanionBuilder =
    DiagnosticSessionsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<int> healthScore,
      Value<String> dtcCodesJson,
      Value<String?> severity,
      Value<String?> aiSummary,
    });

class $$DiagnosticSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $DiagnosticSessionsTable> {
  $$DiagnosticSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get healthScore => $composableBuilder(
    column: $table.healthScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dtcCodesJson => $composableBuilder(
    column: $table.dtcCodesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiSummary => $composableBuilder(
    column: $table.aiSummary,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DiagnosticSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DiagnosticSessionsTable> {
  $$DiagnosticSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get healthScore => $composableBuilder(
    column: $table.healthScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dtcCodesJson => $composableBuilder(
    column: $table.dtcCodesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiSummary => $composableBuilder(
    column: $table.aiSummary,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DiagnosticSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiagnosticSessionsTable> {
  $$DiagnosticSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get healthScore => $composableBuilder(
    column: $table.healthScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dtcCodesJson => $composableBuilder(
    column: $table.dtcCodesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get aiSummary =>
      $composableBuilder(column: $table.aiSummary, builder: (column) => column);
}

class $$DiagnosticSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiagnosticSessionsTable,
          DiagnosticSession,
          $$DiagnosticSessionsTableFilterComposer,
          $$DiagnosticSessionsTableOrderingComposer,
          $$DiagnosticSessionsTableAnnotationComposer,
          $$DiagnosticSessionsTableCreateCompanionBuilder,
          $$DiagnosticSessionsTableUpdateCompanionBuilder,
          (
            DiagnosticSession,
            BaseReferences<
              _$AppDatabase,
              $DiagnosticSessionsTable,
              DiagnosticSession
            >,
          ),
          DiagnosticSession,
          PrefetchHooks Function()
        > {
  $$DiagnosticSessionsTableTableManager(
    _$AppDatabase db,
    $DiagnosticSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiagnosticSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiagnosticSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiagnosticSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> healthScore = const Value.absent(),
                Value<String> dtcCodesJson = const Value.absent(),
                Value<String?> severity = const Value.absent(),
                Value<String?> aiSummary = const Value.absent(),
              }) => DiagnosticSessionsCompanion(
                id: id,
                timestamp: timestamp,
                healthScore: healthScore,
                dtcCodesJson: dtcCodesJson,
                severity: severity,
                aiSummary: aiSummary,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                required int healthScore,
                required String dtcCodesJson,
                Value<String?> severity = const Value.absent(),
                Value<String?> aiSummary = const Value.absent(),
              }) => DiagnosticSessionsCompanion.insert(
                id: id,
                timestamp: timestamp,
                healthScore: healthScore,
                dtcCodesJson: dtcCodesJson,
                severity: severity,
                aiSummary: aiSummary,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DiagnosticSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiagnosticSessionsTable,
      DiagnosticSession,
      $$DiagnosticSessionsTableFilterComposer,
      $$DiagnosticSessionsTableOrderingComposer,
      $$DiagnosticSessionsTableAnnotationComposer,
      $$DiagnosticSessionsTableCreateCompanionBuilder,
      $$DiagnosticSessionsTableUpdateCompanionBuilder,
      (
        DiagnosticSession,
        BaseReferences<
          _$AppDatabase,
          $DiagnosticSessionsTable,
          DiagnosticSession
        >,
      ),
      DiagnosticSession,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DiagnosticSessionsTableTableManager get diagnosticSessions =>
      $$DiagnosticSessionsTableTableManager(_db, _db.diagnosticSessions);
}
