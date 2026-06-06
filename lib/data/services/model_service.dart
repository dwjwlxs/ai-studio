import 'dart:convert';
import '../models/model_info.dart';
import 'bifrost_api_service.dart';
import '../../config/constants.dart';

class ModelService {
  final BifrostApiService _api;

  ModelService(this._api);

  Future<List<ModelInfo>> listModels({String? providerFilter}) async {
    final extraHeaders = <String, String>{};
    if (providerFilter != null) {
      extraHeaders['x-bf-list-models-provider'] = providerFilter;
    }

    final response = await _api.get(
      AppConstants.modelsEndpoint,
      extraHeaders: extraHeaders,
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final dataList = json['data'] as List<dynamic>? ?? [];

    return dataList.map((item) {
      final m = item as Map<String, dynamic>;
      final id = m['id'] as String? ?? '';
      return ModelInfo(
        id: id,
        name: m['name'] as String? ?? id,
        provider: _extractProvider(id),
      );
    }).toList();
  }

  String? _extractProvider(String modelId) {
    if (modelId.contains('/')) {
      return modelId.split('/').first;
    }
    return null;
  }
}
