import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/bluetooth/bluetooth_manager.dart';
import '../../core/logging/app_logger.dart';

// ─── Bluetooth Manager Provider ──────────────────────────────────────────────

final bluetoothManagerProvider = Provider<BluetoothManager>((ref) {
  final manager = BluetoothManager.instance;
  manager.initialize();
  ref.onDispose(() => manager.dispose());
  return manager;
});

// ─── Adapter State ───────────────────────────────────────────────────────────

final bluetoothAdapterStateProvider = StreamProvider<BluetoothAdapterState>((ref) {
  return FlutterBluePlus.adapterState;
});

// ─── BT Status ───────────────────────────────────────────────────────────────

final btStatusProvider = StateNotifierProvider<BtStatusNotifier, BtStatus>((ref) {
  final manager = ref.watch(bluetoothManagerProvider);
  return BtStatusNotifier(manager);
});

class BtStatusNotifier extends StateNotifier<BtStatus> {
  final BluetoothManager _manager;
  StreamSubscription? _sub;

  BtStatusNotifier(this._manager) : super(_manager.status) {
    _sub = _manager.statusStream.listen((s) {
      state = s;
      AppLogger.bt('Provider status → $s');
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ─── Scan Results ─────────────────────────────────────────────────────────────

final btScanResultsProvider =
    StateNotifierProvider<BtScanResultsNotifier, List<ScanResult>>((ref) {
  final manager = ref.watch(bluetoothManagerProvider);
  return BtScanResultsNotifier(manager);
});

class BtScanResultsNotifier extends StateNotifier<List<ScanResult>> {
  final BluetoothManager _manager;
  StreamSubscription? _sub;

  BtScanResultsNotifier(this._manager) : super([]) {
    _sub = _manager.scanResultsStream.listen((results) {
      state = results;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ─── BT Log Stream ───────────────────────────────────────────────────────────

final btLogProvider = StreamProvider<String>((ref) {
  final manager = ref.watch(bluetoothManagerProvider);
  return manager.logStream;
});

// ─── Scan Action ─────────────────────────────────────────────────────────────

final btScanActionProvider = Provider<Future<void> Function()>((ref) {
  final manager = ref.watch(bluetoothManagerProvider);
  return () => manager.startScan();
});
