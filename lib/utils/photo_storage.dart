import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/photo.dart';

class PhotoStorage {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/photos.json');
  }

  static Future<void> savePhotos(List<Photo> photos) async {
    final file = await _localFile;
    final jsonList = photos.map((p) => p.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
    developer.log('Photo saved successfully', name: 'CameraScreen');
  }

  static Future<List<Photo>> loadPhotos() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return [];
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((json) => Photo.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}