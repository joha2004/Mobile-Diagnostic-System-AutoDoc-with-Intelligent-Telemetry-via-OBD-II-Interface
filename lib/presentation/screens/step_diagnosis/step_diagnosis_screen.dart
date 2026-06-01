import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';


class StepDiagnosisScreen extends ConsumerStatefulWidget {
  const StepDiagnosisScreen({super.key});

  @override
  ConsumerState<StepDiagnosisScreen> createState() => _StepDiagnosisScreenState();
}

class _StepDiagnosisScreenState extends ConsumerState<StepDiagnosisScreen> {
  int _currentStepIndex = 0;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(localeProvider);
    final dtc = ref.watch(selectedDtcProvider);
    final resultsMap = ref.watch(diagnosticResultsProvider);
    final result = dtc != null ? resultsMap[dtc.code] : null;

    if (dtc == null || result == null || result.suggestedSteps.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                t.get('errors_no_errors'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(bottomNavIndexProvider.notifier).state = 2,
                child: Text(t.get('step_previous')),
              )
            ],
          ),
        ),
      );
    }

    final steps = result.suggestedSteps;
    final isLastStep = _currentStepIndex == steps.length - 1;
    final progress = (_currentStepIndex + 1) / steps.length;
    final step = steps[_currentStepIndex];
    final isRu = t.languageCode == 'ru';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (_currentStepIndex > 0) {
                        setState(() => _currentStepIndex--);
                      } else {
                        ref.read(bottomNavIndexProvider.notifier).state = 5; // Back to Analysis
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      t.get('step_title'),
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${t.get('step_progress')} ${_currentStepIndex + 1} / ${steps.length}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Step Content Card
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  key: ValueKey<int>(_currentStepIndex),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.surfaceHighlight.withAlpha(200),
                          AppColors.surface.withAlpha(150),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(50),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(20),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: _getIconForCheckType(step.checkType),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                isRu ? step.titleRu : step.title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isRu ? step.descriptionRu : step.description,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                              ),
                              const Spacer(),
                              if (step.checkType == 'tool')
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.warning.withAlpha(50)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber, color: AppColors.warning, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          isRu
                                              ? 'Используйте OBD сканер для сброса ошибок перед тест-драйвом.'
                                              : 'Use the OBD scanner to clear errors before a test drive.',
                                          style: const TextStyle(
                                            color: AppColors.warning,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStepIndex > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _currentStepIndex--);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.textTertiary),
                        ),
                        child: Text(
                          t.get('step_previous'),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  if (_currentStepIndex > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(60),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (isLastStep) {
                            if (step.checkType == 'tool') {
                              // Action to clear DTC and navigate
                              await ref.read(dtcCodesProvider.notifier).clearDtcCodes();
                            }
                            ref.read(bottomNavIndexProvider.notifier).state = 2; // Go back to Errors screen
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t.get('step_done')),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          } else {
                            setState(() => _currentStepIndex++);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          isLastStep ? t.get('step_finish') : t.get('step_next'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getIconForCheckType(String? checkType) {
    IconData iconData;
    switch (checkType) {
      case 'visual':
        iconData = Icons.visibility;
        break;
      case 'sensor':
        iconData = Icons.sensors;
        break;
      case 'tool':
        iconData = Icons.build;
        break;
      default:
        iconData = Icons.check_circle_outline;
    }
    return Icon(iconData, size: 48, color: AppColors.primary);
  }
}
