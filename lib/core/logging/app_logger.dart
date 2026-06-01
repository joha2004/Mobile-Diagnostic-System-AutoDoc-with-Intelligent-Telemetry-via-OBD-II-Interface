import 'package:flutter/foundation.dart';

enum LogLevel { verbose, debug, info, warning, error }

/// Structured logger for AI Auto Doctor
/// All BT/OBD/AI events go through here for easy debugging
class AppLogger {
  static const String _tag = 'AutoDoctor';
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;

  static void setMinLevel(LogLevel level) => _minLevel = level;

  static void v(String message, {String? tag}) =>
      _log(LogLevel.verbose, '🔍', tag ?? _tag, message);

  static void d(String message, {String? tag}) =>
      _log(LogLevel.debug, '🔧', tag ?? _tag, message);

  static void i(String message, {String? tag}) =>
      _log(LogLevel.info, 'ℹ️ ', tag ?? _tag, message);

  static void w(String message, {String? tag}) =>
      _log(LogLevel.warning, '⚠️ ', tag ?? _tag, message);

  static void e(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    _log(LogLevel.error, '❌', tag ?? _tag, message);
    if (error != null && kDebugMode) debugPrint('   └─ $error');
    if (stackTrace != null && kDebugMode) debugPrint('   └─ $stackTrace');
  }

  // BT-specific shortcuts
  static void bt(String message) => _log(LogLevel.info, '📶', 'BT', message);
  static void obd(String message) => _log(LogLevel.info, '🔌', 'OBD', message);
  static void ai(String message) => _log(LogLevel.info, '🤖', 'AI', message);

  static void _log(LogLevel level, String emoji, String tag, String message) {
    if (level.index < _minLevel.index) return;
    final time = DateTime.now();
    final ts = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.${time.millisecond.toString().padLeft(3, '0')}';
    debugPrint('$emoji [$tag][$ts] $message');
  }
}
