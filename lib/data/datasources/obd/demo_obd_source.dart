import 'dart:async';
import 'dart:math';
import '../../../data/models/dtc_code.dart';
import '../../../data/models/live_data.dart';
import '../../../data/models/vehicle_info.dart';
import '../local/dtc_database.dart';
import 'obd_data_source.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Simulated OBD data source for testing without hardware
class DemoObdSource implements ObdDataSource {
  final _random = Random();
  Timer? _liveDataTimer;
  bool _isConnected = false;

  // Base values for realistic simulation
  double _baseRpm = 780;
  double _baseSpeed = 0;
  double _baseCoolantTemp = 85;

  @override
  bool get isConnected => _isConnected;

  /// Simulate connection delay
  @override
  Future<bool> connect([BluetoothDevice? device]) async {
    await Future.delayed(const Duration(seconds: 2));
    _isConnected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    _liveDataTimer?.cancel();
    _isConnected = false;
  }

  /// Get simulated vehicle info
  @override
  VehicleInfo getVehicleInfo() {
    return const VehicleInfo(
      vin: 'WVWZZZ3CZWE123456',
      make: 'Volkswagen',
      model: 'Passat',
      year: 2019,
      engineType: '1.4 TSI',
      fuelType: 'Gasoline',
      protocol: 'CAN (ISO 15765-4)',
    );
  }

  /// Stream of live data (simulated)
  @override
  Stream<LiveData> getLiveDataStream() {
    return Stream.periodic(const Duration(milliseconds: 500), (_) {
      return _generateLiveData();
    });
  }

  LiveData _generateLiveData() {
    // Simulate realistic fluctuations
    _baseRpm += (_random.nextDouble() - 0.5) * 30;
    _baseRpm = _baseRpm.clamp(650, 900);

    _baseSpeed += (_random.nextDouble() - 0.5) * 2;
    _baseSpeed = _baseSpeed.clamp(0, 5);

    _baseCoolantTemp += (_random.nextDouble() - 0.5) * 0.3;
    _baseCoolantTemp = _baseCoolantTemp.clamp(80, 95);

    return LiveData(
      rpm: _baseRpm,
      speed: _baseSpeed,
      engineLoad: 15 + _random.nextDouble() * 10,
      coolantTemp: _baseCoolantTemp,
      intakeAirTemp: 35 + _random.nextDouble() * 5,
      mafAirFlow: 3.5 + _random.nextDouble() * 2,
      mapPressure: 30 + _random.nextDouble() * 5,
      shortTermFuelTrim: 2.5 + (_random.nextDouble() - 0.5) * 5,
      longTermFuelTrim: 8.5 + (_random.nextDouble() - 0.5) * 3,
      o2Voltage: 0.35 + _random.nextDouble() * 0.5,
      throttlePosition: 12 + _random.nextDouble() * 5,
      fuelPressure: 350 + _random.nextDouble() * 30,
      batteryVoltage: 13.8 + (_random.nextDouble() - 0.5) * 0.5,
      runtimeSeconds: DateTime.now().difference(DateTime.now().subtract(
        const Duration(minutes: 15),
      )).inSeconds,
      timestamp: DateTime.now(),
    );
  }

  /// Get simulated DTC codes — demonstrates real diagnoses
  @override
  Future<List<DtcCode>> readDtcCodes() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      DtcCode(
        code: 'P0171',
        description: DtcDatabase.getDescription('P0171', russian: false),
        descriptionRu: DtcDatabase.getDescription('P0171', russian: true),
        severity: DtcSeverity.medium,
        status: DtcStatus.confirmed,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        freezeFrame: FreezeFrame(
          dtcCode: 'P0171',
          rpm: 2200,
          speed: 60,
          engineLoad: 45,
          coolantTemp: 90,
          stft: 22.5,
          ltft: 15.3,
          maf: 8.2,
          map: 42,
          o2Voltage: 0.15,
          capturedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ),
      DtcCode(
        code: 'P0300',
        description: DtcDatabase.getDescription('P0300', russian: false),
        descriptionRu: DtcDatabase.getDescription('P0300', russian: true),
        severity: DtcSeverity.high,
        status: DtcStatus.confirmed,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        freezeFrame: FreezeFrame(
          dtcCode: 'P0300',
          rpm: 1500,
          speed: 45,
          engineLoad: 55,
          coolantTemp: 88,
          stft: 5.1,
          ltft: 3.2,
          maf: 12.5,
          map: 55,
          o2Voltage: 0.68,
          capturedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ),
      DtcCode(
        code: 'P0420',
        description: DtcDatabase.getDescription('P0420', russian: false),
        descriptionRu: DtcDatabase.getDescription('P0420', russian: true),
        severity: DtcSeverity.medium,
        status: DtcStatus.pending,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Simulate clearing DTCs
  @override
  Future<bool> clearDtcCodes() async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  /// Get simulated battery voltage
  double getBatteryVoltage() {
    return 13.8 + (_random.nextDouble() - 0.5) * 0.5;
  }
}
