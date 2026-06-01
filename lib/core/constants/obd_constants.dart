/// OBD-II protocol constants, AT commands, and PID definitions
class OBDConstants {
  OBDConstants._();

  // === ELM327 AT Commands ===
  static const String atReset = 'ATZ';          // Reset all
  static const String atEchoOff = 'ATE0';       // Echo off
  static const String atLinefeedOff = 'ATL0';   // Linefeed off
  static const String atSpacesOff = 'ATS0';     // Spaces off
  static const String atHeadersOff = 'ATH0';    // Headers off
  static const String atHeadersOn = 'ATH1';     // Headers on
  static const String atAutoProtocol = 'ATSP0'; // Auto detect protocol
  static const String atDescribeProtocol = 'ATDP';   // Describe current protocol
  static const String atReadVoltage = 'ATRV';   // Read battery voltage
  static const String atAdaptiveTiming = 'ATAT1'; // Adaptive timing auto1

  // Initialization sequence
  static const List<String> initSequence = [
    atReset,
    atEchoOff,
    atLinefeedOff,
    atSpacesOff,
    atHeadersOff,
    atAdaptiveTiming,
    atAutoProtocol,
  ];

  // === OBD-II Mode Commands ===
  static const String modeCurrentData = '01';    // Mode 01 - Current data
  static const String modeFreezeFrame = '02';    // Mode 02 - Freeze frame
  static const String modeStoredDTC = '03';      // Mode 03 - Stored DTCs
  static const String modeClearDTC = '04';       // Mode 04 - Clear DTCs
  static const String modePendingDTC = '07';     // Mode 07 - Pending DTCs
  static const String modeVehicleInfo = '09';    // Mode 09 - Vehicle Info

  // === Mode 01 PIDs ===
  static const String pidSupportedPids = '0100';       // Supported PIDs [01-20]
  static const String pidStatusSinceClear = '0101';    // Monitor status since DTC cleared
  static const String pidFreezeFrameDTC = '0102';      // Freeze DTC
  static const String pidFuelSystemStatus = '0103';    // Fuel system status
  static const String pidEngineLoad = '0104';          // Calculated engine load
  static const String pidCoolantTemp = '0105';         // Engine coolant temperature
  static const String pidStft1 = '0106';               // Short term fuel trim Bank 1
  static const String pidLtft1 = '0107';               // Long term fuel trim Bank 1
  static const String pidStft2 = '0108';               // Short term fuel trim Bank 2
  static const String pidLtft2 = '0109';               // Long term fuel trim Bank 2
  static const String pidFuelPressure = '010A';        // Fuel pressure
  static const String pidIntakeManifoldPressure = '010B'; // Intake manifold absolute pressure
  static const String pidRpm = '010C';                 // Engine RPM
  static const String pidSpeed = '010D';               // Vehicle speed
  static const String pidTimingAdvance = '010E';       // Timing advance
  static const String pidIntakeAirTemp = '010F';       // Intake air temperature
  static const String pidMafAirFlow = '0110';          // MAF air flow rate
  static const String pidThrottlePosition = '0111';    // Throttle position
  static const String pidO2voltage1 = '0114';          // O2 Sensor 1 voltage
  static const String pidO2voltage2 = '0115';          // O2 Sensor 2 voltage
  static const String pidOBDStandard = '011C';         // OBD standards compliance
  static const String pidRuntimeSinceStart = '011F';   // Runtime since engine start
  static const String pidSupportedPids21 = '0120';     // Supported PIDs [21-40]
  static const String pidDistanceWithMIL = '0121';     // Distance traveled with MIL on
  static const String pidFuelRailPressure = '0122';    // Fuel rail pressure
  static const String pidCatalystTempBank1 = '013C';   // Catalyst Temperature Bank 1
  static const String pidControlModuleVoltage = '0142'; // Control module voltage
  static const String pidFuelType = '0151';            // Fuel type
  static const String pidEthanolFuelPercent = '0152';  // Ethanol fuel %

  // === Mode 09 PIDs ===
  static const String pidVIN = '0902';                 // VIN (Vehicle Identification Number)
  static const String pidCalibrationID = '0904';       // Calibration ID
  static const String pidECUName = '090A';             // ECU name

  // === Response parsing ===
  static const String responseOK = 'OK';
  static const String responseNoData = 'NO DATA';
  static const String responseError = 'ERROR';
  static const String responseUnableToConnect = 'UNABLE TO CONNECT';
  static const String responseSearching = 'SEARCHING...';
  static const String responsePrompt = '>';

  // === BLE UUIDs (OBDLink / Vgate) ===
  static const String bleServiceUUID = '0000fff0-0000-1000-8000-00805f9b34fb';
  static const String bleWriteCharUUID = '0000fff2-0000-1000-8000-00805f9b34fb';
  static const String bleNotifyCharUUID = '0000fff1-0000-1000-8000-00805f9b34fb';

  // Alternative BLE UUIDs
  static const String bleServiceUUID2 = '000018f0-0000-1000-8000-00805f9b34fb';
  static const String bleWriteCharUUID2 = '00002af1-0000-1000-8000-00805f9b34fb';
  static const String bleNotifyCharUUID2 = '00002af0-0000-1000-8000-00805f9b34fb';

  // === Bluetooth Classic UUID ===
  static const String sppUUID = '00001101-0000-1000-8000-00805F9B34FB';

  // === Timeouts ===
  static const int connectionTimeoutMs = 15000;
  static const int commandTimeoutMs = 5000;
  static const int initTimeoutMs = 10000;
  static const int scanTimeoutMs = 10000;

  // === Polling Intervals ===
  static const int liveDataPollMs = 500;
  static const int healthCheckPollMs = 30000;
}
