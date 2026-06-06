import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_error.dart';
import '../models/network_log_entry.dart';
import '../../config/constants.dart';

typedef NetworkLogCallback = void Function(NetworkLogEntry entry);

class BifrostApiService {
  String baseUrl;
  String? apiKey;

  /// Callback fired for every request/response pair.
  /// Used by the Network Inspector to capture traffic.
  NetworkLogCallback? onNetworkLog;

  BifrostApiService({
    required this.baseUrl,
    this.apiKey,
  }) : _client = http.Client();

  final http.Client _client;

  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (apiKey != null && apiKey!.isNotEmpty) {
      h['Authorization'] = 'Bearer $apiKey';
    }
    return h;
  }

  void updateConfig({required String url, String? key}) {
    baseUrl = url;
    apiKey = key;
  }

  int _logCounter = 0;
  String _nextId() => '${++_logCounter}';

  Future<http.Response> get(
    String path, {
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {..._headers, ...?extraHeaders};
    final sw = Stopwatch()..start();
    http.Response? response;
    Object? caughtError;
    try {
      response = await _client
          .get(uri, headers: headers)
          .timeout(AppConstants.defaultTimeout);
      _checkResponse(response);
      return response;
    } catch (e) {
      caughtError = e;
      if (e is ApiError) rethrow;
      throw ApiError(message: 'Connection failed: $e');
    } finally {
      sw.stop();
      _emitLog(
        id: _nextId(),
        method: 'GET',
        url: uri.toString(),
        requestHeaders: headers,
        requestBody: null,
        response: response,
        duration: sw.elapsed,
        caughtError: caughtError,
      );
    }
  }

  Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {..._headers, ...?extraHeaders};
    final encodedBody = jsonEncode(body);
    final sw = Stopwatch()..start();
    http.Response? response;
    Object? caughtError;
    try {
      response = await _client
          .post(uri, headers: headers, body: encodedBody)
          .timeout(AppConstants.defaultTimeout);
      _checkResponse(response);
      return response;
    } catch (e) {
      caughtError = e;
      if (e is ApiError) rethrow;
      throw ApiError(message: 'Request failed: $e');
    } finally {
      sw.stop();
      _emitLog(
        id: _nextId(),
        method: 'POST',
        url: uri.toString(),
        requestHeaders: headers,
        requestBody: encodedBody,
        response: response,
        duration: sw.elapsed,
        caughtError: caughtError,
      );
    }
  }

  Future<http.StreamedResponse> postStream(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request('POST', uri);
    request.headers.addAll(_headers);
    final encodedBody = jsonEncode(body);
    request.body = encodedBody;
    final sw = Stopwatch()..start();
    try {
      final response = await _client.send(request);
      sw.stop();
      // Log the stream initiation (response body arrives over time)
      onNetworkLog?.call(NetworkLogEntry(
        id: _nextId(),
        method: 'POST',
        url: uri.toString(),
        requestHeaders: Map<String, String>.from(request.headers),
        requestBody: encodedBody,
        statusCode: response.statusCode,
        responseHeaders: _streamedHeaders(response),
        responseBody: '[streaming response]',
        duration: sw.elapsed,
        timestamp: DateTime.now(),
        isStreaming: true,
      ));
      return response;
    } catch (e) {
      sw.stop();
      onNetworkLog?.call(NetworkLogEntry(
        id: _nextId(),
        method: 'POST',
        url: uri.toString(),
        requestHeaders: Map<String, String>.from(request.headers),
        requestBody: encodedBody,
        statusCode: null,
        responseBody: null,
        duration: sw.elapsed,
        timestamp: DateTime.now(),
        isStreaming: true,
        error: e.toString(),
      ));
      throw ApiError(message: 'Stream request failed: $e');
    }
  }

  Future<http.StreamedResponse> getStream(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request('GET', uri);
    request.headers.addAll(_headers);
    final sw = Stopwatch()..start();
    try {
      final response = await _client.send(request);
      sw.stop();
      onNetworkLog?.call(NetworkLogEntry(
        id: _nextId(),
        method: 'GET',
        url: uri.toString(),
        requestHeaders: Map<String, String>.from(request.headers),
        requestBody: null,
        statusCode: response.statusCode,
        responseHeaders: _streamedHeaders(response),
        responseBody: '[streaming response]',
        duration: sw.elapsed,
        timestamp: DateTime.now(),
        isStreaming: true,
      ));
      return response;
    } catch (e) {
      sw.stop();
      onNetworkLog?.call(NetworkLogEntry(
        id: _nextId(),
        method: 'GET',
        url: uri.toString(),
        requestHeaders: Map<String, String>.from(request.headers),
        requestBody: null,
        statusCode: null,
        responseBody: null,
        duration: sw.elapsed,
        timestamp: DateTime.now(),
        isStreaming: true,
        error: e.toString(),
      ));
      throw ApiError(message: 'Stream request failed: $e');
    }
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 400) {
      throw ApiError(
        message: 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
  }

  void _emitLog({
    required String id,
    required String method,
    required String url,
    required Map<String, String> requestHeaders,
    required String? requestBody,
    required http.Response? response,
    required Duration duration,
    required Object? caughtError,
  }) {
    final entry = NetworkLogEntry(
      id: id,
      method: method,
      url: url,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      statusCode: response?.statusCode,
      responseHeaders: response != null
          ? _responseHeaders(response)
          : null,
      responseBody: response?.body,
      duration: duration,
      timestamp: DateTime.now(),
      error: caughtError != null && response == null
          ? caughtError.toString()
          : (caughtError is ApiError ? caughtError.responseBody : null),
    );
    onNetworkLog?.call(entry);
  }

  Map<String, String> _responseHeaders(http.Response response) {
    return response.headers;
  }

  Map<String, String> _streamedHeaders(http.StreamedResponse response) {
    return response.headers;
  }

  void dispose() {
    _client.close();
  }
}
