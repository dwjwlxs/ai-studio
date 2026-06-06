import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';
import 'database_helper.dart';

class ChatDao {
  Future<Database> get _db => DatabaseHelper.instance.database;

  // ─── Conversations ───

  Future<void> insertConversation(Conversation conv) async {
    final db = await _db;
    await db.insert('conversations', conv.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateConversationTitle(String id, String title) async {
    final db = await _db;
    await db.update(
      'conversations',
      {
        'title': title,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateConversationTimestamp(String id) async {
    final db = await _db;
    await db.update(
      'conversations',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateConversationModel(String id, String model) async {
    final db = await _db;
    await db.update(
      'conversations',
      {
        'model': model,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteConversation(String id) async {
    final db = await _db;
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Conversation>> getAllConversations() async {
    final db = await _db;
    final rows = await db.query(
      'conversations',
      orderBy: 'updated_at DESC',
    );
    return rows.map((m) => Conversation.fromMap(m)).toList();
  }

  // ─── Messages ───

  Future<void> insertMessage(ChatMessage message, String conversationId,
      {required int sortOrder}) async {
    final db = await _db;
    await db.insert('chat_messages', {
      'conversation_id': conversationId,
      'role': message.role.name,
      'content': message.content,
      'timestamp': message.timestamp?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'sort_order': sortOrder,
    });
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final db = await _db;
    final rows = await db.query(
      'chat_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'sort_order ASC',
    );
    return rows
        .map((m) => ChatMessage.fromMap({
              ...m,
              'conversation_id': conversationId,
            }))
        .toList();
  }

  Future<void> deleteMessages(String conversationId) async {
    final db = await _db;
    await db.delete('chat_messages',
        where: 'conversation_id = ?', whereArgs: [conversationId]);
  }

  Future<int> getMessageCount(String conversationId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM chat_messages WHERE conversation_id = ?',
      [conversationId],
    );
    return result.first['count'] as int? ?? 0;
  }
}
