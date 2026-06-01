import 'dart:async';
import '../../data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/dtc_code.dart';
import '../../data/models/live_data.dart';
import '../../data/models/vehicle_info.dart';
import '../../data/models/diagnostic_result.dart';
import '../../data/models/ai_explanation.dart';
import '../../data/datasources/obd/obd_data_source.dart';
import '../../data/datasources/obd/demo_obd_source.dart';
import '../../data/datasources/obd/real_obd_source.dart';
import '../../data/datasources/ai/gemini_service.dart';
import '../../domain/engine/diagnostic_engine.dart';
import '../../domain/engine/health_score_calculator.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/logging/app_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


// ─── Language ─────────────────────────────────────────────────────────────────

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('ru') {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('language') ?? 'ru';
  }

  Future<void> setLanguage(String lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }
}

final localeProvider = Provider<AppLocale>((ref) {
  final lang = ref.watch(languageProvider);
  return AppLocale(lang);
});

// ─── Connection State ─────────────────────────────────────────────────────────

enum ConnectionStatus { disconnected, scanning, connecting, connected, error, reconnecting }

final connectionStatusProvider = StateProvider<ConnectionStatus>((ref) {
  return ConnectionStatus.disconnected;
});

final isDemoModeProvider = StateProvider<bool>((ref) => false);

// ─── OBD Sources ──────────────────────────────────────────────────────────────

final demoObdSourceProvider = Provider<DemoObdSource>((ref) => DemoObdSource());
final realObdSourceProvider = Provider<RealObdSource>((ref) => RealObdSource());

final obdDataSourceProvider = Provider<ObdDataSource>((ref) {
  final isDemo = ref.watch(isDemoModeProvider);
  return isDemo
      ? ref.watch(demoObdSourceProvider)
      : ref.watch(realObdSourceProvider);
});

// ─── Vehicle Info ─────────────────────────────────────────────────────────────

final vehicleInfoProvider = StateProvider<VehicleInfo?>((ref) => null);

// ─── Live Data ────────────────────────────────────────────────────────────────

final liveDataProvider = StateNotifierProvider<LiveDataNotifier, LiveData?>((ref) {
  return LiveDataNotifier(ref);
});

class LiveDataNotifier extends StateNotifier<LiveData?> {
  final Ref ref;
  StreamSubscription? _subscription;

  LiveDataNotifier(this.ref) : super(null);

  void startListening() {
    final obd = ref.read(obdDataSourceProvider);
    _subscription?.cancel();
    _subscription = obd.getLiveDataStream().listen(
      (data) => state = data,
      onError: (e) => AppLogger.e('LiveData stream error', error: e),
    );
    AppLogger.d('LiveData stream started');
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    state = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// ─── DTC Codes ────────────────────────────────────────────────────────────────

final dtcCodesProvider =
    StateNotifierProvider<DtcCodesNotifier, List<DtcCode>>((ref) {
  return DtcCodesNotifier(ref);
});

class DtcCodesNotifier extends StateNotifier<List<DtcCode>> {
  final Ref ref;

  DtcCodesNotifier(this.ref) : super([]);

  Future<void> scanDtcCodes() async {
    final obd = ref.read(obdDataSourceProvider);
    AppLogger.obd('Scanning DTC codes...');
    state = await obd.readDtcCodes();
    AppLogger.obd('DTCs found: ${state.length}');
  }

  Future<void> clearDtcCodes() async {
    final obd = ref.read(obdDataSourceProvider);
    await obd.clearDtcCodes();
    state = [];
  }

  void setDtcCodes(List<DtcCode> codes) => state = codes;
}

// ─── Diagnostic Engine ────────────────────────────────────────────────────────

final diagnosticEngineProvider = Provider<DiagnosticEngine>((ref) {
  return DiagnosticEngine();
});

// ─── Diagnostic Results ───────────────────────────────────────────────────────

final diagnosticResultsProvider =
    StateProvider<Map<String, DiagnosticResult>>((ref) => {});

// ─── Gemini AI Service ────────────────────────────────────────────────────────

/// Singleton GeminiService — created once and reused for all AI requests
final geminiServiceProvider =
    StateNotifierProvider<GeminiServiceNotifier, String>((ref) {
  return GeminiServiceNotifier();
});

class GeminiServiceNotifier extends StateNotifier<String> {
  late GeminiService _service;

  GeminiServiceNotifier() : super('') {
    _service = GeminiService(apiKey: '');
    _loadKey();
  }

  Future<void> _loadKey() async {
    final prefs = await SharedPreferences.getInstance();
    String? key = prefs.getString('gemini_api_key');
    
    // Fallback to .env if not found in SharedPreferences
    if (key == null || key.isEmpty) {
      key = dotenv.env['GEMINI_API_KEY'] ?? '';
    }
    
    state = key;
    _service.updateApiKey(key);
  }

  Future<void> setApiKey(String key) async {
    final cleanKey = key.trim();
    state = cleanKey;
    _service.updateApiKey(cleanKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', cleanKey);
    AppLogger.ai('API key updated');
  }

  /// The singleton service instance — reuse this, don't create new ones
  GeminiService get service => _service;
}

final aiExplanationsProvider =
    StateProvider<Map<String, AiExplanation>>((ref) => {});

final aiLoadingProvider = StateProvider<bool>((ref) => false);

// ─── Health Score ─────────────────────────────────────────────────────────────

final healthScoreProvider = Provider<int>((ref) {
  final dtcs = ref.watch(dtcCodesProvider);
  final liveData = ref.watch(liveDataProvider);
  if (liveData == null) return -1;
  return HealthScoreCalculator.calculate(activeDtcs: dtcs, liveData: liveData);
});

// ─── Database ─────────────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final diagnosticHistoryProvider = StreamProvider<List<DiagnosticSession>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllSessions();
});

// ─── UI State ─────────────────────────────────────────────────────────────────

final selectedDtcProvider = StateProvider<DtcCode?>((ref) => null);
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
