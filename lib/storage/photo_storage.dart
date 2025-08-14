import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
//import 'package:flutter/material.dart'; // Offset is in here
import '../models/photo.dart';
//import '../models/spot.dart';

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

  static Future<void> updatePhoto(Photo updatedPhoto) async {
    final photos = await loadPhotos();
    final index = photos.indexWhere((photo) => photo.id == updatedPhoto.id);
    if (index != -1) {
      photos[index] = updatedPhoto;
      await savePhotos(photos);
      developer.log('Photo with ID ${updatedPhoto.id} updated', name: 'CameraScreen');
    }
  }

  static Future<void> updatePhotoAtIndex(int index, Photo updatedPhoto) async {
    final photos = await loadPhotos();
    if (index >= 0 && index < photos.length) {
      photos[index] = updatedPhoto;
      await savePhotos(photos);
    }
  }

  // Add this to PhotoStorage class for testing
  /* static Future<void> debugSpotSaving() async {
    // Create a test photo with spots
    final testPhoto = Photo(
      id: 'test_photo',
      path: '/test/path.jpg',
      dateTaken: DateTime.now(),
      spots: [
        Spot(position: Offset(100, 150), radius: 25.0, moleId: 'test_mole'),
      ],
    );
    
    // Save it
    await savePhotos([testPhoto]);
    
    // Load it back
    final loadedPhotos = await loadPhotos();
    final loadedPhoto = loadedPhotos.first;
    
    // Check if spots were preserved
    developer.log('Original spots: ${testPhoto.spots.length}', name: 'SpotTest');
    developer.log('Loaded spots: ${loadedPhoto.spots.length}', name: 'SpotTest');
    
    if (loadedPhoto.spots.isNotEmpty) {
      final spot = loadedPhoto.spots.first;
      developer.log('Spot position: ${spot.position}', name: 'SpotTest');
      developer.log('Spot moleId: ${spot.moleId}', name: 'SpotTest');
    }
  } */
}