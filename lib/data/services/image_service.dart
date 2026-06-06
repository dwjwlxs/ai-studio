import 'dart:convert';
import '../models/image_generation_request.dart';
import '../models/image_generation_response.dart';
import 'bifrost_api_service.dart';
import '../../config/constants.dart';

class ImageService {
  final BifrostApiService _api;

  ImageService(this._api);

  Future<ImageGenerationResponse> generate(ImageGenerationRequest request,
      {Map<String, dynamic>? rawResponse}) async {
    final stopwatch = Stopwatch()..start();
    final body = <String, dynamic>{
      'model': request.model,
      'prompt': request.prompt,
      'size': request.size,
      'response_format': request.responseFormat,
    };
    if (request.n != null) body['n'] = request.n;
    if (request.quality != null) body['quality'] = request.quality;
    if (request.style != null) body['style'] = request.style;
    if (request.background != null) body['background'] = request.background;
    if (request.moderation != null) body['moderation'] = request.moderation;
    if (request.outputFormat != null) {
      body['output_format'] = request.outputFormat;
    }
    if (request.outputCompression != null) {
      body['output_compression'] = request.outputCompression;
    }
    if (request.partialImages != null) {
      body['partial_images'] = request.partialImages;
    }
    if (request.seed != null) body['seed'] = request.seed;
    if (request.negativePrompt != null &&
        request.negativePrompt!.isNotEmpty) {
      body['negative_prompt'] = request.negativePrompt;
    }
    if (request.numInferenceSteps != null) {
      body['num_inference_steps'] = request.numInferenceSteps;
    }

    final response = await _api.post(
      AppConstants.imageGenerationsEndpoint,
      body,
    );
    stopwatch.stop();

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final dataList = json['data'] as List<dynamic>? ?? [];

    final images = dataList.map((item) {
      final m = item as Map<String, dynamic>;
      return GeneratedImage(
        url: m['url'] as String?,
        b64Json: m['b64_json'] as String?,
        revisedPrompt: m['revised_prompt'] as String?,
      );
    }).toList();

    return ImageGenerationResponse(
      images: images,
      latencyMs: stopwatch.elapsedMilliseconds,
      rawResponse: json,
    );
  }
}
