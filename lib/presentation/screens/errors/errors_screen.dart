import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../data/models/dtc_code.dart';

class ErrorsScreen extends ConsumerWidget {
  const ErrorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(localeProvider);
    final dtcCodes = ref.watch(dtcCodesProvider);
    final status = ref.watch(connectionStatusProvider);
    final isRu = t.languageCode == 'ru';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => ref.read(bottomNavIndexProvider.notifier).state = 1,
                  ),
                  const SizedBox(width: 8),
                  Text(t.get('errors_title'), style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  if (dtcCodes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${dtcCodes.length}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (dtcCodes.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 80, color: AppColors.success),
                      const SizedBox(height: 16),
                      Text(t.get('errors_no_errors'), style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(t.get('errors_no_errors_desc'), style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: dtcCodes.length,
                  itemBuilder: (context, index) {
                    final dtc = dtcCodes[index];
                    return _DtcCard(
                      dtc: dtc,
                      isRu: isRu,
                      locale: t,
                      onAnalyze: () {
                        ref.read(selectedDtcProvider.notifier).state = dtc;
                        // Navigate to analysis — handled by parent
                        ref.read(bottomNavIndexProvider.notifier).state = 5; // Analysis tab
                      },
                    );
                  },
                ),
              ),

            // Bottom Actions
            if (status == ConnectionStatus.connected)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await ref.read(dtcCodesProvider.notifier).scanDtcCodes();
                        },
                        icon: const Icon(Icons.radar),
                        label: Text(t.get('errors_scan')),
                      ),
                    ),
                    if (dtcCodes.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showClearDialog(context, ref, t),
                          icon: const Icon(Icons.delete_sweep, color: AppColors.warning),
                          label: Text(t.get('errors_clear')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.warning,
                            side: const BorderSide(color: AppColors.warning),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref, AppLocale t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t.get('errors_clear'), style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.get('errors_clear_confirm'), style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.get('errors_clear_warning'),
                      style: const TextStyle(color: AppColors.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(dtcCodesProvider.notifier).clearDtcCodes();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text(t.get('errors_clear')),
          ),
        ],
      ),
    );
  }
}

class _DtcCard extends StatelessWidget {
  final DtcCode dtc;
  final bool isRu;
  final AppLocale locale;
  final VoidCallback onAnalyze;

  const _DtcCard({
    required this.dtc,
    required this.isRu,
    required this.locale,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(dtc.severity);
    final description = isRu ? dtc.descriptionRu : dtc.description;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(150),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: severityColor.withAlpha(20),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Severity indicator
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: severityColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _severityIcon(dtc.severity),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: severityColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dtc.code,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: severityColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: dtc.status == DtcStatus.pending
                                ? locale.get('errors_pending')
                                : locale.get('errors_confirmed'),
                            color: dtc.status == DtcStatus.pending
                                ? AppColors.warning
                                : AppColors.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description.isNotEmpty ? description : dtc.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRu ? dtc.categoryRu : dtc.category,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Freeze Frame indicator
          if (dtc.freezeFrame != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt, size: 14, color: AppColors.accentCyan),
                  const SizedBox(width: 6),
                  Text(
                    locale.get('errors_freeze_frame'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.accentCyan),
                  ),
                ],
              ),
            ),
          
          // Analyze button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAnalyze,
                icon: const Icon(Icons.analytics, size: 18),
                label: Text(locale.get('errors_analyze')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(DtcSeverity severity) {
    switch (severity) {
      case DtcSeverity.critical: return AppColors.critical;
      case DtcSeverity.high: return AppColors.error;
      case DtcSeverity.medium: return AppColors.warning;
      case DtcSeverity.low: return AppColors.success;
    }
  }

  String _severityIcon(DtcSeverity severity) {
    switch (severity) {
      case DtcSeverity.critical: return '🚨';
      case DtcSeverity.high: return '🔴';
      case DtcSeverity.medium: return '🟡';
      case DtcSeverity.low: return '🟢';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
