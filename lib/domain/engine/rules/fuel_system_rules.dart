import '../../../data/models/dtc_code.dart';
import '../../../data/models/live_data.dart';
import '../../../data/models/diagnostic_result.dart';
import 'base_rule.dart';

/// Rule set for P0170-P0179: Fuel System issues
class FuelSystemRules {
  static RuleResult analyze(String code, LiveData live, FreezeFrame? ff) {
    final causes = <PossibleCause>[];
    final stft = ff?.stft ?? live.shortTermFuelTrim;
    final ltft = ff?.ltft ?? live.longTermFuelTrim;
    final maf = ff?.maf ?? live.mafAirFlow;
    final o2v = ff?.o2Voltage ?? live.o2Voltage;

    if (code == 'P0171' || code == 'P0174') {
      // System Too Lean
      if (stft > 20 && ltft > 15) {
        causes.add(const PossibleCause(
          description: 'Vacuum leak (intake manifold gasket or hose)',
          descriptionRu: 'Подсос воздуха (прокладка впускного коллектора или шланг)',
          probability: 85,
          confirmedBySensors: ['STFT > 20%', 'LTFT > 15%'],
          repairCategory: 'mechanic',
        ));
      }
      if (maf < 3.0 && live.engineLoad > 20) {
        causes.add(const PossibleCause(
          description: 'MAF sensor dirty or faulty',
          descriptionRu: 'Датчик MAF загрязнён или неисправен',
          probability: 70,
          confirmedBySensors: ['MAF low', 'Engine load normal'],
          repairCategory: 'diagnostics',
        ));
      }
      if (live.fuelPressure > 0 && live.fuelPressure < 280) {
        causes.add(const PossibleCause(
          description: 'Weak fuel pump or clogged fuel filter',
          descriptionRu: 'Слабый топливный насос или забит топливный фильтр',
          probability: 60,
          confirmedBySensors: ['Fuel pressure low'],
          repairCategory: 'mechanic',
        ));
      }
      if (o2v < 0.2) {
        causes.add(const PossibleCause(
          description: 'O2 sensor reading very lean',
          descriptionRu: 'Кислородный датчик показывает очень бедную смесь',
          probability: 50,
          confirmedBySensors: ['O2 voltage < 0.2V'],
          repairCategory: 'diagnostics',
        ));
      }
      if (causes.isEmpty) {
        causes.add(const PossibleCause(
          description: 'Unmetered air entering after MAF sensor',
          descriptionRu: 'Неучтённый воздух после датчика MAF',
          probability: 55,
          repairCategory: 'diagnostics',
        ));
      }
    } else if (code == 'P0172' || code == 'P0175') {
      // System Too Rich
      if (stft < -15 && ltft < -10) {
        causes.add(const PossibleCause(
          description: 'Leaking fuel injector',
          descriptionRu: 'Подтекающая форсунка',
          probability: 75,
          confirmedBySensors: ['STFT < -15%', 'LTFT < -10%'],
          repairCategory: 'mechanic',
        ));
      }
      if (live.fuelPressure > 420) {
        causes.add(const PossibleCause(
          description: 'Fuel pressure too high (faulty regulator)',
          descriptionRu: 'Давление топлива слишком высокое (неисправен регулятор)',
          probability: 70,
          confirmedBySensors: ['Fuel pressure high'],
          repairCategory: 'mechanic',
        ));
      }
      if (o2v > 0.9) {
        causes.add(const PossibleCause(
          description: 'O2 sensor stuck rich or coolant temp sensor fault',
          descriptionRu: 'Кислородный датчик заклинил или неисправен датчик температуры ОЖ',
          probability: 60,
          confirmedBySensors: ['O2 voltage > 0.9V'],
          repairCategory: 'diagnostics',
        ));
      }
      if (causes.isEmpty) {
        causes.add(const PossibleCause(
          description: 'Excessive fuel delivery',
          descriptionRu: 'Чрезмерная подача топлива',
          probability: 50,
          repairCategory: 'diagnostics',
        ));
      }
    } else {
      // P0170, P0173: General fuel trim issues
      causes.add(const PossibleCause(
        description: 'Fuel trim out of acceptable range',
        descriptionRu: 'Топливная коррекция вышла за допустимые пределы',
        probability: 60,
        repairCategory: 'diagnostics',
      ));
    }

    // Sort by probability
    causes.sort((a, b) => b.probability.compareTo(a.probability));
    return RuleResult(causes: causes);
  }
}
