import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileStorageService {
  final _uuid = const Uuid();

  Future<String> saveImageFromUrl(String url, {String? filename}) async {
    final dir = await _getImageDir();
    final name = filename ?? _uuid.v4();
    final filePath = p.join(dir.path, '$name.png');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to download image: HTTP ${response.statusCode}');
    }
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  Future<String> saveImageFromBase64(String b64Json, {String? filename}) async {
    final dir = await _getImageDir();
    final name = filename ?? _uuid.v4();
    final filePath = p.join(dir.path, '$name.png');
    final bytes = base64Decode(b64Json);
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  Future<String> saveVideoFromUrl(String url, {String? filename}) async {
    final dir = await _getVideoDir();
    final name = filename ?? _uuid.v4();
    final filePath = p.join(dir.path, '$name.mp4');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to download video: HTTP ${response.statusCode}');
    }
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  Future<Directory> _getImageDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'ai_studio', 'images'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _getVideoDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'ai_studio', 'videos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
