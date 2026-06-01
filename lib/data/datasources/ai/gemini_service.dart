import 'dart:async';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/diagnostic_result.dart';
import '../../models/ai_explanation.dart';
import '../../../core/logging/app_logger.dart';

/// Production AI service with:
/// - Singleton GenerativeModel (created once, reused)
/// - Request queue (serial, deduplicated by DTC code)
/// - 30-second timeout per request
/// - Retry with exponential backoff for 503 errors
/// - Model fallback chain
/// - Streaming response support
/// - Fallback to offline explanation on any failure
class GeminiService {
  String _apiKey;
  GenerativeModel? _model;
  String _currentModelName = _primaryModel;

  // Model fallback chain — if primary is overloaded, try alternatives
  static const String _primaryModel = 'gemini-2.5-flash';
  static const List<String> _fallbackModels = [
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  // Retry config
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 2);

  // Request queue
  final _queue = <_AiRequest>[];
  bool _processing = false;
  final _pendingCodes = <String>{};

  GeminiService({required String apiKey}) : _apiKey = apiKey;

  bool get isConfigured =>
      _apiKey.isNotEmpty && _apiKey != 'your_gemini_api_key_here';

  void updateApiKey(String key) {
    if (_apiKey == key) return;
    _apiKey = key;
    _model = null; // force recreate
    _currentModelName = _primaryModel; // reset to primary model
    AppLogger.ai('API key updated, model will be recreated');
  }

