class ApiError implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  ApiError({
    required this.message,
    this.statusCode,
    this.responseBody,
  });

  @override
  String toString() => 'ApiError: $message (status: $statusCode)';
}
