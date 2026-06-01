import 'package:equatable/equatable.dart';

/// Represents a Diagnostic Trouble Code read from the vehicle
class DtcCode extends Equatable {
  final String code;           // e.g., "P0171"
  final String description;    // Short description
  final String descriptionRu;  // Russian description
  final DtcSeverity severity;
  final DtcStatus status;      // Confirmed, Pending
  final DateTime timestamp;
  final FreezeFrame? freezeFrame;

  const DtcCode({
    required this.code,
    required this.description,
    this.descriptionRu = '',
    required this.severity,
    this.status = DtcStatus.confirmed,
    required this.timestamp,
    this.freezeFrame,
  });

  /// Get DTC category from first character
  String get category {
    switch (code[0]) {
      case 'P': return 'Powertrain';
      case 'C': return 'Chassis';
      case 'B': return 'Body';
      case 'U': return 'Network';
      default: return 'Unknown';
    }
  }

  String get categoryRu {
    switch (code[0]) {
      case 'P': return 'Двигатель/Трансмиссия';
      case 'C': return 'Шасси';
      case 'B': return 'Кузов';
      case 'U': return 'Сеть';
      default: return 'Неизвестно';
    }
  }

  bool get isCritical => severity == DtcSeverity.critical || severity == DtcSeverity.high;

  @override
  List<Object?> get props => [code, status, timestamp];
}

enum DtcSeverity {
  low,
  medium,
  high,
  critical,
}

enum DtcStatus {
  confirmed,
  pending,
  historical,
}

/// Freeze frame data captured when DTC was set
class FreezeFrame extends Equatable {
  final String dtcCode;
  final double? rpm;
  final double? speed;
  final double? engineLoad;
  final double? coolantTemp;
  final double? stft;
  final double? ltft;
  final double? maf;
  final double? map;
  final double? o2Voltage;
  final DateTime capturedAt;

  const FreezeFrame({
    required this.dtcCode,
    this.rpm,
    this.speed,
    this.engineLoad,
    this.coolantTemp,
    this.stft,
    this.ltft,
    this.maf,
    this.map,
    this.o2Voltage,
    required this.capturedAt,
  });

  Map<String, double?> toMap() => {
    'RPM': rpm,
    'Speed': speed,
    'Engine Load': engineLoad,
    'Coolant Temp': coolantTemp,
    'STFT': stft,
    'LTFT': ltft,
    'MAF': maf,
    'MAP': map,
    'O2 Voltage': o2Voltage,
  };

  @override
  List<Object?> get props => [dtcCode, capturedAt];
}
