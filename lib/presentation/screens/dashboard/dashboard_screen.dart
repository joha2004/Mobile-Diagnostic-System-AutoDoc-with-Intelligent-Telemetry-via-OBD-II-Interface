import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../domain/engine/health_score_calculator.dart';
import '../../common/bt_status_badge.dart';
import '../chat/ai_chat_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(localeProvider);
    final liveData = ref.watch(liveDataProvider);
    final vehicle = ref.watch(vehicleInfoProvider);
    final healthScore = ref.watch(healthScoreProvider);
    final status = ref.watch(connectionStatusProvider);

    if (status != ConnectionStatus.connected || liveData == null) {
      return _buildNoConnection(context, t);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with BT badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.get('dashboard_title'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const BtStatusBadge(),
                ],
              ),
              const SizedBox(height: 16),

              // AI Chat Prominent Banner
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AiChatScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accentBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(80),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.languageCode == 'ru' ? 'Спросить AI Механика' : 'Ask AI Mechanic',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.languageCode == 'ru'
                                  ? 'Задайте любой вопрос о вашей машине'
                                  : 'Ask any question about your car',
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Vehicle Info Hero
              if (vehicle != null) _VehicleCard(vehicle: vehicle, t: t),
              const SizedBox(height: 16),

              // Health Score Card
              _HealthScoreCard(score: healthScore, t: t),
              const SizedBox(height: 24),

              // Main Gauges Row (Neon Circles)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _GaugeCard(
                      label: t.get('dashboard_rpm'),
                      value: liveData.rpm,
                      maxValue: 8000,
                      unit: t.get('dashboard_rpm_unit'),
                      color: _rpmColor(liveData.rpm),
                      icon: Icons.speed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GaugeCard(
                      label: t.get('dashboard_speed'),
                      value: liveData.speed,
                      maxValue: 240,
                      unit: t.get('dashboard_km_h'),
                      color: AppColors.accentBlue,
                      icon: Icons.directions_car,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Engine Load & Coolant Temp
              Row(
                children: [
                  Expanded(
                    child: _GaugeCard(
                      label: t.get('dashboard_engine_load'),
                      value: liveData.engineLoad,
                      maxValue: 100,
                      unit: t.get('dashboard_percent'),
                      color: AppColors.accentPurple,
                      icon: Icons.engineering,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GaugeCard(
                      label: t.get('dashboard_coolant_temp'),
                      value: liveData.coolantTemp,
                      maxValue: 130,
                      unit: t.get('dashboard_celsius'),
                      color: _tempColor(liveData.coolantTemp),
                      icon: Icons.thermostat,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Live Data Section Title
              Text(
                t.get('dashboard_live_data'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),

              // Detailed Live Data Cards
              _LiveDataTile(
                icon: Icons.air,
                label: t.get('dashboard_maf'),
                value: '${liveData.mafAirFlow.toStringAsFixed(1)} g/s',
              ),
              _LiveDataTile(
                icon: Icons.compress,
                label: t.get('dashboard_map_pressure'),
                value: '${liveData.mapPressure.toStringAsFixed(0)} kPa',
              ),
              _LiveDataTile(
                icon: Icons.tune,
                label: t.get('dashboard_stft'),
                value: '${liveData.shortTermFuelTrim.toStringAsFixed(1)}%',
                valueColor: _fuelTrimColor(liveData.shortTermFuelTrim),
              ),
              _LiveDataTile(
                icon: Icons.tune,
                label: t.get('dashboard_ltft'),
                value: '${liveData.longTermFuelTrim.toStringAsFixed(1)}%',
                valueColor: _fuelTrimColor(liveData.longTermFuelTrim),
              ),
              _LiveDataTile(
                icon: Icons.sensors,
                label: t.get('dashboard_o2_voltage'),
                value: '${liveData.o2Voltage.toStringAsFixed(2)} ${t.get('dashboard_volts')}',
              ),
              _LiveDataTile(
                icon: Icons.battery_charging_full,
                label: 'Battery',
                value: '${liveData.batteryVoltage.toStringAsFixed(1)} ${t.get('dashboard_volts')}',
                valueColor: liveData.batteryVoltage < 12.5 ? AppColors.warning : null,
              ),
              _LiveDataTile(
                icon: Icons.thermostat_auto,
                label: t.get('dashboard_intake_temp'),
                value: '${liveData.intakeAirTemp.toStringAsFixed(0)} ${t.get('dashboard_celsius')}',
              ),

              // Bottom spacing for floating navbar
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoConnection(BuildContext context, AppLocale t) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_disabled, size: 80, color: AppColors.textTertiary.withAlpha(100)),
            const SizedBox(height: 16),
            Text(
              t.get('dashboard_no_connection'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _rpmColor(double rpm) {
    if (rpm > 5500) return AppColors.error;
    if (rpm > 3500) return AppColors.warning;
    return AppColors.success;
  }

  Color _tempColor(double temp) {
    if (temp > 105) return AppColors.error;
    if (temp > 95) return AppColors.warning;
    if (temp < 50) return AppColors.accentBlue;
    return AppColors.success;
  }

  Color _fuelTrimColor(double trim) {
    if (trim.abs() > 20) return AppColors.error;
    if (trim.abs() > 10) return AppColors.warning;
    return AppColors.success;
  }
}

class _VehicleCard extends StatelessWidget {
  final dynamic vehicle;
  final AppLocale t;
  const _VehicleCard({required this.vehicle, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 30,
            spreadRadius: -10,
          )
        ],
        border: Border.all(color: AppColors.primary.withAlpha(80), width: 1.5),
        image: const DecorationImage(
          image: AssetImage('assets/car_wireframe.png'), // Might not exist but fails gracefully
          alignment: Alignment.centerRight,
          opacity: 0.1,
          fit: BoxFit.contain,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withAlpha(100)),
                ),
                child: const Icon(Icons.directions_car, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.displayName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          BoxShadow(color: AppColors.primary.withAlpha(200), blurRadius: 10)
                        ],
                      ),
                    ),
                    if (vehicle.protocol != null)
                      Text(
                        'Protocol: ${vehicle.protocol}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (vehicle.vin != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(100),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Text(
                'VIN: ${vehicle.vin}',
                style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', letterSpacing: 1.5),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _HealthScoreCard extends StatelessWidget {
  final int score;
  final AppLocale t;
  const _HealthScoreCard({required this.score, required this.t});

  @override
  Widget build(BuildContext context) {
    final displayScore = score < 0 ? 0 : score;
    final color = AppColors.healthScoreColor(displayScore);
    final isRu = t.languageCode == 'ru';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: displayScore / 100,
                    strokeWidth: 8,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '$displayScore',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.get('dashboard_health_score'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${HealthScoreCalculator.getEmoji(displayScore)} ${HealthScoreCalculator.getLabel(displayScore, russian: isRu)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugeCard extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final String unit;
  final Color color;
  final IconData icon;

  const _GaugeCard({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withAlpha(40), blurRadius: 20, spreadRadius: 0),
                ],
              ),
              child: CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 12.0,
                animation: true,
                animateFromLastPercent: true,
                animationDuration: 300,
                percent: (value / maxValue).clamp(0.0, 1.0),
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: AppColors.surfaceLight,
                progressColor: color,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color.withAlpha(150), size: 16),
                    Text(
                      value.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        shadows: [BoxShadow(color: color, blurRadius: 10)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LiveDataTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _LiveDataTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(150),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withAlpha(100)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10, spreadRadius: 1)
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
