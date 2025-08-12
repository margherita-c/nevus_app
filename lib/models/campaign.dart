class Campaign {
  String id;
  DateTime date;
  List<String> photoIds; // List of photo IDs in this campaign
  
  Campaign({
    required this.id,
    required this.date,
    List<String>? photoIds,
  }) : photoIds = photoIds ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'photoIds': photoIds,
  };

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
    id: json['id'],
    date: DateTime.parse(json['date']),
    photoIds: List<String>.from(json['photoIds'] ?? []),
  );
}