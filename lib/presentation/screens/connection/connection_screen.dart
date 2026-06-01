import 'dart:async';

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../providers/app_providers.dart';
import '../../providers/bluetooth_provider.dart';
import '../../../core/bluetooth/bluetooth_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/connecting_dialog.dart';
import 'widgets/connect_success_dialog.dart';
import 'widgets/connect_error_dialog.dart';
import 'widgets/reconnecting_banner.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});
  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _radarCtrl;
  late AnimationController _pulseCtrl;
  bool _isConnecting = false;
  ScanResult? _connectingDevice;
  StreamSubscription? _btLogSub;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenBtStatus();
      _listenLogs();
    });
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _pulseCtrl.dispose();
    _btLogSub?.cancel();
    super.dispose();
  }

  void _listenLogs() {
    final manager = ref.read(bluetoothManagerProvider);
    _btLogSub = manager.logStream.listen((log) {
      if (mounted) setState(() => _logs.insert(0, log));
    });
  }

  void _listenBtStatus() {
    final manager = ref.read(bluetoothManagerProvider);
    manager.statusStream.listen((status) {
      if (!mounted) return;
      final connStatus = ref.read(connectionStatusProvider);

      if (status == BtStatus.reconnecting) {
        ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.reconnecting;
      } else if (status == BtStatus.connected && connStatus == ConnectionStatus.reconnecting) {
        // Reconnection succeeded
        ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.connected;
        ref.read(liveDataProvider.notifier).startListening();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Переподключение успешно'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (status == BtStatus.error && connStatus == ConnectionStatus.reconnecting) {
        ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.error;
      }
    });
  }

  Future<void> _startScan() async {

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Включите Bluetooth на устройстве'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    _radarCtrl.repeat();
    ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.scanning;
    final manager = ref.read(bluetoothManagerProvider);
    await manager.startScan(timeout: const Duration(seconds: 15));
    if (mounted) {
      _radarCtrl.stop();
      _radarCtrl.reset();
      final status = ref.read(connectionStatusProvider);
      if (status == ConnectionStatus.scanning) {
        ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.disconnected;
      }
    }
  }

  Future<void> _connectToDevice(ScanResult result) async {
    if (_isConnecting) return;
    setState(() {
      _isConnecting = true;
      _connectingDevice = result;
    });

    final deviceName = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : 'OBD Device';

    // Show connecting dialog
    ConnectingDialog.show(
      context,
      deviceName: deviceName,
      deviceId: result.device.remoteId.str,
      onCancel: () {
        setState(() => _isConnecting = false);
        Navigator.of(context).pop();
        ref.read(bluetoothManagerProvider).stopScan();
      },
    );

    ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.connecting;
    ref.read(isDemoModeProvider.notifier).state = false;

    final realObd = ref.read(realObdSourceProvider);
    final success = await realObd.connect(result.device);

    // Dismiss connecting dialog
    if (mounted) Navigator.of(context).pop();

    setState(() => _isConnecting = false);

    if (success && mounted) {
      ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.connected;
      ref.read(vehicleInfoProvider.notifier).state = realObd.getVehicleInfo();
      ref.read(liveDataProvider.notifier).startListening();

      // Read VIN in background
      realObd.readVin();

      // Show success popup
      await ConnectSuccessDialog.show(context, deviceName: deviceName);

      // Navigate to dashboard
      if (mounted) {
        await ref.read(dtcCodesProvider.notifier).scanDtcCodes();
        ref.read(bottomNavIndexProvider.notifier).state = 1;
      }
    } else if (mounted) {
      ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.error;
      ConnectErrorDialog.show(
        context,
        deviceName: deviceName,
        errorMessage: 'Не удалось установить соединение с адаптером.\n'
            'Убедитесь что адаптер подключён к OBD-II разъёму.',
        onRetry: () => _connectToDevice(result),
      );
    }
  }

  Future<void> _startDemoMode() async {
    ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.connecting;
    final demo = ref.read(demoObdSourceProvider);
    await demo.connect();
    ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.connected;
    ref.read(isDemoModeProvider.notifier).state = true;
    ref.read(vehicleInfoProvider.notifier).state = demo.getVehicleInfo();
    ref.read(liveDataProvider.notifier).startListening();
    await ref.read(dtcCodesProvider.notifier).scanDtcCodes();
    if (mounted) ref.read(bottomNavIndexProvider.notifier).state = 1;
  }

  Future<void> _disconnect() async {
    final isDemo = ref.read(isDemoModeProvider);
    if (isDemo) {
      await ref.read(demoObdSourceProvider).disconnect();
    } else {
      await ref.read(bluetoothManagerProvider).disconnect();
      await ref.read(realObdSourceProvider).disconnect();
    }
    ref.read(liveDataProvider.notifier).stopListening();
    ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.disconnected;
    ref.read(vehicleInfoProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(localeProvider);
    final status = ref.watch(connectionStatusProvider);
    final scanResults = ref.watch(btScanResultsProvider);
    final btStatus = ref.watch(btStatusProvider);
    final isScanning = btStatus == BtStatus.scanning;
    final isConnected = status == ConnectionStatus.connected;
    final isReconnecting = status == ConnectionStatus.reconnecting;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, t, isConnected),
                if (btStatus == BtStatus.adapterOff) _buildBluetoothOffBanner(context),
                if (btStatus == BtStatus.permissionDenied) _buildPermissionBanner(context),
                Expanded(
                  flex: isConnected ? 2 : 3,
                  child: _buildRadar(context, scanResults, isScanning, status),
                ),
                if (!isConnected && scanResults.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: _buildDeviceList(scanResults, t, status),
                  ),
                _buildActions(context, t, status, isScanning, isConnected),
              ],
            ),
          ),
          // Reconnecting banner overlay
          if (isReconnecting)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: ReconnectingBanner(
                  deviceName: ref.read(bluetoothManagerProvider).connectedDevice?.platformName ?? 'OBD',
                  attempt: 1,
                  maxAttempts: 5,
                  onCancel: _disconnect,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocale t, bool isConnected) {
    final status = ref.watch(connectionStatusProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Auto Doctor',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor(status),
                        boxShadow: [BoxShadow(color: _statusColor(status).withAlpha(150), blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _statusText(status, t),
                      style: TextStyle(color: _statusColor(status), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isConnected)
            IconButton(
              onPressed: _disconnect,
              icon: const Icon(Icons.link_off, color: AppColors.error),
              tooltip: 'Отключить',
            ),
        ],
      ),
    );
  }

  Widget _buildBluetoothOffBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_disabled, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Bluetooth выключен. Включите Bluetooth для поиска устройств.',
              style: TextStyle(color: AppColors.warning, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Нет разрешений Bluetooth. Откройте настройки приложения.',
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: openAppSettings,
            child: const Text('Настройки', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildRadar(BuildContext context, List<ScanResult> devices, bool isScanning, ConnectionStatus status) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Radar rings
            ...List.generate(3, (i) => AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) => Container(
                width: 90.0 + i * 85 + (isScanning ? _pulseCtrl.value * 5 : 0),
                height: 90.0 + i * 85 + (isScanning ? _pulseCtrl.value * 5 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withAlpha(15 + i * 20),
                    width: 1.5,
                  ),
                ),
              ),
            )),
            // Radar sweep
            if (isScanning)
              AnimatedBuilder(
                animation: _radarCtrl,
                builder: (context, child) => Transform.rotate(
                  angle: _radarCtrl.value * 2 * pi,
                  child: CustomPaint(
                    size: const Size(280, 280),
                    painter: _RadarPainter(),
                  ),
                ),
              ),
            // Center button
            GestureDetector(
              onTap: status == ConnectionStatus.connected ? null : _startScan,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, child) => Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: status == ConnectionStatus.connected
                        ? AppColors.successGradient
                        : AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: (status == ConnectionStatus.connected
                                ? AppColors.success
                                : AppColors.primary)
                            .withAlpha((80 + _pulseCtrl.value * 60).round()),
                        blurRadius: 25 + _pulseCtrl.value * 10,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    status == ConnectionStatus.connected
                        ? Icons.check_rounded
                        : isScanning
                            ? Icons.radar
                            : Icons.bluetooth_searching,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
            // Device dots
            ...devices.asMap().entries.map((entry) {
              final i = entry.key;
              final device = entry.value;
              final angle = (i * 1.4 + 0.5) % (2 * pi);
              final radius = 75.0 + (i % 3) * 35;
              return Positioned(
                left: 140 + cos(angle) * radius - 10,
                top: 140 + sin(angle) * radius - 10,
                child: _DeviceDot(
                  result: device,
                  onTap: () => _connectToDevice(device),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(List<ScanResult> devices, AppLocale t, ConnectionStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Text(
                'Найдено устройств: ${devices.length}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: devices.length,
            itemBuilder: (_, i) => _DeviceCard(
              result: devices[i],
              onConnect: () => _connectToDevice(devices[i]),
              isConnecting: _isConnecting && _connectingDevice?.device.remoteId == devices[i].device.remoteId,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, AppLocale t, ConnectionStatus status, bool isScanning, bool isConnected) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        children: [
          if (!isConnected) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isScanning || _isConnecting ? null : _startScan,
                icon: Icon(isScanning ? Icons.radar : Icons.search),
                label: Text(isScanning ? 'Сканирование...' : 'Поиск OBD устройств'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isConnecting ? null : _startDemoMode,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Демо режим (без адаптера)'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
          if (status == ConnectionStatus.connecting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(ConnectionStatus s) {
    switch (s) {
      case ConnectionStatus.connected:    return AppColors.success;
      case ConnectionStatus.connecting:   return AppColors.warning;
      case ConnectionStatus.scanning:     return AppColors.primary;
      case ConnectionStatus.error:        return AppColors.error;
      case ConnectionStatus.reconnecting: return AppColors.warning;
      default:                            return AppColors.textTertiary;
    }
  }

  String _statusText(ConnectionStatus s, AppLocale t) {
    switch (s) {
      case ConnectionStatus.connected:    return 'Подключено';
      case ConnectionStatus.connecting:   return 'Подключение...';
      case ConnectionStatus.scanning:     return 'Поиск устройств...';
      case ConnectionStatus.error:        return 'Ошибка подключения';
      case ConnectionStatus.reconnecting: return 'Переподключение...';
      default:                            return 'Не подключено';
    }
  }
}

// ─── Device Dot on Radar ──────────────────────────────────────────────────────

class _DeviceDot extends StatefulWidget {
  final ScanResult result;
  final VoidCallback onTap;
  const _DeviceDot({required this.result, required this.onTap});

  @override
  State<_DeviceDot> createState() => _DeviceDotState();
}

class _DeviceDotState extends State<_DeviceDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha((100 + _ctrl.value * 100).round()),
                blurRadius: 8 + _ctrl.value * 8,
              ),
            ],
          ),
          child: const Icon(Icons.bluetooth, color: Colors.white, size: 12),
        ),
      ),
    );
  }
}

