import 'package:equatable/equatable.dart';

/// Real-time data from vehicle sensors
class LiveData extends Equatable {
  final double rpm;
  final double speed;
  final double engineLoad;
  final double coolantTemp;
  final double intakeAirTemp;
  final double mafAirFlow;
  final double mapPressure;
  final double shortTermFuelTrim;
  final double longTermFuelTrim;
  final double o2Voltage;
  final double throttlePosition;
  final double fuelPressure;
  final double batteryVoltage;
  final int runtimeSeconds;
  final DateTime timestamp;

  const LiveData({
    this.rpm = 0,
    this.speed = 0,
    this.engineLoad = 0,
    this.coolantTemp = 0,
    this.intakeAirTemp = 0,
    this.mafAirFlow = 0,
    this.mapPressure = 0,
    this.shortTermFuelTrim = 0,
    this.longTermFuelTrim = 0,
    this.o2Voltage = 0,
    this.throttlePosition = 0,
    this.fuelPressure = 0,
    this.batteryVoltage = 0,
    this.runtimeSeconds = 0,
    required this.timestamp,
  });

  LiveData copyWith({
    double? rpm,
    double? speed,
    double? engineLoad,
    double? coolantTemp,
    double? intakeAirTemp,
    double? mafAirFlow,
    double? mapPressure,
    double? shortTermFuelTrim,
    double? longTermFuelTrim,
    double? o2Voltage,
    double? throttlePosition,
    double? fuelPressure,
    double? batteryVoltage,
    int? runtimeSeconds,
    DateTime? timestamp,
  }) {
    return LiveData(
      rpm: rpm ?? this.rpm,
      speed: speed ?? this.speed,
      engineLoad: engineLoad ?? this.engineLoad,
      coolantTemp: coolantTemp ?? this.coolantTemp,
      intakeAirTemp: intakeAirTemp ?? this.intakeAirTemp,
      mafAirFlow: mafAirFlow ?? this.mafAirFlow,
      mapPressure: mapPressure ?? this.mapPressure,
      shortTermFuelTrim: shortTermFuelTrim ?? this.shortTermFuelTrim,
      longTermFuelTrim: longTermFuelTrim ?? this.longTermFuelTrim,
      o2Voltage: o2Voltage ?? this.o2Voltage,
      throttlePosition: throttlePosition ?? this.throttlePosition,
      fuelPressure: fuelPressure ?? this.fuelPressure,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      runtimeSeconds: runtimeSeconds ?? this.runtimeSeconds,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Check if coolant temperature is overheating
  bool get isOverheating => coolantTemp > 105;

  /// Check if engine is running
  bool get isEngineRunning => rpm > 0;

  /// Check if fuel trims are abnormal
  bool get hasFuelTrimIssue =>
      shortTermFuelTrim.abs() > 25 || longTermFuelTrim.abs() > 20;

  Map<String, dynamic> toJson() => {
    'rpm': rpm,
    'speed': speed,
    'engineLoad': engineLoad,
    'coolantTemp': coolantTemp,
    'intakeAirTemp': intakeAirTemp,
    'mafAirFlow': mafAirFlow,
    'mapPressure': mapPressure,
    'stft': shortTermFuelTrim,
    'ltft': longTermFuelTrim,
    'o2Voltage': o2Voltage,
    'throttlePosition': throttlePosition,
    'fuelPressure': fuelPressure,
    'batteryVoltage': batteryVoltage,
    'runtimeSeconds': runtimeSeconds,
    'timestamp': timestamp.toIso8601String(),
  };

  factory LiveData.fromJson(Map<String, dynamic> json) => LiveData(
    rpm: (json['rpm'] as num?)?.toDouble() ?? 0,
    speed: (json['speed'] as num?)?.toDouble() ?? 0,
    engineLoad: (json['engineLoad'] as num?)?.toDouble() ?? 0,
    coolantTemp: (json['coolantTemp'] as num?)?.toDouble() ?? 0,
    intakeAirTemp: (json['intakeAirTemp'] as num?)?.toDouble() ?? 0,
    mafAirFlow: (json['mafAirFlow'] as num?)?.toDouble() ?? 0,
    mapPressure: (json['mapPressure'] as num?)?.toDouble() ?? 0,
    shortTermFuelTrim: (json['stft'] as num?)?.toDouble() ?? 0,
    longTermFuelTrim: (json['ltft'] as num?)?.toDouble() ?? 0,
    o2Voltage: (json['o2Voltage'] as num?)?.toDouble() ?? 0,
    throttlePosition: (json['throttlePosition'] as num?)?.toDouble() ?? 0,
    fuelPressure: (json['fuelPressure'] as num?)?.toDouble() ?? 0,
    batteryVoltage: (json['batteryVoltage'] as num?)?.toDouble() ?? 0,
    runtimeSeconds: (json['runtimeSeconds'] as num?)?.toInt() ?? 0,
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : DateTime.now(),
  );

  @override
  List<Object?> get props => [
    rpm, speed, engineLoad, coolantTemp, intakeAirTemp,
    mafAirFlow, mapPressure, shortTermFuelTrim, longTermFuelTrim,
    o2Voltage, throttlePosition, fuelPressure, batteryVoltage,
    runtimeSeconds, timestamp,
  ];
}
