import '../../../data/models/dtc_code.dart';
import '../../../data/models/live_data.dart';
import '../../../data/models/diagnostic_result.dart';
import 'base_rule.dart';

/// Rule set for P0300-P0312: Misfire issues
class MisfireRules {
  static RuleResult analyze(String code, LiveData live, FreezeFrame? ff) {
    final causes = <PossibleCause>[];
    final isRandom = code == 'P0300';
    final stft = ff?.stft ?? live.shortTermFuelTrim;
    final ltft = ff?.ltft ?? live.longTermFuelTrim;

    if (isRandom) {
      // P0300: Random misfire — multiple possible causes
      if (stft.abs() > 20 || ltft.abs() > 15) {
        causes.add(const PossibleCause(
          description: 'Fuel delivery issue causing misfires in multiple cylinders',
          descriptionRu: 'Проблема подачи топлива вызывает пропуски в нескольких цилиндрах',
          probability: 75,
          confirmedBySensors: ['Fuel trims abnormal'],
          repairCategory: 'mechanic',
        ));
      }
      causes.add(const PossibleCause(
        description: 'Worn spark plugs or ignition coils',
        descriptionRu: 'Изношенные свечи зажигания или катушки',
        probability: 80,
        repairCategory: 'mechanic',
      ));
      if (live.coolantTemp < 70) {
        causes.add(const PossibleCause(
          description: 'Cold engine — misfires may clear after warmup',
          descriptionRu: 'Холодный двигатель — пропуски могут пройти после прогрева',
          probability: 40,
          confirmedBySensors: ['Coolant temp < 70°C'],
          repairCategory: 'diagnostics',
        ));
      }
    } else {
      // Specific cylinder misfire P0301-P0312
      final cylStr = code.substring(4);
      final cyl = int.tryParse(cylStr) ?? 0;
      
      causes.add(PossibleCause(
        description: 'Faulty spark plug in cylinder $cyl',
        descriptionRu: 'Неисправная свеча зажигания цилиндра $cyl',
        probability: 75,
        repairCategory: 'mechanic',
      ));
      causes.add(PossibleCause(
        description: 'Faulty ignition coil for cylinder $cyl',
        descriptionRu: 'Неисправная катушка зажигания цилиндра $cyl',
        probability: 65,
        repairCategory: 'mechanic',
      ));
      causes.add(PossibleCause(
        description: 'Fuel injector issue in cylinder $cyl',
        descriptionRu: 'Проблема с форсункой цилиндра $cyl',
        probability: 45,
        repairCategory: 'mechanic',
      ));
      causes.add(PossibleCause(
        description: 'Low compression in cylinder $cyl',
        descriptionRu: 'Низкая компрессия в цилиндре $cyl',
        probability: 25,
        repairCategory: 'mechanic',
      ));
    }

    // Common causes for all misfires
    if (live.mafAirFlow < 2.0 && live.rpm > 800) {
      causes.add(const PossibleCause(
        description: 'Low air flow may contribute to misfires',
        descriptionRu: 'Низкий расход воздуха может вызвать пропуски',
        probability: 35,
        confirmedBySensors: ['MAF very low'],
        repairCategory: 'diagnostics',
      ));
    }

    causes.sort((a, b) => b.probability.compareTo(a.probability));
    return RuleResult(causes: causes);
  }
}
