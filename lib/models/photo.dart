import 'spot.dart';

/// Represents a mole photograph with associated metadata and markings.
/// 
/// Each photo contains:
/// - Unique identification
/// - File system path to the image
/// - Timestamp of when it was taken
/// - Body region description
/// - Campaign association
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
  final String relativePath;
  
  /// The date and time when this photo was taken.
  /// 
  /// Automatically set when the photo is captured. Used for:
  /// - Displaying capture time to users
  /// - Sorting photos chronologically
  /// - Tracking mole changes over time
  final DateTime dateTaken;

  /// Indicates whether this photo is a template for future photos.
  /// If true, this photo can be used as a starting point for a new photo of the same body part.
  /// It's used as a reference for creating consistent follow-up photos,
  /// when creating a new campaign based on an older one.
  final bool isTemplate;
  
  /// Description of which body region this photo represents.
  /// 
  /// Examples: "Left shoulder", "Upper back", "Right arm", "Chest", etc.
  /// This helps users organize and identify photos by body location.
  final String description;
  
  /// NOTE: Campaign association is stored in the `Campaign.photoIds` list.
  /// The `Photo` model no longer stores `campaignId` to avoid duplicated state.
  
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
    required this.relativePath,
    required this.dateTaken,
    this.isTemplate = false,
  required this.description,
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
    'relativePath': relativePath,
    'dateTaken': dateTaken.toIso8601String(),
    'isTemplate': isTemplate,
    'description': description,
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
    relativePath: json['relativePath'],
    dateTaken: DateTime.parse(json['dateTaken']),
    isTemplate: json['isTemplate'] ?? false,
    description: json['description'] ?? '',
    // Older JSON files may still contain a campaignId field; we ignore it
    spots: (json['spots'] as List<dynamic>?)
        ?.map((s) => Spot.fromJson(s))
        .toList() ?? [],
  );
}