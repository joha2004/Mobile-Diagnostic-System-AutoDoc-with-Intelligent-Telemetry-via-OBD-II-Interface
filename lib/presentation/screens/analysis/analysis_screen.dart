import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../../data/models/ai_explanation.dart';
import '../../../data/models/diagnostic_result.dart';
import '../../../data/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  bool _isAnalyzing = false;
  bool _hasStarted = false;  // Guard against double-start
  DiagnosticResult? _result;
  AiExplanation? _explanation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasStarted) {
        _hasStarted = true;
        _runAnalysis();
      }
    });
  }

  Future<void> _runAnalysis() async {
    final dtc = ref.read(selectedDtcProvider);
    final liveData = ref.read(liveDataProvider);
    if (dtc == null || liveData == null) return;

    setState(() => _isAnalyzing = true);

    // Step 1: Rule-based analysis
    final engine = ref.read(diagnosticEngineProvider);
    final result = engine.analyze(
      dtc: dtc,
      liveData: liveData,
      freezeFrame: dtc.freezeFrame,
    );
    setState(() => _result = result);
    
    // Save to provider for StepDiagnosisScreen
    final map = ref.read(diagnosticResultsProvider);
    ref.read(diagnosticResultsProvider.notifier).state = {...map, dtc.code: result};

    // Step 2: AI explanation — use singleton service from notifier
    try {
      final lang = ref.read(languageProvider);
      // Get the SINGLETON service, not a new instance each time
      final aiService = ref.read(geminiServiceProvider.notifier).service;

      final explanation = await aiService.explain(
        result: result,
        languageCode: lang,
      );
      if (mounted) setState(() => _explanation = explanation);
    } catch (e) {
      if (mounted) {
        setState(() {
          _explanation = AiExplanation.offline(
            dtcCode: dtc.code,
            description: dtc.descriptionRu.isNotEmpty ? dtc.descriptionRu : dtc.description,
          );
        });
      }
    }

    setState(() => _isAnalyzing = false);

    // Save to Drift DB
    try {
      final db = ref.read(appDatabaseProvider);
      final allDtcs = ref.read(dtcCodesProvider);
      final healthScore = ref.read(healthScoreProvider);
      if (healthScore >= 0) {
        await db.insertSession(
          DiagnosticSessionsCompanion.insert(
            timestamp: DateTime.now(),
            healthScore: healthScore,
            dtcCodesJson: jsonEncode(allDtcs.map((d) => d.code).toList()),
            severity: drift.Value(result.overallSeverity),
            aiSummary: drift.Value(_explanation?.problem),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save session to DB: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(localeProvider);
    final dtc = ref.watch(selectedDtcProvider);

    if (dtc == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Text(t.get('errors_no_errors'), style: Theme.of(context).textTheme.headlineSmall),
        ),
      );
    }

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
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => ref.read(bottomNavIndexProvider.notifier).state = 2,
                  ),
                  Expanded(
                    child: Text(
                      '${t.get('analysis_title')}: ${dtc.code}',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            if (_isAnalyzing)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(100),
                              blurRadius: 30,
                              spreadRadius: 10,
                            )
                          ],
                        ),
                        child: const CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            t.get('analysis_ai_loading'),
                            textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              shadows: [
                                Shadow(color: AppColors.primary.withAlpha(150), blurRadius: 10)
                              ],
                            ),
                            speed: const Duration(milliseconds: 100),
                            cursor: '_',
                          ),
                        ],
                        repeatForever: true,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Rule-based causes with probabilities
                      if (_result != null) ...[
                        _SectionCard(
                          title: t.get('analysis_causes'),
                          child: Column(
                            children: _result!.causes.map((cause) {
                              final isRu = t.languageCode == 'ru';
                              return _CauseBar(
                                description: isRu ? cause.descriptionRu : cause.description,
                                probability: cause.probability,
                                sensors: cause.confirmedBySensors,
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Can drive?
                        _InfoCard(
                          icon: '🚗',
                          title: t.get('analysis_can_drive'),
                          value: _result!.canDrive
                              ? (_result!.overallSeverity == 'medium'
                                  ? t.get('analysis_careful')
                                  : t.get('analysis_yes'))
                              : t.get('analysis_no'),
                          note: _result!.canDriveNote,
                          color: _result!.canDrive ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // AI Explanation
                      if (_explanation != null) ...[
                        _SectionCard(
                          title: t.get('analysis_problem'),
                          child: DefaultTextStyle(
                            style: Theme.of(context).textTheme.bodyLarge!,
                            child: AnimatedTextKit(
                              animatedTexts: [
                                TypewriterAnimatedText(
                                  _explanation!.problem,
                                  speed: const Duration(milliseconds: 20),
                                ),
                              ],
                              isRepeatingAnimation: false,
                              displayFullTextOnTap: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (_explanation!.symptoms.isNotEmpty)
                          _SectionCard(
                            title: t.get('analysis_symptoms'),
                            child: DefaultTextStyle(
                              style: Theme.of(context).textTheme.bodyMedium!,
                              child: AnimatedTextKit(
                                animatedTexts: [
                                  TypewriterAnimatedText(
                                    _explanation!.symptoms,
                                    speed: const Duration(milliseconds: 20),
                                  ),
                                ],
                                isRepeatingAnimation: false,
                                displayFullTextOnTap: true,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _InfoCard(
                                icon: '⚠️',
                                title: t.get('analysis_danger'),
                                value: _explanation!.dangerLevel,
                                color: AppColors.severityColor(_explanation!.dangerLevel),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InfoCard(
                                icon: '📊',
                                title: t.get('analysis_confidence'),
                                value: '${_explanation!.confidence.toStringAsFixed(0)}%',
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _SectionCard(
                          title: t.get('analysis_repair_cost'),
                          child: Text(
                            _explanation!.repairCost,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _SectionCard(
                          title: t.get('analysis_specialist'),
                          child: Row(
                            children: [
                              const Text('👨‍🔧 ', style: TextStyle(fontSize: 24)),
                              Text(
                                _explanation!.specialistType,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),

                        if (_explanation!.isOffline)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.warning.withAlpha(50)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.wifi_off, color: AppColors.warning, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      t.get('offline_mode'),
                                      style: const TextStyle(color: AppColors.warning, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],

                      // Freeze Frame
                      if (dtc.freezeFrame != null) ...[
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: t.get('errors_freeze_frame'),
                          child: Column(
                            children: dtc.freezeFrame!.toMap().entries.map((e) {
                              if (e.value == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key, style: Theme.of(context).textTheme.bodySmall),
                                    Text(
                                      e.value!.toStringAsFixed(1),
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Step Diagnosis Button
                      if (_result != null && _result!.suggestedSteps.isNotEmpty)
                        Container(
                          width: double.infinity,
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
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ref.read(bottomNavIndexProvider.notifier).state = 7; // Go to Step Diagnosis
                            },
                            icon: const Icon(Icons.build, color: Colors.white),
                            label: Text(
                              t.get('step_title'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(10),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final String? note;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.note,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 12,
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _CauseBar extends StatelessWidget {
  final String description;
  final double probability;
  final List<String> sensors;

  const _CauseBar({
    required this.description,
    required this.probability,
    required this.sensors,
  });

  @override
  Widget build(BuildContext context) {
    final color = probability > 70
        ? AppColors.error
        : probability > 40
            ? AppColors.warning
            : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(description, style: Theme.of(context).textTheme.bodyMedium),
              ),
              Text(
                '${probability.toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: probability / 100,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          if (sensors.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: sensors.map((s) => Chip(
                label: Text(s, style: const TextStyle(fontSize: 10)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
