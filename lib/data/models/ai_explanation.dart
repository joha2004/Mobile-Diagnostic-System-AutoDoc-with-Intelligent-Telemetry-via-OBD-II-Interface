import 'package:equatable/equatable.dart';

/// AI-generated explanation of diagnostic results
class AiExplanation extends Equatable {
  final String dtcCode;
  final String problem;
  final String symptoms;
  final String dangerLevel;     // Низкая / Средняя / Высокая
  final String canDrive;        // Да / Да но аккуратно / Нет
  final List<AiCause> causes;
  final String repairCost;
  final String specialistType;
  final double confidence;
  final DateTime generatedAt;
  final bool isOffline;         // Generated from local DB, not AI

  const AiExplanation({
    required this.dtcCode,
    required this.problem,
    required this.symptoms,
    required this.dangerLevel,
    required this.canDrive,
    this.causes = const [],
    required this.repairCost,
    required this.specialistType,
    required this.confidence,
    required this.generatedAt,
    this.isOffline = false,
  });

  factory AiExplanation.fromApiResponse(String dtcCode, Map<String, dynamic> json) {
    final causesRaw = json['causes'] as List<dynamic>? ?? [];
    return AiExplanation(
      dtcCode: dtcCode,
      problem: json['problem'] as String? ?? 'Не удалось определить',
      symptoms: json['symptoms'] as String? ?? '',
      dangerLevel: json['danger_level'] as String? ?? 'Средняя',
      canDrive: json['can_drive'] as String? ?? 'Да, но аккуратно',
      causes: causesRaw
          .map((c) => AiCause(
                description: c['description'] as String? ?? '',
                probability: (c['probability'] as num?)?.toDouble() ?? 0,
              ))
          .toList(),
      repairCost: json['repair_cost'] as String? ?? 'Неизвестно',
      specialistType: json['specialist'] as String? ?? 'Диагност',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 50,
      generatedAt: DateTime.now(),
    );
  }

  factory AiExplanation.offline({
    required String dtcCode,
    required String description,
  }) {
    return AiExplanation(
      dtcCode: dtcCode,
      problem: description,
      symptoms: 'Для подробного анализа требуется подключение к интернету',
      dangerLevel: 'Средняя',
      canDrive: 'Да, но аккуратно',
      causes: [],
      repairCost: 'Неизвестно',
      specialistType: 'Диагност',
      confidence: 30,
      generatedAt: DateTime.now(),
      isOffline: true,
    );
  }

  @override
  List<Object?> get props => [dtcCode, problem, generatedAt];
}

class AiCause extends Equatable {
  final String description;
  final double probability;

  const AiCause({
    required this.description,
    required this.probability,
  });

  @override
  List<Object?> get props => [description, probability];
}
