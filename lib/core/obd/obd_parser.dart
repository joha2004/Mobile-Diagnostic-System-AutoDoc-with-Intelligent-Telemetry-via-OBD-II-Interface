import '../../data/models/dtc_code.dart';
import '../../data/datasources/local/dtc_database.dart';
import '../logging/app_logger.dart';

/// Stateless OBD-II response parser
/// Handles all PID responses, DTC codes, Freeze Frame, VIN
class OBDParser {
  // ─── Mode 01 PID Parsers ──────────────────────────────────────────────────

  /// PID 0C: Engine RPM → ((A*256)+B)/4
  static double? parseRpm(String raw) {
    final hex = _extract(raw, '410C', 4);
    if (hex == null) return null;
    final val = int.parse(hex, radix: 16);
    return val / 4.0;
  }

  /// PID 0D: Vehicle Speed → A km/h
  static double? parseSpeed(String raw) {
    final hex = _extract(raw, '410D', 2);
    if (hex == null) return null;
    return int.parse(hex, radix: 16).toDouble();
  }

  /// PID 05: Coolant Temperature → A - 40 °C
  static double? parseCoolantTemp(String raw) {
    final hex = _extract(raw, '4105', 2);
    if (hex == null) return null;
    return int.parse(hex, radix: 16) - 40.0;
  }

  /// PID 04: Engine Load → A * 100 / 255 %
  static double? parseEngineLoad(String raw) {
    final hex = _extract(raw, '4104', 2);
    if (hex == null) return null;
    return int.parse(hex, radix: 16) * 100 / 255.0;
  }

  /// PID 0F: Intake Air Temperature → A - 40 °C
  static double? parseIntakeAirTemp(String raw) {
    final hex = _extract(raw, '410F', 2);
    if (hex == null) return null;
    return int.parse(hex, radix: 16) - 40.0;
  }

  /// PID 10: MAF Air Flow Rate → ((A*256)+B) / 100 g/s
  static double? parseMaf(String raw) {
    final hex = _extract(raw, '4110', 4);
    if (hex == null) return null;
    final val = int.parse(hex, radix: 16);
    return val / 100.0;
  }

  /// PID 0B: Intake Manifold Absolute Pressure → A kPa
  static double? parseMap(String raw) {
    final hex = _extract(raw, '410B', 2);
    if (hex == null) return null;
    return int.parse(hex, radix: 16).toDouble();
  }

  /// PID 06: Short-Term Fuel Trim Bank 1 → (A-128)*100/128 %
  static double? parseStft(String raw) {
    final hex = _extract(raw, '4106', 2);
    if (hex == null) return null;
    return (int.parse(hex, radix: 16) - 128) * 100 / 128.0;
  }

  /// PID 07: Long-Term Fuel Trim Bank 1 → (A-128)*100/128 %
  static double? parseLtft(String raw) {
    final hex = _extract(raw, '4107', 2);
    if (hex == null) return null;
    return (int.parse(hex, radix: 16) - 128) * 100 / 128.0;
  }

  /// PID 14: O2 Sensor Bank 1, Sensor 1 Voltage → A/200 V
  static double? parseO2Voltage(String raw) {
    final hex = _extract(raw, '4114', 2);
    if (hex == null) return null;
    return int.parse(hex, radix: 16) / 200.0;
  }

  /// PID 11: Throttle Position → A * 100 / 255 %
  static double? parseThrottlePos(String raw) {
    final hex = _extract(raw, '4111', 2);
    if (hex == null) return null;
    return int.parse(hex, radix: 16) * 100 / 255.0;
  }

  /// PID 1F: Engine Run Time → (A*256)+B seconds
  static int? parseRuntime(String raw) {
    final hex = _extract(raw, '411F', 4);
    if (hex == null) return null;
    return int.parse(hex, radix: 16);
  }

  /// PID 42: Control Module Voltage → ((A*256)+B)/1000 V
  static double? parseBatteryVoltage(String raw) {
    final hex = _extract(raw, '4142', 4);
    if (hex == null) return null;
    return int.parse(hex, radix: 16) / 1000.0;
  }

  /// PID 0A: Fuel Pressure → A*3 kPa
  static double? parseFuelPressure(String raw) {
    final hex = _extract(raw, '410A', 2);
    if (hex == null) return null;
    return int.parse(hex, radix: 16) * 3.0;
  }

  // ─── Mode 03: DTC Code Parser ─────────────────────────────────────────────

