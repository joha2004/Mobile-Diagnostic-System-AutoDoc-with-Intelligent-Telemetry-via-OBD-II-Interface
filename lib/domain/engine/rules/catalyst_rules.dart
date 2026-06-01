import '../../../data/models/dtc_code.dart';
import '../../../data/models/live_data.dart';
import '../../../data/models/diagnostic_result.dart';
import 'base_rule.dart';

/// Rule set for P0420-P0430: Catalyst System issues
class CatalystRules {
  static RuleResult analyze(String code, LiveData live, FreezeFrame? ff) {
    final causes = <PossibleCause>[];

    causes.add(const PossibleCause(
      description: 'Catalytic converter degraded — may need replacement',
      descriptionRu: 'Каталитический нейтрализатор изношен — возможно нужна замена',
      probability: 65,
      repairCategory: 'mechanic',
    ));

    causes.add(const PossibleCause(
      description: 'Downstream O2 sensor faulty (giving false reading)',
      descriptionRu: 'Неисправен нижний кислородный датчик (ложные показания)',
      probability: 50,
      repairCategory: 'diagnostics',
    ));

    if (live.shortTermFuelTrim.abs() > 15 || live.longTermFuelTrim.abs() > 12) {
      causes.add(const PossibleCause(
        description: 'Fuel system issue causing excess emissions and catalyst wear',
        descriptionRu: 'Проблема топливной системы вызывает повышенный выброс и износ катализатора',
        probability: 55,
        confirmedBySensors: ['Fuel trims abnormal'],
        repairCategory: 'diagnostics',
      ));
    }

    causes.add(const PossibleCause(
      description: 'Exhaust leak before catalytic converter',
      descriptionRu: 'Утечка выхлопа перед каталитическим нейтрализатором',
      probability: 30,
      repairCategory: 'mechanic',
    ));

    causes.sort((a, b) => b.probability.compareTo(a.probability));
    return RuleResult(causes: causes);
  }
}
