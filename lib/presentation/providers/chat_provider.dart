import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'app_providers.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    required this.messages,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  ChatSession? _session;
  static const int _maxRetries = 3;

  ChatNotifier(this._ref) : super(ChatState(messages: []));

  void initSession() {
    final service = _ref.read(geminiServiceProvider.notifier).service;
    final isRu = _ref.read(languageProvider) == 'ru';
    _session = service.startChat(isRu);
    state = ChatState(messages: []);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(text: text, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    final isRu = _ref.read(languageProvider) == 'ru';

    // Retry loop with exponential backoff for 503 errors
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        if (_session == null) initSession();
        
        final response = await _session!
            .sendMessage(Content.text(text))
            .timeout(const Duration(seconds: 30));
        final aiMsg = ChatMessage(text: response.text ?? '...', isUser: false);
        state = state.copyWith(
          messages: [...state.messages, aiMsg],
          isLoading: false,
        );
        return; // Success — exit
      } catch (e) {
        final isRetryable = _isRetryableError(e);

        if (isRetryable && attempt < _maxRetries) {
          // Exponential backoff: 2s, 4s, 8s
          final delay = Duration(seconds: 2 * (1 << attempt));
          state = state.copyWith(
            error: isRu
                ? 'Сервер перегружен, повтор через ${delay.inSeconds}с... (${attempt + 1}/$_maxRetries)'
                : 'Server overloaded, retrying in ${delay.inSeconds}s... (${attempt + 1}/$_maxRetries)',
          );
          await Future.delayed(delay);

          // Recreate session on retry (model might switch to fallback)
          if (attempt == _maxRetries - 1) {
            _session = null; // Force new session which may use fallback model
            if (_session == null) initSession();
          }
          continue;
        }

        // Final failure — show friendly error
        String errorMessage;
        if (_isRetryableError(e)) {
          errorMessage = isRu
              ? '⚠️ Сервер ИИ временно перегружен. Попробуйте через 1–2 минуты.'
              : '⚠️ AI server is temporarily overloaded. Please try again in 1–2 minutes.';
        } else if (e is TimeoutException) {
          errorMessage = isRu
              ? '⏱ Время ожидания истекло. Попробуйте ещё раз.'
              : '⏱ Request timed out. Please try again.';
        } else {
          errorMessage = isRu ? 'Ошибка: $e' : 'Error: $e';
        }

        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
        );
        return;
      }
    }
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
        msg.contains('resource exhausted');
  }
}
