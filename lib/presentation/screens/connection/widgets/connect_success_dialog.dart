import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Success popup shown after successful BLE connection
class ConnectSuccessDialog extends StatefulWidget {
  final String deviceName;

  const ConnectSuccessDialog({super.key, required this.deviceName});

  static Future<void> show(BuildContext context, {required String deviceName}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(160),
      builder: (_) => ConnectSuccessDialog(deviceName: deviceName),
    );
  }

  @override
  State<ConnectSuccessDialog> createState() => _ConnectSuccessDialogState();
}

class _ConnectSuccessDialogState extends State<ConnectSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.success.withAlpha(100), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withAlpha(80),
                blurRadius: 40,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.success, Color(0xFF00E676)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withAlpha(120),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              Text(
                'Подключено!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.deviceName,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'OBD-II адаптер готов к работе',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
