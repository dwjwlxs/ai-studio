class ImageGenerationRequest {
  final String model;
  final String prompt;
  final String size;
  final String responseFormat;
  final int? n;
  final String? quality;
  final String? style;
  final String? background;
  final String? moderation;
  final String? outputFormat;
  final int? outputCompression;
  final int? partialImages;
  final int? seed;
  final String? negativePrompt;
  final int? numInferenceSteps;

  const ImageGenerationRequest({
    required this.model,
    required this.prompt,
    this.size = '1024x1024',
    this.responseFormat = 'url',
    this.n,
    this.quality,
    this.style,
    this.background,
    this.moderation,
    this.outputFormat,
    this.outputCompression,
    this.partialImages,
    this.seed,
    this.negativePrompt,
    this.numInferenceSteps,
  });
}