// ─── Device List Card ────────────────────────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onConnect;
  final bool isConnecting;

  const _DeviceCard({required this.result, required this.onConnect, this.isConnecting = false});

  @override
  Widget build(BuildContext context) {
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : result.advertisementData.advName.isNotEmpty
            ? result.advertisementData.advName
            : 'Unknown Device';
    final rssi = result.rssi;
    final signalBars = rssi > -60 ? 3 : rssi > -75 ? 2 : 1;
    final signalColor = rssi > -60 ? AppColors.success : rssi > -75 ? AppColors.warning : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
        boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(10), blurRadius: 12)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withAlpha(25),
            border: Border.all(color: AppColors.primary.withAlpha(60)),
          ),
          child: const Icon(Icons.bluetooth, color: AppColors.primary, size: 22),
        ),
        title: Text(name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.device.remoteId.str,
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontFamily: 'monospace')),
            const SizedBox(height: 4),
            Row(
              children: [
                ...List.generate(3, (i) => Container(
                  width: 5,
                  height: 5 + i * 3.0,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: i < signalBars ? signalColor : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
                const SizedBox(width: 6),
                Text('$rssi dBm', style: TextStyle(fontSize: 11, color: signalColor)),
              ],
            ),
          ],
        ),
        trailing: isConnecting
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary))
            : ElevatedButton(
                onPressed: onConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(72, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Подключить', style: TextStyle(fontSize: 12)),
              ),
      ),
    );
  }
}

// ─── Radar Painter ────────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: pi / 1.5,
        colors: [AppColors.primary.withAlpha(0), AppColors.primary.withAlpha(70)],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2),
      -pi / 2,
      pi / 1.5,
      true,
      paint,
    );
    // Leading line
    final linePaint = Paint()
      ..color = AppColors.primary.withAlpha(150)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, Offset(center.dx, center.dy - size.width / 2), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
