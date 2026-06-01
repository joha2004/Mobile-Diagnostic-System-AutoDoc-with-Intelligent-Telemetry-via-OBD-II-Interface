import '../../data/models/dtc_code.dart';
import '../../data/models/live_data.dart';

/// Calculates overall vehicle health score (0-100)
class HealthScoreCalculator {
  /// Calculate health score based on DTCs, live data stability, and history
  static int calculate({
    required List<DtcCode> activeDtcs,
    required LiveData liveData,
    int recurringErrorCount = 0,
  }) {
    double score = 100;

    // === Deductions for DTC codes ===
    for (final dtc in activeDtcs) {
      switch (dtc.severity) {
        case DtcSeverity.critical:
          score -= 25;
          break;
        case DtcSeverity.high:
          score -= 15;
          break;
        case DtcSeverity.medium:
          score -= 8;
          break;
        case DtcSeverity.low:
          score -= 3;
          break;
      }
    }

    // === Deductions for live data anomalies ===
    // Overheating
    if (liveData.coolantTemp > 105) {
      score -= 20;
    } else if (liveData.coolantTemp > 95) {
      score -= 5;
    }

    // Fuel trims way off
    if (liveData.shortTermFuelTrim.abs() > 25) {
      score -= 10;
    } else if (liveData.shortTermFuelTrim.abs() > 15) {
      score -= 5;
    }

    if (liveData.longTermFuelTrim.abs() > 20) {
      score -= 10;
    } else if (liveData.longTermFuelTrim.abs() > 12) {
      score -= 5;
    }

    // Low battery voltage
    if (liveData.batteryVoltage > 0 && liveData.batteryVoltage < 12.0) {
      score -= 10;
    } else if (liveData.batteryVoltage > 0 && liveData.batteryVoltage < 13.0) {
      score -= 3;
    }

    // Unstable RPM at idle (too high or too low)
    if (liveData.speed < 5 && liveData.rpm > 0) {
      if (liveData.rpm < 500 || liveData.rpm > 1200) {
        score -= 5;
      }
    }

    // === Deductions for recurring errors ===
    score -= recurringErrorCount * 3;

    return score.round().clamp(0, 100);
  }

  /// Get health category label
  static String getLabel(int score, {bool russian = true}) {
    if (score >= 90) return russian ? 'Отличное' : 'Excellent';
    if (score >= 75) return russian ? 'Хорошее' : 'Good';
    if (score >= 50) return russian ? 'Требует внимания' : 'Needs Attention';
    if (score >= 25) return russian ? 'Проблемы' : 'Issues Found';
    return russian ? 'Критическое' : 'Critical';
  }

  /// Get health emoji
  static String getEmoji(int score) {
    if (score >= 90) return '💚';
    if (score >= 75) return '💛';
    if (score >= 50) return '🟠';
    if (score >= 25) return '🔴';
    return '🚨';
  }
}
