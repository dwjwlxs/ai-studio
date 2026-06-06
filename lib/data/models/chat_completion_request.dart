class ChatCompletionRequest {
  final String model;
  final List<Map<String, String>> messages;
  final bool stream;
  final double? temperature;
  final int? maxTokens;
  final double? topP;

  const ChatCompletionRequest({
    required this.model,
    required this.messages,
    this.stream = false,
    this.temperature,
    this.maxTokens,
    this.topP,
  });
}
