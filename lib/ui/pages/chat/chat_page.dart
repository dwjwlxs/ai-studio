import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../../../app/providers.dart';
import '../../../data/models/chat_message.dart';
import '../../core/widgets/model_selector.dart';
import '../../core/widgets/parameter_panel.dart';
import '../../core/widgets/raw_json_viewer.dart';
import '../../core/widgets/response_metadata.dart';
import '../../core/widgets/error_display.dart';
import 'conversation_sidebar.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  double? _temperature;
  int? _maxTokens;
  double? _topP;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _inputController.text.trim();
    final model = ref.read(selectedModelProvider('chat'));
    if (content.isEmpty || model == null) return;

    _inputController.clear();
    ref.read(chatProvider.notifier).sendMessage(
          content,
          model,
          temperature: _temperature,
          maxTokens: _maxTokens,
          topP: _topP,
          stream: true,
        );

    // Auto-scroll after sending
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
    final chatState = ref.watch(chatProvider);
    final selectedModel = ref.watch(selectedModelProvider('chat'));

    return Row(
      children: [
        const ConversationSidebar(),
        // Main chat area
        Expanded(
          child: Column(
            children: [
              // Top bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('Model:', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    ModelSelector(
                      value: selectedModel,
                      onChanged: (v) => ref
                          .read(selectedModelProvider('chat').notifier)
                          .setModel(v),
                    ),
                    const Spacer(),
                    // Generation status indicator
                    if (chatState.phase != GenerationPhase.idle)
                      _GenerationStatusBadge(phase: chatState.phase),
                    if (chatState.isStreaming)
                      IconButton(
                        icon: const Icon(Icons.stop_circle, color: Colors.red),
                        tooltip: 'Stop streaming',
                        onPressed: () =>
                            ref.read(chatProvider.notifier).stopStreaming(),
                      ),
                  ],
                ),
              ),
              // Parameter panel
              ParameterPanel(
                temperature: _temperature,
                maxTokens: _maxTokens,
                topP: _topP,
                onTemperatureChanged: (v) => setState(() => _temperature = v),
                onMaxTokensChanged: (v) => setState(() => _maxTokens = v),
                onTopPChanged: (v) => setState(() => _topP = v),
              ),
              // Error
              ErrorDisplay(error: chatState.error),
              // Messages
              Expanded(
                child: chatState.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64,
                                color: Theme.of(context).disabledColor),
                            const SizedBox(height: 16),
                            Text('Start a conversation',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text('Select a model and type a message below',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, index) {
                          final msg = chatState.messages[index];
                          final isLastAssistant = index == chatState.messages.length - 1 &&
                              msg.role == MessageRole.assistant;
                          return _MessageBubble(
                            message: msg,
                            phase: isLastAssistant ? chatState.phase : GenerationPhase.idle,
                          );
                        },
                      ),
              ),
              // Latency info bar
              if (chatState.timeToFirstToken != null ||
                  chatState.totalLatency != null)
                _LatencyBar(
                  ttft: chatState.timeToFirstToken,
                  totalLatency: chatState.totalLatency,
                ),
              // Last response metadata
              if (chatState.lastResponse != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ResponseMetadata(
                    model: chatState.lastResponse!.model,
                    latencyMs: chatState.lastResponse!.latencyMs,
                    promptTokens: chatState.lastResponse!.promptTokens,
                    completionTokens: chatState.lastResponse!.completionTokens,
                    totalTokens: chatState.lastResponse!.totalTokens,
                  ),
                ),
              if (chatState.lastResponse?.rawResponse != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child:
                      RawJsonViewer(data: chatState.lastResponse!.rawResponse),
                ),
              // Input bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey ==
                                  LogicalKeyboardKey.enter &&
                              !HardwareKeyboard.instance.isShiftPressed) {
                            _sendMessage();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextField(
                          controller: _inputController,
                          maxLines: 4,
                          minLines: 1,
                          decoration: const InputDecoration(
                            hintText: 'Type a message... (Enter to send, Shift+Enter for new line)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed:
                          chatState.isStreaming ? null : _sendMessage,
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Generation Status Badge (top bar) ───
class _GenerationStatusBadge extends StatefulWidget {
  final GenerationPhase phase;
  const _GenerationStatusBadge({required this.phase});

  @override
  State<_GenerationStatusBadge> createState() => _GenerationStatusBadgeState();
}

class _GenerationStatusBadgeState extends State<_GenerationStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isThinking = widget.phase == GenerationPhase.thinking;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isThinking
            ? colorScheme.tertiaryContainer
            : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final opacity = 0.4 + 0.6 * ((_controller.value * 2).clamp(0, 1));
              return Opacity(
                opacity: opacity,
                child: child,
              );
            },
            child: Icon(
              isThinking ? Icons.psychology : Icons.auto_awesome,
              size: 14,
              color: isThinking
                  ? colorScheme.onTertiaryContainer
                  : colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isThinking ? 'Thinking...' : 'Generating',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isThinking
                  ? colorScheme.onTertiaryContainer
                  : colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 4),
          _AnimatedDots(
            color: isThinking
                ? colorScheme.onTertiaryContainer
                : colorScheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }
}

// ─── Animated ellipsis dots ───
class _AnimatedDots extends StatefulWidget {
  final Color color;
  const _AnimatedDots({required this.color});

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final dotCount = (_controller.value * 3).floor().clamp(0, 3);
        return Text(
          '.' * dotCount,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: widget.color,
          ),
        );
      },
    );
  }
}

