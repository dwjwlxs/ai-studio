import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  Database? _db;
  static const _dbName = 'ai_studio.db';
  static const _dbVersion = 1;

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<void> initialize() async {
    // Initialize FFI for desktop platforms
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    await database;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL DEFAULT '',
        model TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL DEFAULT '',
        timestamp INTEGER NOT NULL,
        sort_order INTEGER NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_msg_conv ON chat_messages(conversation_id, sort_order)
    ''');
    await db.execute('''
      CREATE TABLE generated_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prompt TEXT NOT NULL,
        model TEXT NOT NULL DEFAULT '',
        size TEXT NOT NULL DEFAULT '1024x1024',
        revised_prompt TEXT,
        local_file_path TEXT NOT NULL,
        source_url TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE generated_videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id TEXT NOT NULL,
        prompt TEXT NOT NULL,
        model TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'pending',
        result_url TEXT,
        local_file_path TEXT,
        error TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
  }
}
