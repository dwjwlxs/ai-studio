import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/persisted_image.dart';
import 'database_helper.dart';

class ImageDao {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<int> insertImage(PersistedImage image) async {
    final db = await _db;
    return await db.insert('generated_images', image.toMap());
  }

  Future<List<PersistedImage>> getAllImages() async {
    final db = await _db;
    final rows = await db.query(
      'generated_images',
      orderBy: 'created_at DESC',
    );
    return rows.map((m) => PersistedImage.fromMap(m)).toList();
  }

  Future<void> deleteImage(int id) async {
    final db = await _db;
    await db.delete('generated_images', where: 'id = ?', whereArgs: [id]);
  }
}
