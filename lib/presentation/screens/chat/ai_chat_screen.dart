import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../providers/chat_provider.dart';
import '../../../core/theme/app_colors.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          if (!HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.shiftLeft) &&
              !HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.shiftRight)) {
            _sendMessage();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).initSession();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);
    final isRu = ref.watch(languageProvider) == 'ru';

    // Auto-scroll when new message arrives
    ref.listen(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              isRu ? 'Чат с ИИ' : 'AI Chat',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? Center(
                    child: Text(
                      isRu ? 'Напишите ваш вопрос об автомобиле' : 'Ask any question about your car',
                      style: const TextStyle(color: AppColors.textTertiary),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          ),
                        );
                      }
                      final msg = state.messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                state.error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          _buildInputArea(isRu),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.primary.withAlpha(50) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: msg.isUser ? const Radius.circular(4) : const Radius.circular(20),
            bottomLeft: msg.isUser ? const Radius.circular(20) : const Radius.circular(4),
          ),
          border: Border.all(
            color: msg.isUser ? AppColors.primary.withAlpha(100) : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          msg.text,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isRu) {
    return Container(
      padding: EdgeInsets.only(
        // Add 100 pixels to clear the floating bottom navigation bar
        bottom: MediaQuery.of(context).padding.bottom + 100,
        top: 12,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              style: const TextStyle(color: AppColors.textPrimary),
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: isRu ? 'Спросить ИИ...' : 'Ask AI...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
