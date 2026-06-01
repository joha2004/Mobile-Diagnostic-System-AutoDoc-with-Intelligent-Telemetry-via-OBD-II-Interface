import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../logging/app_logger.dart';

/// Async serial command queue for ELM327 / OBD adapters.
/// Guarantees only ONE command is in-flight at any time, preventing
/// Completer conflicts and buffer corruption.
class OBDCommandQueue {
  static const int _defaultTimeoutMs = 2000;
  static const int _initTimeoutMs = 6000;
  static const int _maxRetries = 2;
  static const int _retryDelayMs = 300;

  BluetoothCharacteristic? _txChar;

  String _rxBuffer = '';
  Completer<String>? _pending;

  bool _disposed = false;

  void attach({
    required BluetoothCharacteristic tx,
  }) {
    _txChar = tx;
    _rxBuffer = '';
    _pending = null;
  }

  /// Called by the BLE notification listener
  void onDataReceived(List<int> data) {
    if (data.isEmpty || _disposed) return;

    String chunk;
    try {
      chunk = ascii.decode(data, allowInvalid: true);
    } catch (_) {
      chunk = String.fromCharCodes(data.where((b) => b >= 0x20 && b <= 0x7E));
    }

    _rxBuffer += chunk;

    // ELM327 signals end-of-response with '>'
    if (_rxBuffer.contains('>')) {
      final response = _rxBuffer
          .split('>')
          .first
          .replaceAll('\r', ' ')
          .replaceAll('\n', ' ')
          .trim();
      _rxBuffer = '';

      AppLogger.v('OBD ← "$response"', tag: 'Queue');

      if (_pending != null && !_pending!.isCompleted) {
        _pending!.complete(response);
      }
    }
  }

  /// Send a single OBD command and await the response.
  /// [isInit] — use longer timeout for AT initialization commands
  Future<String> send(String cmd, {bool isInit = false}) async {
    if (_txChar == null || _disposed) return '';

    final timeout = isInit ? _initTimeoutMs : _defaultTimeoutMs;
    int attempt = 0;

    while (attempt <= _maxRetries) {
      try {
        _rxBuffer = ''; // always clear before sending
        _pending = Completer<String>();

        final bytes = ascii.encode('$cmd\r');
        AppLogger.v('OBD → "$cmd"', tag: 'Queue');

        await _txChar!.write(
          bytes,
          withoutResponse: _txChar!.properties.writeWithoutResponse,
        );

        final response = await _pending!.future.timeout(
          Duration(milliseconds: timeout),
        );

        // Don't retry on non-error responses
        if (!OBDCommandQueueHelpers.isAdapterError(response) || attempt == _maxRetries) {
          return response;
        }

        attempt++;
        AppLogger.w('OBD retry $attempt for "$cmd" (got: $response)', tag: 'Queue');
        await Future.delayed(const Duration(milliseconds: _retryDelayMs));
      } on TimeoutException {
        attempt++;
        if (attempt > _maxRetries) {
          AppLogger.w('OBD timeout after ${_maxRetries + 1} attempts: "$cmd"', tag: 'Queue');
          _pending = null;
          return '';
        }
        AppLogger.w('OBD timeout attempt $attempt for "$cmd"', tag: 'Queue');
        await Future.delayed(const Duration(milliseconds: _retryDelayMs));
      } catch (e) {
        AppLogger.e('OBD send error for "$cmd"', error: e, tag: 'Queue');
        _pending = null;
        return '';
      }
    }
    return '';
  }

  void dispose() {
    _disposed = true;
    _pending?.complete('');
    _pending = null;
  }
}

class OBDCommandQueueHelpers {
  static bool isAdapterError(String r) {
    final u = r.toUpperCase();
    return u.contains('ERROR') || u.contains('UNABLE') || u.contains('BUS INIT') || u.contains('STOPPED');
  }
}
