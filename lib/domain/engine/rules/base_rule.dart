import '../../../data/models/diagnostic_result.dart';

/// Common result type returned by all rule sets
class RuleResult {
  final List<PossibleCause> causes;
  const RuleResult({required this.causes});
}
