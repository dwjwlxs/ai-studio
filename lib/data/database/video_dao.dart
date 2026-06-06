import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/video_job.dart';
import 'database_helper.dart';

class VideoDao {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<int> insertVideo(VideoJob job) async {
    final db = await _db;
    return await db.insert('generated_videos', job.toMap());
  }

  Future<void> updateVideoStatus(
    String jobId, {
    String? status,
    String? localFilePath,
    String? error,
    String? resultUrl,
  }) async {
    final db = await _db;
    final values = <String, Object?>{};
    if (status != null) values['status'] = status;
    if (localFilePath != null) values['local_file_path'] = localFilePath;
    if (error != null) values['error'] = error;
    if (resultUrl != null) values['result_url'] = resultUrl;
    if (values.isNotEmpty) {
      await db.update(
        'generated_videos',
        values,
        where: 'job_id = ?',
        whereArgs: [jobId],
      );
    }
  }

  Future<List<VideoJob>> getAllVideos() async {
    final db = await _db;
    final rows = await db.query(
      'generated_videos',
      orderBy: 'created_at DESC',
    );
    return rows.map((m) => VideoJob.fromMap(m)).toList();
  }

  Future<void> deleteVideo(int id) async {
    final db = await _db;
    await db.delete('generated_videos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteVideoByJobId(String jobId) async {
    final db = await _db;
    await db.delete('generated_videos',
        where: 'job_id = ?', whereArgs: [jobId]);
  }

  Future<List<VideoJob>> getIncompleteVideos() async {
    final db = await _db;
    final rows = await db.query(
      'generated_videos',
      where: 'status IN (?, ?)',
      whereArgs: ['pending', 'processing'],
    );
    return rows.map((m) => VideoJob.fromMap(m)).toList();
  }
}
