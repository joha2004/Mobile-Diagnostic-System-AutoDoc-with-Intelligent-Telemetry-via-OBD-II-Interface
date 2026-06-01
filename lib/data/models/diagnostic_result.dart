import 'package:equatable/equatable.dart';
import 'dtc_code.dart';
import 'live_data.dart';

/// Result of rule-based diagnostic engine analysis
class DiagnosticResult extends Equatable {
  final String dtcCode;
  final List<PossibleCause> causes;
  final double confidencePercent;
  final String overallSeverity; // low, medium, high, critical
  final bool canDrive;
  final String canDriveNote;
  final LiveData? liveDataSnapshot;
  final FreezeFrame? freezeFrame;
  final List<DiagnosticStep> suggestedSteps;
  final DateTime timestamp;

  const DiagnosticResult({
    required this.dtcCode,
    required this.causes,
    required this.confidencePercent,
    required this.overallSeverity,
    this.canDrive = true,
    this.canDriveNote = '',
    this.liveDataSnapshot,
    this.freezeFrame,
    this.suggestedSteps = const [],
    required this.timestamp,
  });

  /// Top probable cause
  PossibleCause? get topCause =>
      causes.isNotEmpty ? causes.first : null;

  /// Data summary for AI prompt
  Map<String, dynamic> toAiContext() => {
    'dtc_code': dtcCode,
    'causes': causes.map((c) => {
      'cause': c.description,
      'probability': c.probability,
      'confirmed_by_sensors': c.confirmedBySensors,
    }).toList(),
    'confidence': confidencePercent,
    'severity': overallSeverity,
    'can_drive': canDrive,
    'live_data': liveDataSnapshot?.toJson(),
    'freeze_frame': freezeFrame?.toMap(),
  };

  @override
  List<Object?> get props => [dtcCode, causes, confidencePercent, timestamp];
}

/// A possible cause identified by the rule engine
class PossibleCause extends Equatable {
  final String description;
  final String descriptionRu;
  final double probability; // 0-100
  final List<String> confirmedBySensors;
  final String repairCategory; // electrician, mechanic, diagnostics

  const PossibleCause({
    required this.description,
    this.descriptionRu = '',
    required this.probability,
    this.confirmedBySensors = const [],
    this.repairCategory = 'diagnostics',
  });

  @override
  List<Object?> get props => [description, probability];
}

/// A step in the guided diagnostic process
class DiagnosticStep extends Equatable {
  final int order;
  final String title;
  final String titleRu;
  final String description;
  final String descriptionRu;
  final String? checkType; // visual, sensor, tool

  const DiagnosticStep({
    required this.order,
    required this.title,
    this.titleRu = '',
    required this.description,
    this.descriptionRu = '',
    this.checkType,
  });

  @override
  List<Object?> get props => [order, title];
}
