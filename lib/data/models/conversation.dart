class Conversation {
  final String id;
  final String title;
  final String model;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    this.title = '',
    this.model = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Conversation copyWith({
    String? id,
    String? title,
    String? model,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Conversation(
        id: id ?? this.id,
        title: title ?? this.title,
        model: model ?? this.model,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory Conversation.fromMap(Map<String, dynamic> map) => Conversation(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        model: map['model'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'model': model,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };
}
