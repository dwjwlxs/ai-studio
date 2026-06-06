import 'dart:async';
import 'dart:convert';
import '../models/chat_completion_request.dart';
import '../models/chat_completion_response.dart';
import '../models/api_error.dart';
import 'bifrost_api_service.dart';
import '../../config/constants.dart';

class ChatService {
  final BifrostApiService _api;

  ChatService(this._api);

  Future<ChatCompletionResponse> complete(ChatCompletionRequest request) async {
    final stopwatch = Stopwatch()..start();
    final body = <String, dynamic>{
      'model': request.model,
      'messages': request.messages,
      'stream': false,
    };
    if (request.temperature != null) body['temperature'] = request.temperature;
    if (request.maxTokens != null) body['max_tokens'] = request.maxTokens;
    if (request.topP != null) body['top_p'] = request.topP;

    final response = await _api.post(
      AppConstants.chatCompletionsEndpoint,
      body,
    );
    stopwatch.stop();

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        json['choices']?[0]?['message']?['content'] as String? ?? '';
    final usage = json['usage'] as Map<String, dynamic>?;

    return ChatCompletionResponse(
      content: content,
      model: json['model'] as String?,
      promptTokens: usage?['prompt_tokens'] as int? ?? 0,
      completionTokens: usage?['completion_tokens'] as int? ?? 0,
      totalTokens: usage?['total_tokens'] as int? ?? 0,
      latencyMs: stopwatch.elapsedMilliseconds,
      rawResponse: json,
    );
  }

  Stream<String> completeStream(ChatCompletionRequest request) async* {
    final body = <String, dynamic>{
      'model': request.model,
      'messages': request.messages,
      'stream': true,
    };
    if (request.temperature != null) body['temperature'] = request.temperature;
    if (request.maxTokens != null) body['max_tokens'] = request.maxTokens;
    if (request.topP != null) body['top_p'] = request.topP;

    final streamedResponse = await _api.postStream(
      AppConstants.chatCompletionsEndpoint,
      body,
    );

    if (streamedResponse.statusCode >= 400) {
      final body = await streamedResponse.stream.bytesToString();
      throw ApiError(
        message: 'HTTP ${streamedResponse.statusCode}',
        statusCode: streamedResponse.statusCode,
        responseBody: body,
      );
    }

    String buffer = '';
    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      buffer += chunk;
      final lines = buffer.split('\n');
      buffer = lines.removeLast(); // keep incomplete line in buffer

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed == 'data: [DONE]') return;
        if (trimmed.startsWith('data: ')) {
          final dataStr = trimmed.substring(6);
          try {
            final data = jsonDecode(dataStr) as Map<String, dynamic>;
            final delta = data['choices']?[0]?['delta']?['content'];
            if (delta != null && delta is String && delta.isNotEmpty) {
              yield delta;
            }
          } catch (_) {
            // Skip malformed JSON chunks
          }
        }
      }
    }
  }
}
