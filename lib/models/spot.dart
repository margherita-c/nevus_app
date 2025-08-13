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