import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Overlay banner shown during auto-reconnect attempts
class ReconnectingBanner extends StatefulWidget {
  final String deviceName;
  final int attempt;
  final int maxAttempts;
  final VoidCallback onCancel;

  const ReconnectingBanner({
    super.key,
    required this.deviceName,
    required this.attempt,
    required this.maxAttempts,
    required this.onCancel,
  });

  @override
  State<ReconnectingBanner> createState() => _ReconnectingBannerState();
}

class _ReconnectingBannerState extends State<ReconnectingBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2D1F00),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withAlpha(120), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withAlpha(60),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) => Transform.rotate(
                angle: _ctrl.value * 6.28,
                child: const Icon(Icons.refresh, color: AppColors.warning, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Переподключение... (${widget.attempt}/${widget.maxAttempts})',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    widget.deviceName,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: widget.onCancel,
              child: const Text('Отмена', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
