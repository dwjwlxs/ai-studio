enum VideoJobStatus { pending, processing, complete, failed, cancelled, unknown }

class VideoJob {
  final String id;
  final String prompt;
  final String model;
  final VideoJobStatus status;
  final String? resultUrl;
  final String? localFilePath;
  final String? error;
  final int latencyMs;
  final Map<String, dynamic>? rawResponse;
  final DateTime? createdAt;

  const VideoJob({
    required this.id,
    required this.prompt,
    required this.model,
    this.status = VideoJobStatus.pending,
    this.resultUrl,
    this.localFilePath,
    this.error,
    this.latencyMs = 0,
    this.rawResponse,
    this.createdAt,
  });

  VideoJob copyWith({
    String? id,
    String? prompt,
    String? model,
    VideoJobStatus? status,
    String? resultUrl,
    String? localFilePath,
    String? error,
    int? latencyMs,
    Map<String, dynamic>? rawResponse,
    DateTime? createdAt,
  }) =>
      VideoJob(
        id: id ?? this.id,
        prompt: prompt ?? this.prompt,
        model: model ?? this.model,
        status: status ?? this.status,
        resultUrl: resultUrl ?? this.resultUrl,
        localFilePath: localFilePath ?? this.localFilePath,
        error: error ?? this.error,
        latencyMs: latencyMs ?? this.latencyMs,
        rawResponse: rawResponse ?? this.rawResponse,
        createdAt: createdAt ?? this.createdAt,
      );

  factory VideoJob.fromMap(Map<String, dynamic> map) => VideoJob(
        id: map['job_id'] as String? ?? '',
        prompt: map['prompt'] as String? ?? '',
        model: map['model'] as String? ?? '',
        status: _parseStatus(map['status'] as String?),
        resultUrl: map['result_url'] as String?,
        localFilePath: map['local_file_path'] as String?,
        error: map['error'] as String?,
        createdAt: map['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
            : null,
      );

  Map<String, dynamic> toMap() => {
        'job_id': id,
        'prompt': prompt,
        'model': model,
        'status': status.name,
        'result_url': resultUrl,
        'local_file_path': localFilePath,
        'error': error,
        'created_at': createdAt?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
      };

  static VideoJobStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return VideoJobStatus.pending;
      case 'processing':
        return VideoJobStatus.processing;
      case 'complete':
      case 'completed':
      case 'succeeded':
        return VideoJobStatus.complete;
      case 'failed':
        return VideoJobStatus.failed;
      case 'cancelled':
      case 'canceled':
        return VideoJobStatus.cancelled;
      default:
        return VideoJobStatus.unknown;
    }
  }
}
