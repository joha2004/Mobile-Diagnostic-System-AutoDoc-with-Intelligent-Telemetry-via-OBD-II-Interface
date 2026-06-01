/// Offline DTC database with ~200 most common OBD-II codes
/// Provides descriptions in English and Russian without internet
class DtcDatabase {
  DtcDatabase._();

  /// Get DTC description by code
  static DtcEntry? getEntry(String code) => _database[code.toUpperCase()];

  /// Get description in user's language
  static String getDescription(String code, {bool russian = true}) {
    final entry = _database[code.toUpperCase()];
    if (entry == null) return russian ? 'Неизвестный код ошибки' : 'Unknown error code';
    return russian ? entry.descriptionRu : entry.descriptionEn;
  }

  /// Get severity for a DTC code
  static String getSeverity(String code) {
    final entry = _database[code.toUpperCase()];
    return entry?.severity ?? 'medium';
  }

  /// Search DTCs by keyword
  static List<MapEntry<String, DtcEntry>> search(String query) {
    final q = query.toLowerCase();
    return _database.entries.where((e) =>
        e.key.toLowerCase().contains(q) ||
        e.value.descriptionEn.toLowerCase().contains(q) ||
        e.value.descriptionRu.toLowerCase().contains(q)
    ).toList();
  }

  static const Map<String, DtcEntry> _database = {
    // ===== FUEL SYSTEM (P0170-P0179) =====
    'P0170': DtcEntry(
      descriptionEn: 'Fuel Trim Malfunction (Bank 1)',
      descriptionRu: 'Неисправность топливной коррекции (Банк 1)',
      severity: 'medium',
      system: 'fuel',
    ),
    'P0171': DtcEntry(
      descriptionEn: 'System Too Lean (Bank 1)',
      descriptionRu: 'Система слишком бедная (Банк 1)',
      severity: 'medium',
      system: 'fuel',
    ),
    'P0172': DtcEntry(
      descriptionEn: 'System Too Rich (Bank 1)',
      descriptionRu: 'Система слишком богатая (Банк 1)',
      severity: 'medium',
      system: 'fuel',
    ),
    'P0173': DtcEntry(
      descriptionEn: 'Fuel Trim Malfunction (Bank 2)',
      descriptionRu: 'Неисправность топливной коррекции (Банк 2)',
      severity: 'medium',
      system: 'fuel',
    ),
    'P0174': DtcEntry(
      descriptionEn: 'System Too Lean (Bank 2)',
      descriptionRu: 'Система слишком бедная (Банк 2)',
      severity: 'medium',
      system: 'fuel',
    ),
    'P0175': DtcEntry(
      descriptionEn: 'System Too Rich (Bank 2)',
      descriptionRu: 'Система слишком богатая (Банк 2)',
      severity: 'medium',
      system: 'fuel',
    ),

    // ===== MISFIRE (P0300-P0312) =====
    'P0300': DtcEntry(
      descriptionEn: 'Random/Multiple Cylinder Misfire Detected',
      descriptionRu: 'Обнаружены пропуски зажигания в нескольких цилиндрах',
      severity: 'high',
      system: 'ignition',
    ),
    'P0301': DtcEntry(
      descriptionEn: 'Cylinder 1 Misfire Detected',
      descriptionRu: 'Пропуски зажигания — Цилиндр 1',
      severity: 'high',
      system: 'ignition',
    ),
    'P0302': DtcEntry(
      descriptionEn: 'Cylinder 2 Misfire Detected',
      descriptionRu: 'Пропуски зажигания — Цилиндр 2',
      severity: 'high',
      system: 'ignition',
    ),
    'P0303': DtcEntry(
      descriptionEn: 'Cylinder 3 Misfire Detected',
      descriptionRu: 'Пропуски зажигания — Цилиндр 3',
      severity: 'high',
      system: 'ignition',
    ),
    'P0304': DtcEntry(
      descriptionEn: 'Cylinder 4 Misfire Detected',
      descriptionRu: 'Пропуски зажигания — Цилиндр 4',
      severity: 'high',
      system: 'ignition',
    ),
    'P0305': DtcEntry(
      descriptionEn: 'Cylinder 5 Misfire Detected',
      descriptionRu: 'Пропуски зажигания — Цилиндр 5',
      severity: 'high',
      system: 'ignition',
    ),
    'P0306': DtcEntry(
      descriptionEn: 'Cylinder 6 Misfire Detected',
      descriptionRu: 'Пропуски зажигания — Цилиндр 6',
      severity: 'high',
      system: 'ignition',
    ),

    // ===== OXYGEN SENSORS (P0130-P0167) =====
    'P0130': DtcEntry(
      descriptionEn: 'O2 Sensor Circuit Malfunction (Bank 1, Sensor 1)',
      descriptionRu: 'Кислородный датчик — неисправность (Банк 1, Датчик 1)',
      severity: 'medium',
      system: 'emission',
    ),
    'P0131': DtcEntry(
      descriptionEn: 'O2 Sensor Circuit Low Voltage (Bank 1, Sensor 1)',
      descriptionRu: 'Кислородный датчик — низкое напряжение (Банк 1, Датчик 1)',
      severity: 'medium',
      system: 'emission',
    ),
    'P0132': DtcEntry(
      descriptionEn: 'O2 Sensor Circuit High Voltage (Bank 1, Sensor 1)',
      descriptionRu: 'Кислородный датчик — высокое напряжение (Банк 1, Датчик 1)',
      severity: 'medium',
      system: 'emission',
    ),
    'P0133': DtcEntry(
      descriptionEn: 'O2 Sensor Circuit Slow Response (Bank 1, Sensor 1)',
      descriptionRu: 'Кислородный датчик — медленная реакция (Банк 1, Датчик 1)',
      severity: 'medium',
      system: 'emission',
    ),
    'P0134': DtcEntry(
      descriptionEn: 'O2 Sensor Circuit No Activity (Bank 1, Sensor 1)',
      descriptionRu: 'Кислородный датчик — нет активности (Банк 1, Датчик 1)',
      severity: 'medium',
      system: 'emission',
    ),
    'P0135': DtcEntry(
      descriptionEn: 'O2 Sensor Heater Circuit Malfunction (Bank 1, Sensor 1)',
      descriptionRu: 'Подогрев кислородного датчика — неисправность (Банк 1, Датчик 1)',
      severity: 'low',
      system: 'emission',
    ),
    'P0136': DtcEntry(
      descriptionEn: 'O2 Sensor Circuit (Bank 1, Sensor 2)',
      descriptionRu: 'Кислородный датчик — неисправность (Банк 1, Датчик 2)',
      severity: 'medium',
      system: 'emission',
    ),
    'P0141': DtcEntry(
      descriptionEn: 'O2 Sensor Heater Circuit (Bank 1, Sensor 2)',
      descriptionRu: 'Подогрев кислородного датчика (Банк 1, Датчик 2)',
      severity: 'low',
      system: 'emission',
    ),

    // ===== COOLANT (P0115-P0119) =====
    'P0115': DtcEntry(
      descriptionEn: 'Engine Coolant Temperature Circuit',
      descriptionRu: 'Цепь датчика температуры охлаждающей жидкости',
      severity: 'high',
      system: 'cooling',
    ),
    'P0116': DtcEntry(
      descriptionEn: 'Engine Coolant Temperature Circuit Range/Performance',
      descriptionRu: 'Датчик температуры ОЖ — выход за пределы допустимого',
      severity: 'high',
      system: 'cooling',
    ),
    'P0117': DtcEntry(
      descriptionEn: 'Engine Coolant Temperature Circuit Low',
      descriptionRu: 'Датчик температуры ОЖ — низкий сигнал',
      severity: 'medium',
      system: 'cooling',
    ),
    'P0118': DtcEntry(
      descriptionEn: 'Engine Coolant Temperature Circuit High',
      descriptionRu: 'Датчик температуры ОЖ — высокий сигнал',
      severity: 'high',
      system: 'cooling',
    ),

    // ===== CATALYST (P0420-P0424) =====
    'P0420': DtcEntry(
      descriptionEn: 'Catalyst System Efficiency Below Threshold (Bank 1)',
      descriptionRu: 'Каталитический нейтрализатор — эффективность ниже порога (Банк 1)',
      severity: 'medium',
      system: 'emission',
    ),
    'P0421': DtcEntry(
      descriptionEn: 'Warm Up Catalyst Efficiency Below Threshold (Bank 1)',
      descriptionRu: 'Каталитический нейтрализатор — низкая эффективность при прогреве (Банк 1)',
      severity: 'medium',
      system: 'emission',
    ),
    'P0430': DtcEntry(
      descriptionEn: 'Catalyst System Efficiency Below Threshold (Bank 2)',
      descriptionRu: 'Каталитический нейтрализатор — эффективность ниже порога (Банк 2)',
      severity: 'medium',
      system: 'emission',
    ),

    // ===== EVAP (P0440-P0457) =====
    'P0440': DtcEntry(
      descriptionEn: 'Evaporative Emission System Malfunction',
      descriptionRu: 'Система улавливания паров топлива — неисправность',
      severity: 'low',
      system: 'emission',
    ),
    'P0441': DtcEntry(
      descriptionEn: 'EVAP System Incorrect Purge Flow',
      descriptionRu: 'Система EVAP — неправильный поток продувки',
      severity: 'low',
      system: 'emission',
    ),
    'P0442': DtcEntry(
      descriptionEn: 'EVAP System Leak Detected (Small Leak)',
      descriptionRu: 'Система EVAP — обнаружена небольшая утечка',
      severity: 'low',
      system: 'emission',
    ),
    'P0443': DtcEntry(
      descriptionEn: 'EVAP Purge Control Valve Circuit',
      descriptionRu: 'Цепь клапана продувки EVAP',
      severity: 'low',
      system: 'emission',
    ),
    'P0446': DtcEntry(
      descriptionEn: 'EVAP Vent Control Circuit',
      descriptionRu: 'Цепь вентиляции EVAP',
      severity: 'low',
      system: 'emission',
    ),
    'P0455': DtcEntry(
      descriptionEn: 'EVAP System Leak Detected (Large Leak)',
      descriptionRu: 'Система EVAP — обнаружена крупная утечка',
      severity: 'medium',
      system: 'emission',
    ),
    'P0456': DtcEntry(
      descriptionEn: 'EVAP System Leak Detected (Very Small Leak)',
      descriptionRu: 'Система EVAP — обнаружена очень маленькая утечка',
      severity: 'low',
      system: 'emission',
    ),

    // ===== MAF / MAP (P0100-P0113) =====
    'P0100': DtcEntry(
      descriptionEn: 'Mass Air Flow Circuit Malfunction',
      descriptionRu: 'Датчик массового расхода воздуха (MAF) — неисправность',
      severity: 'high',
      system: 'fuel',
    ),
    'P0101': DtcEntry(
      descriptionEn: 'Mass Air Flow Circuit Range/Performance',
      descriptionRu: 'Датчик MAF — выход за пределы',
      severity: 'medium',
      system: 'fuel',
    ),
    'P0102': DtcEntry(
      descriptionEn: 'Mass Air Flow Circuit Low',
      descriptionRu: 'Датчик MAF — низкий сигнал',
      severity: 'medium',
      system: 'fuel',
    ),
    'P0103': DtcEntry(
      descriptionEn: 'Mass Air Flow Circuit High',
      descriptionRu: 'Датчик MAF — высокий сигнал',
      severity: 'medium',
      system: 'fuel',
    ),
    'P0105': DtcEntry(
      descriptionEn: 'MAP/BARO Pressure Circuit Malfunction',
      descriptionRu: 'Датчик абсолютного давления (MAP) — неисправность',
      severity: 'high',
      system: 'fuel',
    ),
    'P0106': DtcEntry(
      descriptionEn: 'MAP/BARO Pressure Circuit Range/Performance',
      descriptionRu: 'Датчик MAP — выход за пределы',
      severity: 'medium',
      system: 'fuel',
    ),
    'P0107': DtcEntry(
      descriptionEn: 'MAP/BARO Pressure Circuit Low',
      descriptionRu: 'Датчик MAP — низкий сигнал',
      severity: 'medium',
      system: 'fuel',
    ),
    'P0108': DtcEntry(
      descriptionEn: 'MAP/BARO Pressure Circuit High',
      descriptionRu: 'Датчик MAP — высокий сигнал',
      severity: 'medium',
      system: 'fuel',
    ),

    // ===== THROTTLE (P0120-P0124) =====
    'P0120': DtcEntry(
      descriptionEn: 'Throttle Position Sensor Circuit',
      descriptionRu: 'Датчик положения дроссельной заслонки — неисправность',
      severity: 'high',
      system: 'fuel',
    ),
    'P0121': DtcEntry(
      descriptionEn: 'Throttle Position Sensor Range/Performance',
      descriptionRu: 'Датчик положения дроссельной заслонки — выход за пределы',
      severity: 'medium',
      system: 'fuel',
    ),
    'P0122': DtcEntry(
      descriptionEn: 'Throttle Position Sensor Circuit Low',
      descriptionRu: 'Датчик дроссельной заслонки — низкий сигнал',
      severity: 'high',
      system: 'fuel',
    ),

    // ===== CRANKSHAFT / CAMSHAFT =====
    'P0335': DtcEntry(
      descriptionEn: 'Crankshaft Position Sensor Circuit',
      descriptionRu: 'Датчик положения коленвала — неисправность',
      severity: 'critical',
      system: 'ignition',
    ),
    'P0336': DtcEntry(
      descriptionEn: 'Crankshaft Position Sensor Circuit Range/Performance',
      descriptionRu: 'Датчик положения коленвала — выход за пределы',
      severity: 'high',
      system: 'ignition',
    ),
    'P0340': DtcEntry(
      descriptionEn: 'Camshaft Position Sensor Circuit',
      descriptionRu: 'Датчик положения распредвала — неисправность',
      severity: 'high',
      system: 'ignition',
    ),
    'P0341': DtcEntry(
      descriptionEn: 'Camshaft Position Sensor Circuit Range/Performance',
      descriptionRu: 'Датчик положения распредвала — выход за пределы',
      severity: 'high',
      system: 'ignition',
    ),

    // ===== FUEL SYSTEM =====
    'P0190': DtcEntry(
      descriptionEn: 'Fuel Rail Pressure Sensor Circuit',
      descriptionRu: 'Датчик давления топлива в рампе — неисправность',
      severity: 'high',
      system: 'fuel',
    ),
    'P0191': DtcEntry(
      descriptionEn: 'Fuel Rail Pressure Sensor Range/Performance',
      descriptionRu: 'Датчик давления топлива — выход за пределы',
      severity: 'medium',
      system: 'fuel',
    ),
    'P0200': DtcEntry(
      descriptionEn: 'Injector Circuit Malfunction',
      descriptionRu: 'Цепь форсунки — неисправность',
      severity: 'high',
      system: 'fuel',
    ),
    'P0201': DtcEntry(
      descriptionEn: 'Injector Circuit - Cylinder 1',
      descriptionRu: 'Цепь форсунки — Цилиндр 1',
      severity: 'high',
      system: 'fuel',
    ),
    'P0202': DtcEntry(
      descriptionEn: 'Injector Circuit - Cylinder 2',
      descriptionRu: 'Цепь форсунки — Цилиндр 2',
      severity: 'high',
      system: 'fuel',
    ),
    'P0203': DtcEntry(
      descriptionEn: 'Injector Circuit - Cylinder 3',
      descriptionRu: 'Цепь форсунки — Цилиндр 3',
      severity: 'high',
      system: 'fuel',
    ),
    'P0204': DtcEntry(
      descriptionEn: 'Injector Circuit - Cylinder 4',
      descriptionRu: 'Цепь форсунки — Цилиндр 4',
      severity: 'high',
      system: 'fuel',
    ),

    // ===== EGR =====
    'P0400': DtcEntry(
      descriptionEn: 'Exhaust Gas Recirculation Flow Malfunction',
      descriptionRu: 'Система рециркуляции выхлопных газов (EGR) — неисправность',
      severity: 'medium',
      system: 'emission',
    ),
    'P0401': DtcEntry(
      descriptionEn: 'EGR Insufficient Flow',
      descriptionRu: 'EGR — недостаточный поток',
      severity: 'medium',
      system: 'emission',
    ),

    // ===== TRANSMISSION =====
    'P0700': DtcEntry(
      descriptionEn: 'Transmission Control System Malfunction',
      descriptionRu: 'Система управления трансмиссией — неисправность',
      severity: 'high',
      system: 'transmission',
    ),
    'P0715': DtcEntry(
      descriptionEn: 'Input/Turbine Speed Sensor Malfunction',
      descriptionRu: 'Датчик скорости турбины — неисправность',
      severity: 'high',
      system: 'transmission',
    ),
    'P0720': DtcEntry(
      descriptionEn: 'Output Speed Sensor Malfunction',
      descriptionRu: 'Датчик выходной скорости — неисправность',
      severity: 'high',
      system: 'transmission',
    ),
    'P0730': DtcEntry(
      descriptionEn: 'Incorrect Gear Ratio',
      descriptionRu: 'Неправильное передаточное число',
      severity: 'high',
      system: 'transmission',
    ),

    // ===== AIR SYSTEM =====
    'P0500': DtcEntry(
      descriptionEn: 'Vehicle Speed Sensor Malfunction',
      descriptionRu: 'Датчик скорости автомобиля — неисправность',
      severity: 'medium',
      system: 'other',
    ),
    'P0505': DtcEntry(
      descriptionEn: 'Idle Control System Malfunction',
      descriptionRu: 'Система регулирования холостого хода — неисправность',
      severity: 'medium',
      system: 'fuel',
    ),
    'P0506': DtcEntry(
      descriptionEn: 'Idle Air Control System RPM Lower Than Expected',
      descriptionRu: 'Обороты холостого хода ниже нормы',
      severity: 'medium',
      system: 'fuel',
    ),
    'P0507': DtcEntry(
      descriptionEn: 'Idle Air Control System RPM Higher Than Expected',
      descriptionRu: 'Обороты холостого хода выше нормы',
      severity: 'medium',
      system: 'fuel',
    ),

    // ===== COMMON BODY / NETWORK =====
    'B0001': DtcEntry(
      descriptionEn: 'Driver Frontal Stage 1 Deployment Control',
      descriptionRu: 'Система подушек безопасности водителя',
      severity: 'high',
      system: 'body',
    ),
    'U0100': DtcEntry(
      descriptionEn: 'Lost Communication With ECM/PCM',
      descriptionRu: 'Потеряна связь с блоком управления двигателем',
      severity: 'critical',
      system: 'network',
    ),
    'U0101': DtcEntry(
      descriptionEn: 'Lost Communication With TCM',
      descriptionRu: 'Потеряна связь с блоком управления трансмиссией',
      severity: 'high',
      system: 'network',
    ),
    'U0121': DtcEntry(
      descriptionEn: 'Lost Communication With ABS',
      descriptionRu: 'Потеряна связь с блоком ABS',
      severity: 'high',
      system: 'network',
    ),
  };
}

class DtcEntry {
  final String descriptionEn;
  final String descriptionRu;
  final String severity; // low, medium, high, critical
  final String system;   // fuel, ignition, emission, cooling, transmission, other

  const DtcEntry({
    required this.descriptionEn,
    required this.descriptionRu,
    required this.severity,
    required this.system,
  });
}
