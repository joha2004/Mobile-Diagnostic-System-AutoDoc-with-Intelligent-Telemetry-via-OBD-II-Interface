import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/diagnostic_sessions.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [DiagnosticSessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // DAO functions
  Future<List<DiagnosticSession>> getAllSessions() => select(diagnosticSessions).get();
  Stream<List<DiagnosticSession>> watchAllSessions() => select(diagnosticSessions).watch();
  Future<int> insertSession(DiagnosticSessionsCompanion session) => into(diagnosticSessions).insert(session);
  Future<int> deleteSession(int id) => (delete(diagnosticSessions)..where((t) => t.id.equals(id))).go();
  Future<int> clearAllSessions() => delete(diagnosticSessions).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'autodoctor_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
