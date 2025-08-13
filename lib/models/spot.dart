import 'package:flutter/material.dart';

/// Represents a marked spot on a mole photo.
/// 
/// Each spot has a position (x,y coordinates), a radius for display,
/// and an identifier for the specific mole being marked.
/// Spots are used to mark areas of interest on mole photos for tracking
/// changes over time.
/// 
/// Example:
/// ```dart
/// final spot = Spot(
///   position: Offset(100, 150),
///   radius: 25.0,
///   moleId: 'mole_shoulder_left_01',
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
  
  /// Unique identifier for the mole being marked by this spot.
  /// 
  /// This string helps identify which specific mole this spot represents,
  /// allowing for tracking the same mole across multiple photos and sessions.
  /// Examples: "mole_back_center", "suspicious_spot_arm", "birthmark_leg_01"
  String moleId;
  
  /// Creates a new spot with the specified [position], [radius], and [moleId].
  /// 
  /// All parameters are required for proper mole identification and tracking.
  Spot({
    required this.position, 
    required this.radius,
    required this.moleId,
  });

  /// Converts this spot to a JSON map for storage.
  /// 
  /// Returns a map containing the x,y coordinates, radius, and mole identifier.
  /// Used for persisting spots to local storage.
  Map<String, dynamic> toJson() => {
    'dx': position.dx,
    'dy': position.dy,
    'radius': radius,
    'moleId': moleId,
  };

  /// Creates a spot from a JSON map.
  /// 
  /// Expects a map with 'dx', 'dy', 'radius', and 'moleId' keys.
  /// Used for loading spots from local storage.
  factory Spot.fromJson(Map<String, dynamic> json) => Spot(
    position: Offset(json['dx'], json['dy']),
    radius: json['radius'],
    moleId: json['moleId'],
  );
}