  /// Parses Mode 03 response → list of DTC codes
  /// Response format: "43 01 23 00 00 00 00" or multiline
  static List<DtcCode> parseDtcCodes(String raw) {
    final codes = <DtcCode>[];
    if (raw.isEmpty || raw.contains('NO DATA') || raw.contains('UNABLE')) return codes;

    // Remove all whitespace and look for 43xx pairs
    final clean = raw.toUpperCase().replaceAll(RegExp(r'\s+'), '');

    // Find all "43" prefixes and extract byte pairs after them
    int idx = 0;
    while (idx < clean.length) {
      final pos = clean.indexOf('43', idx);
      if (pos == -1) break;
      idx = pos + 2;

      // Extract up to 6 byte pairs (3 DTCs per frame per OBD spec)
      for (int i = 0; i < 6; i++) {
        final start = idx + i * 4;
        if (start + 4 > clean.length) break;
        final pair = clean.substring(start, start + 4);
        if (pair == '0000') continue; // padding

        final code = _decodeDtcBytes(pair);
        if (code != null) {
          codes.add(DtcCode(
            code: code,
            description: DtcDatabase.getDescription(code, russian: false),
            descriptionRu: DtcDatabase.getDescription(code, russian: true),
            severity: _mapSeverity(DtcDatabase.getSeverity(code)),
            status: DtcStatus.confirmed,
            timestamp: DateTime.now(),
          ));
        }
      }
      break; // Only process first 43 block for MVP; extend for multi-frame later
    }

    AppLogger.obd('Parsed ${codes.length} DTC codes: ${codes.map((c) => c.code).join(', ')}');
    return codes;
  }

  /// Parse Mode 02 (Freeze Frame) for a specific DTC
  static Map<String, double?> parseFreezeFrameRaw(String raw) {
    return {
      'rpm': parseRpm(raw),
      'speed': parseSpeed(raw),
      'engineLoad': parseEngineLoad(raw),
      'coolantTemp': parseCoolantTemp(raw),
      'stft': parseStft(raw),
      'ltft': parseLtft(raw),
      'maf': parseMaf(raw),
      'map': parseMap(raw),
      'o2Voltage': parseO2Voltage(raw),
    };
  }

  /// Parse VIN from Mode 09 PID 02 response
  static String? parseVin(String raw) {
    if (raw.isEmpty || raw.contains('NO DATA')) return null;
    try {
      // Remove "49 02 0X " headers and spaces
      final clean = raw.toUpperCase().replaceAll(RegExp(r'49\s*02\s*0.\s*'), '').replaceAll(' ', '');
      // Convert hex pairs to ASCII
      final sb = StringBuffer();
      for (int i = 0; i < clean.length - 1; i += 2) {
        final byte = int.tryParse(clean.substring(i, i + 2), radix: 16);
        if (byte != null && byte >= 0x20 && byte <= 0x7E) {
          sb.writeCharCode(byte);
        }
      }
      final vin = sb.toString().trim();
      return vin.length >= 17 ? vin.substring(0, 17) : null;
    } catch (e) {
      return null;
    }
  }

  /// Check if response indicates an error
  static bool isError(String raw) {
    final upper = raw.toUpperCase();
    return upper.isEmpty ||
        upper.contains('NO DATA') ||
        upper.contains('ERROR') ||
        upper.contains('UNABLE TO CONNECT') ||
        upper.contains('BUS INIT') ||
        upper.contains('STOPPED') ||
        upper.contains('?');
  }

  // ─── Internal Helpers ─────────────────────────────────────────────────────

  static String? _extract(String raw, String prefix, int hexLen) {
    if (isError(raw)) return null;
    final clean = raw.toUpperCase().replaceAll(RegExp(r'\s+'), '');
    final pat = RegExp('$prefix([0-9A-F]{$hexLen})');
    final match = pat.firstMatch(clean);
    return match?.group(1);
  }

  /// Decode 4-hex-char DTC byte pair → DTC string (e.g. "0171" → "P0171")
  static String? _decodeDtcBytes(String hex4) {
    if (hex4.length != 4) return null;
    try {
      final high = int.parse(hex4.substring(0, 2), radix: 16);
      final low = int.parse(hex4.substring(2, 4), radix: 16);
      final prefix = ['P', 'C', 'B', 'U'][(high & 0xC0) >> 6];
      final digit1 = (high & 0x30) >> 4;
      final digit2 = high & 0x0F;
      final lowStr = low.toRadixString(16).toUpperCase().padLeft(2, '0');
      return '$prefix$digit1$digit2$lowStr';
    } catch (_) {
      return null;
    }
  }

  static DtcSeverity _mapSeverity(String s) {
    switch (s) {
      case 'critical': return DtcSeverity.critical;
      case 'high':     return DtcSeverity.high;
      case 'medium':   return DtcSeverity.medium;
      default:         return DtcSeverity.low;
    }
  }
}

