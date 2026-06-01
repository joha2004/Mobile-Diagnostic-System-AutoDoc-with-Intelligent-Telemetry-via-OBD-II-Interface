import '../../../data/models/dtc_code.dart';
import '../../../data/models/live_data.dart';
import '../../../data/models/diagnostic_result.dart';
import 'base_rule.dart';

/// Rule set for P0115-P0119: Coolant Temperature issues
class CoolantRules {
  static RuleResult analyze(String code, LiveData live, FreezeFrame? ff) {
    final causes = <PossibleCause>[];
    final temp = ff?.coolantTemp ?? live.coolantTemp;

    if (code == 'P0115') {
      causes.add(const PossibleCause(
        description: 'Faulty coolant temperature sensor (ECT)',
        descriptionRu: 'Неисправный датчик температуры охлаждающей жидкости',
        probability: 70,
        repairCategory: 'mechanic',
      ));
      causes.add(const PossibleCause(
        description: 'Open or short circuit in ECT wiring',
        descriptionRu: 'Обрыв или замыкание проводки датчика температуры',
        probability: 55,
        repairCategory: 'electrician',
      ));
    }

    if (code == 'P0116') {
      if (temp < 50 && live.runtimeSeconds > 600) {
        causes.add(const PossibleCause(
          description: 'Thermostat stuck open — engine not warming up',
          descriptionRu: 'Термостат заклинил в открытом положении — двигатель не прогревается',
          probability: 80,
          confirmedBySensors: ['Coolant temp < 50°C after 10 min'],
          repairCategory: 'mechanic',
        ));
      }
      causes.add(const PossibleCause(
        description: 'ECT sensor reading outside expected range',
        descriptionRu: 'Датчик температуры ОЖ даёт показания вне допустимых пределов',
        probability: 60,
        repairCategory: 'diagnostics',
      ));
    }

    if (code == 'P0117') {
      causes.add(const PossibleCause(
        description: 'ECT sensor short to ground (reads too cold)',
        descriptionRu: 'Датчик температуры ОЖ замкнут на массу (показывает слишком холодно)',
        probability: 70,
        repairCategory: 'electrician',
      ));
    }

    if (code == 'P0118') {
      if (temp > 120) {
        causes.add(const PossibleCause(
          description: 'Engine overheating — STOP immediately!',
          descriptionRu: 'Двигатель перегревается — НЕМЕДЛЕННО остановитесь!',
          probability: 90,
          confirmedBySensors: ['Coolant temp > 120°C'],
          repairCategory: 'mechanic',
        ));
      }
      causes.add(const PossibleCause(
        description: 'ECT sensor open circuit (reads too hot)',
        descriptionRu: 'Обрыв цепи датчика температуры ОЖ (показывает слишком горячо)',
        probability: 65,
        repairCategory: 'electrician',
      ));
    }

    if (causes.isEmpty) {
      causes.add(const PossibleCause(
        description: 'Coolant temperature sensor malfunction',
        descriptionRu: 'Неисправность датчика температуры охлаждающей жидкости',
        probability: 60,
        repairCategory: 'diagnostics',
      ));
    }

    causes.sort((a, b) => b.probability.compareTo(a.probability));
    return RuleResult(causes: causes);
  }
}
