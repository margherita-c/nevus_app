/// Represents a user of the nevus app.
/// 
/// Users can be either authenticated users with a username,
/// or guest users. Each user has their own data folder.
class User {
  /// Username for authenticated users, or "guest" for guest users.
  final String username;
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? gender;
  
  /// Fitzpatrick skin type scale (1-6)
  /// 1 = Very fair, always burns, never tans
  /// 2 = Fair, usually burns, tans minimally
  /// 3 = Medium, sometimes burns, tans gradually
  /// 4 = Olive, rarely burns, tans easily
  /// 5 = Brown, very rarely burns, tans darkly
  /// 6 = Dark brown/black, never burns
  final int? skinType;

  /// Whether this is a guest user (not logged in).
  final bool isGuest;

  User({
    required this.username,
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.skinType,
    this.isGuest = false,
  });

  /// Creates a guest user.
  factory User.guest() => User(username: 'guest', isGuest: true);

  /// Converts this user to a JSON map for storage.
  Map<String, dynamic> toJson() => {
        'username': username,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'skinType': skinType,
        'isGuest': isGuest,
      };

  /// Creates a user from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) => User(
        username: json['username'],
        fullName: json['fullName'],
        dateOfBirth: json['dateOfBirth'] != null 
            ? DateTime.parse(json['dateOfBirth']) 
            : null,
        gender: json['gender'],
        skinType: json['skinType'],
        isGuest: json['isGuest'] ?? false,
      );

  /// Creates a copy of this user with updated fields.
  User copyWith({
    String? username,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    int? skinType,
    bool? isGuest,
  }) => User(
        username: username ?? this.username,
        fullName: fullName ?? this.fullName,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        skinType: skinType ?? this.skinType,
        isGuest: isGuest ?? this.isGuest,
      );

  /// Returns the user's age based on date of birth.
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Returns a formatted string of the date of birth.
  String get formattedDateOfBirth {
    if (dateOfBirth == null) return 'Not specified';
    return '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}';
  }

  /// Returns the display name for the user.
  String get displayName {
    if (isGuest) return 'Guest';
    return fullName?.isNotEmpty == true ? fullName! : username;
  }

  /// Returns the Fitzpatrick skin type description.
  String get skinTypeDescription {
    if (skinType == null) return 'Not specified';
    switch (skinType!) {
      case 1: return 'Type I - Very fair, always burns';
      case 2: return 'Type II - Fair, usually burns';
      case 3: return 'Type III - Medium, sometimes burns';
      case 4: return 'Type IV - Olive, rarely burns';
      case 5: return 'Type V - Brown, very rarely burns';
      case 6: return 'Type VI - Dark brown/black, never burns';
      default: return 'Invalid skin type';
    }
  }
}