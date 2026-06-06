enum MessageRole { user, assistant, system }

class ChatMessage {
  final int? id;
  final String? conversationId;
  final MessageRole role;
  final String content;
  final DateTime? timestamp;
  final bool isStreaming;

  const ChatMessage({
    this.id,
    this.conversationId,
    required this.role,
    required this.content,
    this.timestamp,
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    int? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        role: role ?? this.role,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
        isStreaming: isStreaming ?? this.isStreaming,
      );

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'] as int?,
        conversationId: map['conversation_id'] as String?,
        role: _parseRole(map['role'] as String),
        content: map['content'] as String? ?? '',
        timestamp: map['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
            : null,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'conversation_id': conversationId,
        'role': role.name,
        'content': content,
        'timestamp': timestamp?.millisecondsSinceEpoch ?? 0,
      };

  static MessageRole _parseRole(String s) {
    switch (s) {
      case 'user':
        return MessageRole.user;
      case 'system':
        return MessageRole.system;
      default:
        return MessageRole.assistant;
    }
  }
}
