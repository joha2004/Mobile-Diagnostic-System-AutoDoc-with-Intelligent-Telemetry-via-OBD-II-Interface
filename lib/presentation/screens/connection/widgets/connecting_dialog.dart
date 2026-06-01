import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Animated dialog shown while connecting to a BLE device
class ConnectingDialog extends StatefulWidget {
  final String deviceName;
  final String deviceId;
  final VoidCallback onCancel;

  const ConnectingDialog({
    super.key,
    required this.deviceName,
    required this.deviceId,
    required this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required String deviceName,
    required String deviceId,
    required VoidCallback onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(160),
      builder: (_) => ConnectingDialog(
        deviceName: deviceName,
        deviceId: deviceId,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<ConnectingDialog> createState() => _ConnectingDialogState();
}

class _ConnectingDialogState extends State<ConnectingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
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
          border: Border.all(color: AppColors.primary.withAlpha(80), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(60),
              blurRadius: 40,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing BT icon
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(
                    (20 + _pulseCtrl.value * 40).round(),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(
                        (60 + (_pulseCtrl.value * 80).round()),
                      ),
                      blurRadius: 20 + _pulseCtrl.value * 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bluetooth_searching,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Подключение...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.deviceName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.deviceId,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
                fontFamily: 'monospace',
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              borderRadius: BorderRadius.circular(4),
              minHeight: 4,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: widget.onCancel,
              child: Text(
                'Отмена',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
