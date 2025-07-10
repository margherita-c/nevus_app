class Photo {
  final String path;
  final DateTime dateTaken;
  final String moleName;

  Photo({
    required this.path,
    required this.dateTaken,
    required this.moleName,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'dateTaken': dateTaken.toIso8601String(),
        'moleName': moleName,
      };

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        path: json['path'],
        dateTaken: DateTime.parse(json['dateTaken']),
        moleName: json['moleName'],
      );
}