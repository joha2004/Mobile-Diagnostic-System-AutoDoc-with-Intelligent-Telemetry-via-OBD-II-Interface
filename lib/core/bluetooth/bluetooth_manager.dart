import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../logging/app_logger.dart';

/// Bluetooth connection state
enum BtStatus {
  adapterOff,
  permissionDenied,
  idle,
  scanning,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Central Bluetooth Manager — single source of truth for all BT operations.
/// Handles: permissions, adapter state, scan, connect, disconnect, auto-reconnect.
class BluetoothManager {
  // Singleton
  BluetoothManager._();
  static final BluetoothManager instance = BluetoothManager._();

  // State streams
  final _statusController = StreamController<BtStatus>.broadcast();
  final _scanResultsController = StreamController<List<ScanResult>>.broadcast();
  final _logController = StreamController<String>.broadcast();

  Stream<BtStatus> get statusStream => _statusController.stream;
  Stream<List<ScanResult>> get scanResultsStream => _scanResultsController.stream;
  Stream<String> get logStream => _logController.stream;

  BtStatus _status = BtStatus.idle;
  BtStatus get status => _status;

  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  final Map<String, ScanResult> _scanResults = {};
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults.values.toList()
    ..sort((a, b) => b.rssi.compareTo(a.rssi)));

  StreamSubscription? _adapterSub;
  StreamSubscription? _scanSub;
  StreamSubscription? _connectionSub;
  Timer? _reconnectTimer;
  bool _shouldReconnect = false;
  int _reconnectAttempt = 0;
  static const int _maxReconnectAttempts = 5;

  /// BLE is supported on Android, iOS, macOS, and Windows.
  bool get _isBleSupported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;

