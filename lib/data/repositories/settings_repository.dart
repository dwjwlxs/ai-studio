import 'package:shared_preferences/shared_preferences.dart';
import '../models/server_config.dart';

class SettingsRepository {
  static const _keyGatewayUrl = 'gateway_url';
  static const _keyApiKey = 'api_key';
  static const _keyThemeMode = 'theme_mode';
  static const _keyPrefixModel = 'selected_model_';

  Future<ServerConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_keyGatewayUrl) ?? 'http://localhost:8080';
    final apiKey = prefs.getString(_keyApiKey) ?? '';
    return ServerConfig(
      gatewayUrl: url,
      apiKey: apiKey,
      isConfigured: url.isNotEmpty,
    );
  }

  Future<void> saveConfig(ServerConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGatewayUrl, config.gatewayUrl);
    await prefs.setString(_keyApiKey, config.apiKey);
  }

  Future<String> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  Future<String?> loadSelectedModel(String page) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyPrefixModel$page');
  }

  Future<void> saveSelectedModel(String page, String? model) async {
    final prefs = await SharedPreferences.getInstance();
    if (model == null) {
      await prefs.remove('$_keyPrefixModel$page');
    } else {
      await prefs.setString('$_keyPrefixModel$page', model);
    }
  }
}
