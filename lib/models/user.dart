/// Represents a user of the nevus app.
/// 
/// Users can be either authenticated users with a username,
/// or guest users. Each user has their own data folder.
class User {
  /// Username for authenticated users, or "guest" for guest users.
  final String username;
  
  /// Whether this is a guest user (not logged in).
  final bool isGuest;

  User({
    required this.username,
    this.isGuest = false,
  });

  /// Creates a guest user.
  factory User.guest() => User(username: 'guest', isGuest: true);

  /// Converts this user to a JSON map for storage.
  Map<String, dynamic> toJson() => {
    'username': username,
    'isGuest': isGuest,
  };

  /// Creates a user from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) => User(
    username: json['username'],
    isGuest: json['isGuest'] ?? false,
  );
}