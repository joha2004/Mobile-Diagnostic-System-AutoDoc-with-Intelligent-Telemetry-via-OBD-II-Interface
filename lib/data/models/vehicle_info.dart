import 'package:equatable/equatable.dart';

/// Vehicle identification information
class VehicleInfo extends Equatable {
  final String? vin;
  final String make;
  final String model;
  final int? year;
  final String? engineType;
  final String? fuelType;
  final String? protocol;

  const VehicleInfo({
    this.vin,
    this.make = 'Unknown',
    this.model = 'Unknown',
    this.year,
    this.engineType,
    this.fuelType,
    this.protocol,
  });

  String get displayName {
    if (make == 'Unknown') return vin ?? 'Автомобиль';
    return '$make $model ${year ?? ''}';
  }

  bool get isIdentified => vin != null || make != 'Unknown';

  Map<String, dynamic> toJson() => {
    'vin': vin,
    'make': make,
    'model': model,
    'year': year,
    'engineType': engineType,
    'fuelType': fuelType,
    'protocol': protocol,
  };

  factory VehicleInfo.fromJson(Map<String, dynamic> json) => VehicleInfo(
    vin: json['vin'] as String?,
    make: json['make'] as String? ?? 'Unknown',
    model: json['model'] as String? ?? 'Unknown',
    year: json['year'] as int?,
    engineType: json['engineType'] as String?,
    fuelType: json['fuelType'] as String?,
    protocol: json['protocol'] as String?,
  );

  @override
  List<Object?> get props => [vin, make, model, year];
}
