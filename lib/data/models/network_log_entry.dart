class NetworkLogEntry {
  final String id;
  final String method;
  final String url;
  final Map<String, String> requestHeaders;
  final String? requestBody;
  final int? statusCode;
  final Map<String, String>? responseHeaders;
  final String? responseBody;
  final Duration duration;
  final DateTime timestamp;
  final String? error;
  final bool isStreaming;

  const NetworkLogEntry({
    required this.id,
    required this.method,
    required this.url,
    required this.requestHeaders,
    this.requestBody,
    this.statusCode,
    this.responseHeaders,
    this.responseBody,
    required this.duration,
    required this.timestamp,
    this.error,
    this.isStreaming = false,
  });
}
