import '../../../data/models/dtc_code.dart';
import '../../../data/models/live_data.dart';
import '../../../data/models/diagnostic_result.dart';
import 'base_rule.dart';

/// Rule set for P0130-P0167: Oxygen Sensor issues
class OxygenSensorRules {
  static RuleResult analyze(String code, LiveData live, FreezeFrame? ff) {
    final causes = <PossibleCause>[];
    final o2v = ff?.o2Voltage ?? live.o2Voltage;

    if (code == 'P0130' || code == 'P0131' || code == 'P0132') {
      causes.add(const PossibleCause(
        description: 'Faulty O2 sensor (Bank 1, Sensor 1)',
        descriptionRu: 'Неисправный кислородный датчик (Банк 1, Датчик 1)',
        probability: 70,
        repairCategory: 'diagnostics',
      ));
      causes.add(const PossibleCause(
        description: 'Wiring damage to O2 sensor',
        descriptionRu: 'Повреждение проводки кислородного датчика',
        probability: 50,
        confirmedBySensors: ['O2 circuit'],
        repairCategory: 'electrician',
      ));
    }

    if (code == 'P0133') {
      causes.add(const PossibleCause(
        description: 'Slow responding O2 sensor — aging sensor',
        descriptionRu: 'Медленный отклик кислородного датчика — старение',
        probability: 75,
        repairCategory: 'diagnostics',
      ));
    }

    if (code == 'P0134') {
      if (o2v < 0.1) {
        causes.add(const PossibleCause(
          description: 'O2 sensor not generating signal — likely dead',
          descriptionRu: 'Кислородный датчик не даёт сигнал — вероятно вышел из строя',
          probability: 85,
          confirmedBySensors: ['O2 voltage ≈ 0V'],
          repairCategory: 'diagnostics',
        ));
      }
      causes.add(const PossibleCause(
        description: 'Open circuit in O2 sensor heater',
        descriptionRu: 'Обрыв цепи подогрева кислородного датчика',
        probability: 60,
        repairCategory: 'electrician',
      ));
    }

    if (code == 'P0135' || code == 'P0141') {
      causes.add(const PossibleCause(
        description: 'O2 sensor heater element burned out',
        descriptionRu: 'Нагревательный элемент кислородного датчика перегорел',
        probability: 80,
        repairCategory: 'diagnostics',
      ));
      causes.add(const PossibleCause(
        description: 'Blown fuse for O2 heater circuit',
        descriptionRu: 'Перегоревший предохранитель цепи подогрева',
        probability: 40,
        repairCategory: 'electrician',
      ));
    }

    if (causes.isEmpty) {
      causes.add(const PossibleCause(
        description: 'O2 sensor fault — replacement recommended',
        descriptionRu: 'Неисправность кислородного датчика — рекомендуется замена',
        probability: 65,
        repairCategory: 'diagnostics',
      ));
    }

    causes.sort((a, b) => b.probability.compareTo(a.probability));
    return RuleResult(causes: causes);
  }
}
