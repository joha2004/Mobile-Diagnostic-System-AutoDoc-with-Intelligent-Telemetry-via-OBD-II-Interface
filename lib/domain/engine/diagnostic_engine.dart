import '../../data/models/dtc_code.dart';
import '../../data/models/live_data.dart';
import '../../data/models/diagnostic_result.dart';
import 'rules/base_rule.dart';
import 'rules/fuel_system_rules.dart';
import 'rules/misfire_rules.dart';
import 'rules/oxygen_sensor_rules.dart';
import 'rules/coolant_rules.dart';
import 'rules/catalyst_rules.dart';

/// Core diagnostic engine that analyzes DTCs against live sensor data
/// to produce probability-ranked causes. AI does NOT diagnose — this engine does.
class DiagnosticEngine {
  /// Run full analysis on a DTC code using live data context
  DiagnosticResult analyze({
    required DtcCode dtc,
    required LiveData liveData,
    FreezeFrame? freezeFrame,
  }) {
    // Select rule set based on DTC code range
    final ruleResult = _applyRules(dtc.code, liveData, freezeFrame);

    // Calculate overall confidence based on available data
    final confidence = _calculateConfidence(liveData, freezeFrame);

    // Determine severity considering live data
    final severity = _assessSeverity(dtc, liveData);

    // Determine if safe to drive
    final driveAssessment = _canDrive(dtc, liveData, severity);

    // Generate diagnostic steps
    final steps = _generateSteps(dtc.code, ruleResult.causes);

    return DiagnosticResult(
      dtcCode: dtc.code,
      causes: ruleResult.causes,
      confidencePercent: confidence,
      overallSeverity: severity,
      canDrive: driveAssessment.canDrive,
      canDriveNote: driveAssessment.note,
      liveDataSnapshot: liveData,
      freezeFrame: freezeFrame,
      suggestedSteps: steps,
      timestamp: DateTime.now(),
    );
  }

  RuleResult _applyRules(String dtcCode, LiveData liveData, FreezeFrame? ff) {
    final code = dtcCode.toUpperCase();

    // P0170-P0179: Fuel system
    if (code.startsWith('P017')) {
      return FuelSystemRules.analyze(code, liveData, ff);
    }
    // P0300-P0312: Misfire
    if (code.startsWith('P030')) {
      return MisfireRules.analyze(code, liveData, ff);
    }
    // P0130-P0167: O2 sensors
    if (code.startsWith('P013') || code.startsWith('P014')) {
      return OxygenSensorRules.analyze(code, liveData, ff);
    }
    // P0115-P0119: Coolant
    if (code.startsWith('P011')) {
      return CoolantRules.analyze(code, liveData, ff);
    }
    // P0420-P0430: Catalyst
    if (code.startsWith('P042') || code.startsWith('P043')) {
      return CatalystRules.analyze(code, liveData, ff);
    }

    // Generic fallback
    return RuleResult(causes: [
      const PossibleCause(
        description: 'Sensor or circuit malfunction',
        descriptionRu: 'Неисправность датчика или цепи',
        probability: 60,
        repairCategory: 'diagnostics',
      ),
      const PossibleCause(
        description: 'Wiring issue',
        descriptionRu: 'Проблема с проводкой',
        probability: 30,
        repairCategory: 'electrician',
      ),
    ]);
  }

  double _calculateConfidence(LiveData liveData, FreezeFrame? ff) {
    double confidence = 40; // Base without any live data

    // More data = higher confidence
    if (liveData.isEngineRunning) {
      confidence += 15;
    }
    if (liveData.coolantTemp > 0) {
      confidence += 5;
    }
    if (liveData.mafAirFlow > 0) {
      confidence += 5;
    }
    if (liveData.shortTermFuelTrim != 0) {
      confidence += 10;
    }
    if (liveData.longTermFuelTrim != 0) {
      confidence += 10;
    }
    if (liveData.o2Voltage > 0) {
      confidence += 5;
    }
    if (ff != null) {
      confidence += 10;
    }

    return confidence.clamp(0, 95);
  }

  String _assessSeverity(DtcCode dtc, LiveData liveData) {
    // Start with DTC severity
    String severity = dtc.severity.name;

    // Upgrade if live data shows danger
    if (liveData.isOverheating) {
      severity = 'critical';
    }
    if (liveData.hasFuelTrimIssue && dtc.code.startsWith('P017')) {
      severity = 'high';
    }

    return severity;
  }

  _DriveAssessment _canDrive(DtcCode dtc, LiveData liveData, String severity) {
    if (severity == 'critical' || liveData.isOverheating) {
      return const _DriveAssessment(false, 'Движение опасно. Остановитесь и вызовите эвакуатор.');
    }
    if (severity == 'high') {
      return const _DriveAssessment(false, 'Рекомендуем не ехать. Обратитесь в сервис.');
    }
    if (severity == 'medium') {
      return const _DriveAssessment(true, 'Можно ехать аккуратно до ближайшего сервиса.');
    }
    return const _DriveAssessment(true, 'Можно ехать. Запланируйте визит на СТО.');
  }

  List<DiagnosticStep> _generateSteps(String code, List<PossibleCause> causes) {
    final steps = <DiagnosticStep>[];
    int order = 1;

    // Generic first steps
    steps.add(DiagnosticStep(
      order: order++,
      title: 'Visual Inspection',
      titleRu: 'Визуальный осмотр',
      description: 'Check for visible damage, loose connectors, or broken wires',
      descriptionRu: 'Проверьте видимые повреждения, ослабленные разъёмы и повреждённые провода',
      checkType: 'visual',
    ));

    // Add cause-specific steps
    for (final cause in causes.take(3)) {
      steps.add(DiagnosticStep(
        order: order++,
        title: 'Check: ${cause.description}',
        titleRu: 'Проверить: ${cause.descriptionRu}',
        description: 'Verify this component based on sensor data',
        descriptionRu: 'Проверьте этот компонент на основе данных датчиков',
        checkType: 'sensor',
      ));
    }

    steps.add(DiagnosticStep(
      order: order++,
      title: 'Clear codes and test drive',
      titleRu: 'Сбросить ошибки и провести тест-драйв',
      description: 'After repairs, clear codes and drive to verify fix',
      descriptionRu: 'После ремонта сбросьте ошибки и проведите тест-драйв для проверки',
      checkType: 'tool',
    ));

    return steps;
  }
}

class _DriveAssessment {
  final bool canDrive;
  final String note;
  const _DriveAssessment(this.canDrive, this.note);
}
