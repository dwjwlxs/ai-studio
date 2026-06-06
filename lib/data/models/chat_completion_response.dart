class ChatCompletionResponse {
  final String content;
  final String? model;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final int latencyMs;
  final Map<String, dynamic>? rawResponse;

  const ChatCompletionResponse({
    required this.content,
    this.model,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
    this.latencyMs = 0,
    this.rawResponse,
  });
}
