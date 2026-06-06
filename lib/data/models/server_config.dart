class ServerConfig {
  final String gatewayUrl;
  final String apiKey;
  final bool isConfigured;

  const ServerConfig({
    this.gatewayUrl = 'http://localhost:8080',
    this.apiKey = '',
    this.isConfigured = false,
  });

  ServerConfig copyWith({
    String? gatewayUrl,
    String? apiKey,
    bool? isConfigured,
  }) =>
      ServerConfig(
        gatewayUrl: gatewayUrl ?? this.gatewayUrl,
        apiKey: apiKey ?? this.apiKey,
        isConfigured: isConfigured ?? this.isConfigured,
      );
}
