import 'photo.dart';

class Mole {
  final String id;
  final String name;
  final String description;

  Mole({
    required this.id,
    required this.name,
    required this.description,
  });

  /// Converts this mole to a JSON map for storage.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };

  /// Creates a mole from a JSON map.
  factory Mole.fromJson(Map<String, dynamic> json) => Mole(
    id: json['id'],
    name: json['name'],
    description: json['description'],
  );

  /// Retrieves all photos where this mole appears.
  /// 
  /// Searches through all campaigns and photos to find spots
  /// that reference this mole's ID.
  /// 
  /// Returns a list of photos containing this mole.
  static Future<List<Photo>> getPhotosForMole(String moleId) async {
    // Implementation will be added in Phase 3
    return [];
  }
}