  /// Start adapter state monitoring
  void initialize() {
    // flutter_blue_plus does not support Windows/Linux desktop.
    if (!_isBleSupported) {
      AppLogger.bt('Bluetooth not supported on this platform (Windows/Linux)');
      _setStatus(BtStatus.idle);
      return;
    }
    _adapterSub?.cancel();
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      AppLogger.bt('Adapter state: $state');
      if (state == BluetoothAdapterState.off) {
        _setStatus(BtStatus.adapterOff);
        _cleanupScan();
      } else if (state == BluetoothAdapterState.on) {
        if (_status == BtStatus.adapterOff) {
          _setStatus(BtStatus.idle);
        }
      }
    });
  }

  void dispose() {
    _adapterSub?.cancel();
    _scanSub?.cancel();
    _connectionSub?.cancel();
    _reconnectTimer?.cancel();
    _statusController.close();
    _scanResultsController.close();
    _logController.close();
  }

  // ─── Permissions ──────────────────────────────────────────────────────────

  /// Request all required Bluetooth permissions.
  /// Returns true if all granted.
  Future<bool> requestPermissions() async {
    if (!_isBleSupported) return true; // No permissions needed on Windows
    _log('Requesting Bluetooth permissions...');

    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    final results = await permissions.request();

    final denied = results.entries
        .where((e) => !e.value.isGranted)
        .map((e) => e.key.toString())
        .toList();

    if (denied.isNotEmpty) {
      _log('Permissions denied: ${denied.join(', ')}');
      AppLogger.bt('Permissions denied: $denied');
      _setStatus(BtStatus.permissionDenied);
      return false;
    }

    _log('All BT permissions granted ✓');
    AppLogger.bt('Permissions granted');
    return true;
  }

  /// Check (without requesting) if BT scan permission is granted
  Future<bool> hasPermissions() async {
    if (!_isBleSupported) return true;
    return await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted;
  }

  // ─── Scan ─────────────────────────────────────────────────────────────────

  /// Start BLE scan. Requests permissions first if needed.
  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    if (!_isBleSupported) {
      _log('Bluetooth scanning not supported on this platform');
      return;
    }
    if (_status == BtStatus.adapterOff) {
      _log('Cannot scan — Bluetooth is off');
      return;
    }

    if (_status == BtStatus.scanning) {
      _log('Already scanning');
      return;
    }

    final granted = await requestPermissions();
    if (!granted) return;

    _scanResults.clear();
    _scanResultsController.add([]);
    _setStatus(BtStatus.scanning);
    _log('Starting BLE scan (${timeout.inSeconds}s)...');

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      bool changed = false;
      for (final r in results) {
        final id = r.device.remoteId.str;
        // Show all devices, even unnamed ones.


        final existing = _scanResults[id];
        if (existing == null || existing.rssi != r.rssi) {
          _scanResults[id] = r;
          changed = true;
        }
      }
      if (changed) {
        _scanResultsController.add(scanResults);
        _log('Found ${_scanResults.length} device(s): ${_scanResults.values.map((r) => r.device.platformName).join(', ')}');
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: false,
      );
    } catch (e) {
      AppLogger.e('Scan start failed', error: e);
      _log('Scan error: $e');
    }

    // Scan complete
    await Future.delayed(timeout + const Duration(milliseconds: 500));
    await stopScan();
    _log('Scan complete — ${_scanResults.length} device(s) found');
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _cleanupScan();
    if (_status == BtStatus.scanning) _setStatus(BtStatus.idle);
  }

  void _cleanupScan() {
    _scanSub?.cancel();
    _scanSub = null;
  }

  // ─── Connection ───────────────────────────────────────────────────────────

  Future<bool> connect(BluetoothDevice device) async {
    if (!_isBleSupported) {
      _log('Bluetooth not supported on this platform');
      return false;
    }
    // Guard: prevent duplicate connections
    if (_connectedDevice?.remoteId == device.remoteId &&
        _status == BtStatus.connected) {
      _log('Already connected to ${device.platformName}');
      return true;
    }

    // Stop scan if running
    await stopScan();

    _setStatus(BtStatus.connecting);
    _shouldReconnect = true;
    _reconnectAttempt = 0;
    _log('Connecting to ${device.platformName} (${device.remoteId})...');

    try {
      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 20),
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        await device.requestMtu(512);
        AppLogger.bt('MTU negotiated');
      }

      _connectedDevice = device;
      _setStatus(BtStatus.connected);
      _log('Connected to ${device.platformName} ✓');

      _setupDisconnectWatch(device);
      return true;
    } catch (e) {
      AppLogger.e('Connection failed to ${device.platformName}', error: e);
      _log('Connection failed: $e');
      _setStatus(BtStatus.error);
      _connectedDevice = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _connectionSub?.cancel();

    final device = _connectedDevice;
    _connectedDevice = null;

    try {
      await device?.disconnect();
    } catch (_) {}

    _setStatus(BtStatus.idle);
    _log('Disconnected');
    AppLogger.bt('Manually disconnected');
  }

  // ─── Auto-Reconnect ───────────────────────────────────────────────────────

  void _setupDisconnectWatch(BluetoothDevice device) {
    _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((state) {
      AppLogger.bt('Connection state → $state');
      if (state == BluetoothConnectionState.disconnected) {
        _connectedDevice = null;
        if (_shouldReconnect && _reconnectAttempt < _maxReconnectAttempts) {
          _scheduleReconnect(device);
        } else {
          _setStatus(BtStatus.idle);
          _log('Disconnected — no more reconnect attempts');
        }
      }
    });
  }

  void _scheduleReconnect(BluetoothDevice device) {
    _reconnectAttempt++;
    final delay = Duration(seconds: 3 * _reconnectAttempt); // back-off
    _setStatus(BtStatus.reconnecting);
    _log('Unexpected disconnect — reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempt/$_maxReconnectAttempts)');
    AppLogger.bt('Scheduling reconnect in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (!_shouldReconnect) return;
      _log('Reconnect attempt $_reconnectAttempt...');
      final success = await connect(device);
      if (!success && _reconnectAttempt < _maxReconnectAttempts) {
        _scheduleReconnect(device);
      } else if (!success) {
        _setStatus(BtStatus.error);
        _log('All reconnect attempts failed');
      }
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _setStatus(BtStatus s) {
    _status = s;
    _statusController.add(s);
    AppLogger.bt('Status → $s');
  }

  void _log(String message) {
    _logController.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $message');
  }
}
