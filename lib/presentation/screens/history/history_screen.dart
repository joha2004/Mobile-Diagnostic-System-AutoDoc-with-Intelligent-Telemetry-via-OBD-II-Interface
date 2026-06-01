import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(localeProvider);
    final history = ref.watch(diagnosticHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => ref.read(bottomNavIndexProvider.notifier).state = 1,
                  ),
                  const SizedBox(width: 8),
                  Text(t.get('history_title'), style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
            Expanded(
              child: history.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: 80, color: AppColors.textTertiary.withAlpha(100)),
                          const SizedBox(height: 16),
                          Text(t.get('history_empty'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.textTertiary)),
                          const SizedBox(height: 8),
                          Text(t.get('history_empty_desc'), style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final entry = sessions[index];
                      final color = AppColors.healthScoreColor(entry.healthScore);
                      
                      final errorList = (jsonDecode(entry.dtcCodesJson) as List)
                          .map((e) => e.toString())
                          .toList();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            // Health Score Circle
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: entry.healthScore / 100,
                                    strokeWidth: 5,
                                    backgroundColor: AppColors.surfaceLight,
                                    valueColor: AlwaysStoppedAnimation(color),
                                  ),
                                  Text(
                                    '${entry.healthScore}',
                                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${entry.timestamp.day}.${entry.timestamp.month}.${entry.timestamp.year}  ${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${t.get('history_errors_found')}: ${errorList.length}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (errorList.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Wrap(
                                        spacing: 4,
                                        children: errorList.map((c) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withAlpha(20),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(c, style: const TextStyle(color: AppColors.error, fontSize: 10)),
                                        )).toList(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
