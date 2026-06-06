class PersistedImage {
  final int? id;
  final String prompt;
  final String model;
  final String size;
  final String? revisedPrompt;
  final String localFilePath;
  final String? sourceUrl;
  final DateTime createdAt;

  const PersistedImage({
    this.id,
    required this.prompt,
    this.model = '',
    this.size = '1024x1024',
    this.revisedPrompt,
    required this.localFilePath,
    this.sourceUrl,
    required this.createdAt,
  });

  factory PersistedImage.fromMap(Map<String, dynamic> map) => PersistedImage(
        id: map['id'] as int?,
        prompt: map['prompt'] as String,
        model: map['model'] as String? ?? '',
        size: map['size'] as String? ?? '1024x1024',
        revisedPrompt: map['revised_prompt'] as String?,
        localFilePath: map['local_file_path'] as String,
        sourceUrl: map['source_url'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'prompt': prompt,
        'model': model,
        'size': size,
        'revised_prompt': revisedPrompt,
        'local_file_path': localFilePath,
        'source_url': sourceUrl,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}
