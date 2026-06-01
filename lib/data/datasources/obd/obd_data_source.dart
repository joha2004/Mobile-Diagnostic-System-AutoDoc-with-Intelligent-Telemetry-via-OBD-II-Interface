import '../../../data/models/dtc_code.dart';
import '../../../data/models/live_data.dart';
import '../../../data/models/vehicle_info.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class ObdDataSource {
  bool get isConnected;

  /// Connect to device. In demo mode device is null.
  Future<bool> connect([BluetoothDevice? device]);

  /// Disconnect and release all resources
  Future<void> disconnect();

  VehicleInfo getVehicleInfo();

  Stream<LiveData> getLiveDataStream();

  Future<List<DtcCode>> readDtcCodes();

  Future<bool> clearDtcCodes();
}
