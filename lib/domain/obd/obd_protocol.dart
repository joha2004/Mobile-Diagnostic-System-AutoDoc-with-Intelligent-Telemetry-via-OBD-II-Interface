class ObdProtocol {
  final String id;
  final String name;

  const ObdProtocol(this.id, this.name);

  static const automatic = ObdProtocol('0', 'Automatic');
  static const saeJ1850Pwm = ObdProtocol('1', 'SAE J1850 PWM (41.6 kbaud)');
  static const saeJ1850Vpw = ObdProtocol('2', 'SAE J1850 VPW (10.4 kbaud)');
  static const iso9141_2 = ObdProtocol('3', 'ISO 9141-2 (5 baud init)');
  static const iso14230_4Kwp5baud = ObdProtocol('4', 'ISO 14230-4 KWP (5 baud init)');
  static const iso14230_4KwpFast = ObdProtocol('5', 'ISO 14230-4 KWP (fast init)');
  static const iso15765_4Can11_500 = ObdProtocol('6', 'ISO 15765-4 CAN (11 bit ID, 500 kbaud)');
  static const iso15765_4Can29_500 = ObdProtocol('7', 'ISO 15765-4 CAN (29 bit ID, 500 kbaud)');
  static const iso15765_4Can11_250 = ObdProtocol('8', 'ISO 15765-4 CAN (11 bit ID, 250 kbaud)');
  static const iso15765_4Can29_250 = ObdProtocol('9', 'ISO 15765-4 CAN (29 bit ID, 250 kbaud)');
  static const saeJ1939Can = ObdProtocol('A', 'SAE J1939 CAN');
}

class ObdException implements Exception {
  final String message;
  ObdException(this.message);

  @override
  String toString() => 'ObdException: $message';
}
