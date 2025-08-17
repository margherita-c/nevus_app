class Mole {
  final String id;
  final String name;
  final String description;
  final DateTime? createdDate;
  final DateTime? lastModified;
  final Map<String, dynamic>? metadata;

  Mole({
    required this.id,
    required this.name,
    this.description = '',
    DateTime? createdDate,
    DateTime? lastModified,
    this.metadata,
  }) : createdDate = createdDate ?? DateTime.now(),
       lastModified = lastModified ?? DateTime.now();

  /// Converts this mole to a JSON map for storage.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdDate': createdDate?.toIso8601String(),
        'lastModified': lastModified?.toIso8601String(),
        'metadata': metadata,
      };

  /// Creates a mole from a JSON map.
  factory Mole.fromJson(Map<String, dynamic> json) => Mole(
        id: json['id'],
        name: json['name'],
        description: json['description'] ?? '',
        createdDate: json['createdDate'] != null 
            ? DateTime.parse(json['createdDate']) 
            : null,
        lastModified: json['lastModified'] != null 
            ? DateTime.parse(json['lastModified']) 
            : null,
        metadata: json['metadata'],
      );

  /// Creates a copy of this mole with updated fields.
  Mole copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdDate,
    DateTime? lastModified,
    Map<String, dynamic>? metadata,
  }) => Mole(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        createdDate: createdDate ?? this.createdDate,
        lastModified: lastModified ?? DateTime.now(),
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mole && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Mole{id: $id, name: $name, description: $description}';
}

