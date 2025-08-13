import 'dart:ui';
import 'package:flutter/material.dart';

/// Represents a marked spot on a mole photo.
/// 
/// Each spot has a position (x,y coordinates) and a radius for display.
/// Spots are used to mark areas of interest on mole photos for tracking
/// changes over time.
/// 
/// Example:
/// ```dart
/// final spot = Spot(
///   position: Offset(100, 150),
///   radius: 25.0,
/// );
/// ```
class Spot {
  /// The position of the spot on the image in pixels.
  /// 
  /// Uses Flutter's [Offset] class where dx is the x-coordinate
  /// and dy is the y-coordinate from the top-left corner.
  Offset position;
  
  /// The radius of the spot marker in pixels.
  /// 
  /// This determines how large the circular marker appears
  /// when drawn on the photo. Typical values range from 10-50 pixels.
  double radius;
  
  /// Creates a new spot with the specified [position] and [radius].
  /// 
  /// Both parameters are required.
  Spot({required this.position, required this.radius});

  /// Converts this spot to a JSON map for storage.
  /// 
  /// Returns a map containing the x,y coordinates and radius.
  /// Used for persisting spots to local storage.
  Map<String, dynamic> toJson() => {
    'dx': position.dx,
    'dy': position.dy,
    'radius': radius,
  };

  /// Creates a spot from a JSON map.
  /// 
  /// Expects a map with 'dx', 'dy', and 'radius' keys.
  /// Used for loading spots from local storage.
  factory Spot.fromJson(Map<String, dynamic> json) => Spot(
    position: Offset(json['dx'], json['dy']),
    radius: json['radius'],
  );
}

/// Represents a mole photograph with associated metadata and markings.
/// 
/// Each photo contains:
/// - Unique identification
/// - File system path to the image
/// - Timestamp of when it was taken
/// - User-assigned name for the mole
/// - List of marked spots for tracking changes
/// 
/// Photos are the core data structure of the nevus app, allowing users
/// to document and track their moles over time.
/// 
/// Example:
/// ```dart
/// final photo = Photo(
///   id: 'photo_123456789',
///   path: '/storage/images/mole_photo.jpg',
///   dateTaken: DateTime.now(),
///   moleName: 'Mole on left shoulder',
/// );
/// ```
class Photo {
  /// Unique identifier for this photo.
  /// 
  /// Generated when the photo is created, typically using a timestamp
  /// or UUID. Used for referencing this photo in storage and UI operations.
  final String id;
  
  /// File system path where the image is stored.
  /// 
  /// Points to the actual image file on the device's storage.
  /// Used for loading and displaying the photo in the UI.
  final String path;
  
  /// The date and time when this photo was taken.
  /// 
  /// Automatically set when the photo is captured. Used for:
  /// - Displaying capture time to users
  /// - Sorting photos chronologically
  /// - Tracking mole changes over time
  final DateTime dateTaken;
  
  /// User-assigned name for the mole in this photo.
  /// 
  /// Can be empty initially and edited later by the user.
  /// Examples: "Mole on back", "Suspicious spot on arm", etc.
  final String moleName;
  
  /// List of spots marked on this photo.
  /// 
  /// Users can add circular markers to highlight areas of interest
  /// on the mole photo. These spots persist with the photo and can
  /// be used to track changes over time.
  List<Spot> spots;

  /// Creates a new photo with the specified metadata.
  /// 
  /// The [spots] parameter is optional and defaults to an empty list
  /// if not provided. Spots can be added later through the UI.
  /// 
  /// All other parameters are required for proper photo management.
  Photo({
    required this.id,
    required this.path,
    required this.dateTaken,
    required this.moleName,
    List<Spot>? spots,
  }) : spots = spots ?? [];

  /// Converts this photo to a JSON map for storage.
  /// 
  /// Serializes all photo data including metadata and spots
  /// to a format suitable for local storage. The [dateTaken]
  /// DateTime is converted to ISO 8601 string format.
  /// 
  /// Returns a map that can be encoded to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'dateTaken': dateTaken.toIso8601String(),
    'moleName': moleName,
    'spots': spots.map((s) => s.toJson()).toList(),
  };

  /// Creates a photo from a JSON map.
  /// 
  /// Deserializes photo data from storage format back to a Photo object.
  /// The date string is parsed back to a DateTime object, and spots
  /// are reconstructed from their JSON representations.
  /// 
  /// Expects a map with all required fields. Missing spots will
  /// default to an empty list.
  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
    id: json['id'],
    path: json['path'],
    dateTaken: DateTime.parse(json['dateTaken']),
    moleName: json['moleName'],
    spots: (json['spots'] as List<dynamic>?)
        ?.map((s) => Spot.fromJson(s))
        .toList() ?? [],
  );
}