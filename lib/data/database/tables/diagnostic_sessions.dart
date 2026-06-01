import 'package:drift/drift.dart';

@DataClassName('DiagnosticSession')
class DiagnosticSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get healthScore => integer()();
  TextColumn get dtcCodesJson => text()(); // JSON string of DTC codes
  TextColumn get severity => text().nullable()(); 
  TextColumn get aiSummary => text().nullable()(); 
}
