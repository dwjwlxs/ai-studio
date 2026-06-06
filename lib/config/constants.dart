class AppConstants {
  AppConstants._();

  static const String defaultGatewayUrl = 'http://localhost:8080';
  static const String healthEndpoint = '/health';
  static const String modelsEndpoint = '/v1/models';
  static const String chatCompletionsEndpoint = '/v1/chat/completions';
  static const String imageGenerationsEndpoint = '/v1/images/generations';
  static const String videosEndpoint = '/v1/videos';
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration videoPollInterval = Duration(seconds: 5);
  static const double minWindowWidth = 1000;
  static const double minWindowHeight = 700;
}
