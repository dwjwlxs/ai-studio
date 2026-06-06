class GeneratedImage {
  final String? url;
  final String? b64Json;
  final String? revisedPrompt;

  const GeneratedImage({
    this.url,
    this.b64Json,
    this.revisedPrompt,
  });
}

class ImageGenerationResponse {
  final List<GeneratedImage> images;
  final int latencyMs;
  final Map<String, dynamic>? rawResponse;

  const ImageGenerationResponse({
    required this.images,
    this.latencyMs = 0,
    this.rawResponse,
  });
}
