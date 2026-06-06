import 'bifrost_api_service.dart';
import '../../config/constants.dart';

class HealthService {
  final BifrostApiService _api;

  HealthService(this._api);

  Future<bool> checkConnection() async {
    try {
      await _api.get(AppConstants.healthEndpoint);
      return true;
    } catch (_) {
      return false;
    }
  }
}