  GenerativeModel _getModel(bool isRussian, {String? modelName}) {
    final targetModel = modelName ?? _currentModelName;
    // Recreate if model name changed or not yet created
    if (_model == null || _currentModelName != targetModel) {
      _currentModelName = targetModel;
      _model = GenerativeModel(
        model: targetModel,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.3,
          maxOutputTokens: 800,
        ),
      );
      AppLogger.ai('Created model: $targetModel');
    }
    return _model!;
  }

  /// Create a new ChatSession for conversational UI
  ChatSession startChat(bool isRussian) {
    if (!isConfigured) {
      throw GenerativeAIException(
        isRussian
            ? 'API-ключ не настроен. Пожалуйста, укажите его в настройках.'
            : 'API key is not configured. Please set it in Settings.',
      );
    }
    // We use a separate model instance for chat because we don't want JSON output
    final chatModel = GenerativeModel(
      model: _currentModelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7, // More creative/conversational
      ),
      systemInstruction: Content.system(isRussian
          ? 'Ты — AI Auto Doctor, профессиональный автомеханик и диагност. Отвечай на вопросы пользователя по автомобилям вежливо, понятно и по делу.'
          : 'You are AI Auto Doctor, a professional auto mechanic and diagnostician. Answer user questions about cars politely, clearly, and to the point.'),
    );
    AppLogger.ai('Chat session started with model: $_currentModelName');
    return chatModel.startChat();
  }

  /// Enqueue an AI explanation request.
  /// Returns immediately with a Future that resolves when processed.
  /// Deduplicates: if same DTC code is already queued, returns existing future.
  Future<AiExplanation> explain({
    required DiagnosticResult result,
    required String languageCode,
  }) async {
    if (!isConfigured) {
      AppLogger.ai('Not configured — returning offline explanation');
      return _offlineFallback(result, languageCode);
    }

    final code = result.dtcCode;

    // Deduplication: reuse existing request if same code is queued
    final existing = _queue.where((r) => r.dtcCode == code).firstOrNull;
    if (existing != null) {
      AppLogger.ai('Dedup: $code already queued, reusing future');
      return existing.completer.future;
    }

    final request = _AiRequest(
      dtcCode: code,
      result: result,
      languageCode: languageCode,
      completer: Completer<AiExplanation>(),
    );

    _queue.add(request);
    _pendingCodes.add(code);
    AppLogger.ai('Queued AI request for $code (queue size: ${_queue.length})');

    _processQueue();
    return request.completer.future;
  }

  void _processQueue() {
    if (_processing || _queue.isEmpty) return;
    _processing = true;
    _processNext();
  }

  Future<void> _processNext() async {
    while (_queue.isNotEmpty) {
      final req = _queue.first;
      AppLogger.ai('Processing AI request: ${req.dtcCode}');

      try {
        final explanation = await _callGeminiWithRetry(
          result: req.result,
          languageCode: req.languageCode,
        ).timeout(const Duration(seconds: 45));

        req.completer.complete(explanation);
        AppLogger.ai('AI request completed: ${req.dtcCode}');
      } catch (e) {
        AppLogger.e('AI request failed: ${req.dtcCode}', error: e);
        req.completer.complete(_offlineFallback(req.result, req.languageCode));
      } finally {
        _queue.remove(req);
        _pendingCodes.remove(req.dtcCode);
      }
    }
    _processing = false;
  }

  /// Retry wrapper with exponential backoff and model fallback
  Future<AiExplanation> _callGeminiWithRetry({
    required DiagnosticResult result,
    required String languageCode,
  }) async {
    // Try primary model with retries
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        return await _callGemini(
          result: result,
          languageCode: languageCode,
        );
      } catch (e) {
        final isRetryable = _isRetryableError(e);
        AppLogger.ai(
          'Attempt ${attempt + 1}/$_maxRetries failed (model: $_currentModelName, retryable: $isRetryable): $e',
        );

        if (!isRetryable || attempt == _maxRetries - 1) {
          // Not retryable or last attempt — try fallback models
          break;
        }

        // Exponential backoff: 2s, 4s, 8s
        final delay = _initialRetryDelay * (1 << attempt);
        AppLogger.ai('Retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
      }
    }

    // Try fallback models
    for (final fallbackModel in _fallbackModels) {
      if (fallbackModel == _currentModelName) continue;
      AppLogger.ai('Trying fallback model: $fallbackModel');

      try {
        _model = null; // force recreate with new model
        _currentModelName = fallbackModel;
        return await _callGemini(
          result: result,
          languageCode: languageCode,
        );
      } catch (e) {
        AppLogger.ai('Fallback model $fallbackModel also failed: $e');
      }
    }

    // All models failed — throw to trigger offline fallback
    throw Exception('All AI models unavailable');
  }

  /// Check if an error is transient and worth retrying
  bool _isRetryableError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('503') ||
        msg.contains('429') ||
        msg.contains('high demand') ||
        msg.contains('unavailable') ||
        msg.contains('overloaded') ||
        msg.contains('rate limit') ||
        msg.contains('resource exhausted') ||
        msg.contains('timeout');
  }

  Future<AiExplanation> _callGemini({
    required DiagnosticResult result,
    required String languageCode,
  }) async {
    final isRu = languageCode == 'ru';
    final model = _getModel(isRu);

    final systemPrompt = _buildSystemPrompt(isRu);
    final userPrompt = _buildUserPrompt(result, isRu);

    // Use streaming for better perceived performance
    final buffer = StringBuffer();
    final stream = model.generateContentStream([
      Content.system(systemPrompt),
      Content.text(userPrompt),
    ]);

    await for (final chunk in stream) {
      if (chunk.text != null) buffer.write(chunk.text);
    }

    final content = buffer.toString().trim();
    AppLogger.ai('Raw AI response (${content.length} chars): ${content.substring(0, content.length.clamp(0, 100))}...');

    // Clean markdown fences if model wraps in ```json ```
    final jsonStr = _extractJson(content);
    final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
    return AiExplanation.fromApiResponse(result.dtcCode, parsed);
  }

  String _extractJson(String raw) {
    // Strip ```json ... ``` if present
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', multiLine: true);
    final match = fenced.firstMatch(raw);
    if (match != null) return match.group(1)!;
    // Find first { ... }
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return raw.substring(start, end + 1);
    }
    return raw;
  }

  AiExplanation _offlineFallback(DiagnosticResult result, String languageCode) {
    final isRu = languageCode == 'ru';
    final desc = result.causes.isNotEmpty
        ? (isRu ? result.causes.first.descriptionRu : result.causes.first.description)
        : (isRu ? 'Анализ выполнен локально' : 'Local analysis performed');
    return AiExplanation.offline(dtcCode: result.dtcCode, description: desc);
  }

  String _buildSystemPrompt(bool isRu) {
    if (isRu) {
      return '''Ты — профессиональный ИИ-диагност автомобилей. Анализируй ТОЛЬКО предоставленные диагностические данные.
НЕ придумывай неисправности. Отвечай строго по данным.

Правила:
- Простой язык, понятный водителю без технического образования
- Только реальные причины, подтверждённые данными
- Конкретный план действий
- Точная оценка критичности

Ответь СТРОГО в JSON без Markdown:
{
  "problem": "суть проблемы простым языком",
  "symptoms": "как проявляется при вождении",
  "danger_level": "Низкая|Средняя|Высокая|Критическая",
  "can_drive": "Да|Осторожно|Нет — эвакуатор",
  "causes": [
    {"description": "причина 1", "probability": 85},
    {"description": "причина 2", "probability": 60}
  ],
  "repair_cost": "оценка стоимости ремонта",
  "specialist": "тип специалиста",
  "confidence": 85
}''';
    } else {
      return '''You are a professional AI vehicle diagnostic assistant. Analyze ONLY the provided diagnostic data.
Do NOT invent faults. Answer strictly based on data.

Rules:
- Simple language, understandable to a non-technical driver
- Only real causes confirmed by the data
- Concrete action plan
- Accurate criticality assessment

Respond STRICTLY in JSON without Markdown:
{
  "problem": "problem explanation in simple terms",
  "symptoms": "how it manifests while driving",
  "danger_level": "Low|Medium|High|Critical",
  "can_drive": "Yes|Carefully|No — call tow truck",
  "causes": [
    {"description": "cause 1", "probability": 85},
    {"description": "cause 2", "probability": 60}
  ],
  "repair_cost": "estimated repair cost",
  "specialist": "type of specialist needed",
  "confidence": 85
}''';
    }
  }

  String _buildUserPrompt(DiagnosticResult result, bool isRu) {
    final context = result.toAiContext();
    if (isRu) {
      return 'Код ошибки: ${result.dtcCode}\n'
          'Уверенность модуля: ${result.confidencePercent}%\n'
          'Серьёзность: ${result.overallSeverity}\n'
          'Данные датчиков: ${jsonEncode(context)}\n'
          'Сгенерируй JSON ответ строго по системным инструкциям.';
    } else {
      return 'Error code: ${result.dtcCode}\n'
          'Module confidence: ${result.confidencePercent}%\n'
          'Severity: ${result.overallSeverity}\n'
          'Sensor data: ${jsonEncode(context)}\n'
          'Generate JSON response strictly per system instructions.';
    }
  }

  void cancelPending() {
    for (final req in _queue) {
      if (!req.completer.isCompleted) {
        req.completer.complete(_offlineFallback(req.result, req.languageCode));
      }
    }
    _queue.clear();
    _pendingCodes.clear();
    _processing = false;
  }
}

class _AiRequest {
  final String dtcCode;
  final DiagnosticResult result;
  final String languageCode;
  final Completer<AiExplanation> completer;

  _AiRequest({
    required this.dtcCode,
    required this.result,
    required this.languageCode,
    required this.completer,
  });
}
