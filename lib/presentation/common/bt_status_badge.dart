import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../providers/bluetooth_provider.dart';
import '../../../core/theme/app_colors.dart';

/// Live BT connection badge showing signal strength + device name.
/// Shows in top-right of screens when connected to real OBD adapter.
class BtStatusBadge extends ConsumerWidget {
  const BtStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connStatus = ref.watch(connectionStatusProvider);
    final isDemo = ref.watch(isDemoModeProvider);

    if (isDemo) return _DemoBadge();
    if (connStatus != ConnectionStatus.connected) return const SizedBox.shrink();

    final device = ref.read(bluetoothManagerProvider).connectedDevice;
    final deviceName = device?.platformName ?? 'OBD';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(),
          const SizedBox(width: 6),
          Text(
            deviceName,
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withAlpha(80), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_outline, color: AppColors.warning, size: 12),
          SizedBox(width: 4),
          Text(
            'DEMO',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated pulsing green dot
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _opacity = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 7, height: 7,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success,
        ),
      ),
    );
  }
}
