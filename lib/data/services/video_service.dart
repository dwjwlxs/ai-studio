import 'dart:convert';
import '../models/video_job.dart';
import 'bifrost_api_service.dart';
import '../../config/constants.dart';

class VideoService {
  final BifrostApiService _api;

  VideoService(this._api);

  Future<VideoJob> submitJob(
    String prompt,
    String model, {
    String? seconds,
    String? size,
    String? negativePrompt,
    int? seed,
    String? inputReference,
    String? videoUri,
    bool? audio,
  }) async {
    final stopwatch = Stopwatch()..start();
    final body = <String, dynamic>{
      'prompt': prompt,
      'model': model,
    };
    if (seconds != null && seconds.isNotEmpty) body['seconds'] = seconds;
    if (size != null && size.isNotEmpty) body['size'] = size;
    if (negativePrompt != null && negativePrompt.isNotEmpty) {
      body['negative_prompt'] = negativePrompt;
    }
    if (seed != null) body['seed'] = seed;
    if (inputReference != null && inputReference.isNotEmpty) {
      body['input_reference'] = inputReference;
    }
    if (videoUri != null && videoUri.isNotEmpty) body['video_uri'] = videoUri;
    if (audio != null) body['audio'] = audio;

    final response = await _api.post(
      AppConstants.videosEndpoint,
      body,
    );
    stopwatch.stop();

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return VideoJob(
      id: json['id'] as String? ?? '',
      prompt: prompt,
      model: model,
      status: _parseStatus(json['status'] as String?),
      resultUrl: json['url'] as String?,
      latencyMs: stopwatch.elapsedMilliseconds,
      rawResponse: json,
    );
  }

  Future<VideoJob> pollStatus(VideoJob job) async {
    final response = await _api.get('${AppConstants.videosEndpoint}/${job.id}');
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Extract video URL: check videos[0].url first (per API spec), then fallback
    String? videoUrl = job.resultUrl;
    final videos = json['videos'];
    if (videos is List && videos.isNotEmpty) {
      final firstVideo = videos[0];
      if (firstVideo is Map<String, dynamic>) {
        videoUrl = firstVideo['url'] as String? ?? videoUrl;
      }
    }
    videoUrl =
        json['url'] as String? ?? json['content_url'] as String? ?? videoUrl;

    // Extract error message from error object or string
    String? errorMsg;
    final errorField = json['error'];
    if (errorField is Map<String, dynamic>) {
      errorMsg = errorField['message'] as String?;
    } else if (errorField is String) {
      errorMsg = errorField;
    }

    return job.copyWith(
      status: _parseStatus(json['status'] as String?),
      resultUrl: videoUrl,
      error: errorMsg,
      rawResponse: json,
    );
  }

  String getContentUrl(String jobId) {
    return '${_api.baseUrl}${AppConstants.videosEndpoint}/$jobId/content';
  }

  VideoJobStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return VideoJobStatus.pending;
      case 'processing':
      case 'in_progress':
        return VideoJobStatus.processing;
      case 'complete':
      case 'completed':
      case 'succeeded':
        return VideoJobStatus.complete;
      case 'failed':
        return VideoJobStatus.failed;
      default:
        return VideoJobStatus.unknown;
    }
  }
}
