import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Error dialog shown when BLE connection fails
class ConnectErrorDialog extends StatelessWidget {
  final String deviceName;
  final String errorMessage;
  final VoidCallback onRetry;

  const ConnectErrorDialog({
    super.key,
    required this.deviceName,
    required this.errorMessage,
    required this.onRetry,
  });

  static Future<void> show(
    BuildContext context, {
    required String deviceName,
    required String errorMessage,
    required VoidCallback onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ConnectErrorDialog(
        deviceName: deviceName,
        errorMessage: errorMessage,
        onRetry: onRetry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.error.withAlpha(100), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withAlpha(60),
              blurRadius: 40,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withAlpha(25),
                border: Border.all(color: AppColors.error.withAlpha(100)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withAlpha(80),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.bluetooth_disabled, color: AppColors.error, size: 34),
            ),
            const SizedBox(height: 20),
            Text(
              'Ошибка подключения',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              deviceName,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withAlpha(40)),
              ),
              child: Text(
                errorMessage,
                style: TextStyle(fontSize: 12, color: AppColors.error.withAlpha(200)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textTertiary),
                    ),
                    child: const Text('Закрыть'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRetry();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Повторить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