// ─── Message Bubble ───
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final GenerationPhase phase;
  const _MessageBubble({required this.message, this.phase = GenerationPhase.idle});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isThinking = phase == GenerationPhase.thinking && message.content.isEmpty;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.smart_toy,
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thinking state - show animated indicator
                    if (isThinking)
                      _ThinkingIndicator()
                    else if (isUser)
                      SelectableText(message.content)
                    else ...[
                      if (message.content.isNotEmpty)
                        GptMarkdown(message.content),
                      // Streaming cursor
                      if (message.isStreaming && message.content.isNotEmpty)
                        _StreamingCursor(),
                    ],
                    // Copy button for completed assistant messages
                    if (!isUser && !message.isStreaming && message.content.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: message.content));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy,
                                size: 12,
                                color: Theme.of(context).hintColor),
                            const SizedBox(width: 2),
                            Text('Copy',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).hintColor)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    Theme.of(context).colorScheme.tertiaryContainer,
                child: Icon(Icons.person,
                    size: 18,
                    color: Theme.of(context).colorScheme.onTertiaryContainer),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Thinking indicator with animated brain + text ───
class _ThinkingIndicator extends StatefulWidget {
  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Pulsing opacity effect
            final pulse = (1 + _controller.value * 0.5).clamp(0.5, 1.5);
            return Transform.scale(
              scale: pulse.clamp(0.9, 1.1),
              child: Opacity(
                opacity: (0.5 + 0.5 * (1 - _controller.value)).clamp(0.4, 1.0),
                child: child,
              ),
            );
          },
          child: Icon(
            Icons.psychology,
            size: 16,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Thinking',
          style: TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 2),
        _AnimatedDots(color: colorScheme.onSurfaceVariant),
      ],
    );
  }
}

// ─── Streaming cursor (blinking block) ───
class _StreamingCursor extends StatefulWidget {
  @override
  State<_StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<_StreamingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 2,
            height: 16,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }
}

// ─── Latency info bar ───
class _LatencyBar extends StatelessWidget {
  final Duration? ttft;
  final Duration? totalLatency;

  const _LatencyBar({this.ttft, this.totalLatency});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(
      fontSize: 11,
      color: colorScheme.onSurfaceVariant,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          if (ttft != null) ...[
            Icon(Icons.speed, size: 13, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('TTFT: ${ttft!.inMilliseconds}ms', style: textStyle),
            const SizedBox(width: 16),
          ],
          if (totalLatency != null) ...[
            Icon(Icons.timer_outlined, size: 13, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('Total: ${totalLatency!.inMilliseconds}ms', style: textStyle),
          ],
        ],
      ),
    );
  }
}
