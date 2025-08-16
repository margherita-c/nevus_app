import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/photo.dart';
import '../models/campaign.dart';
import '../models/mole.dart';

/// Manages user data storage with organized folder structure.
/// 
/// Each user has their own folder: /users/{username}/
/// Campaign photos are stored in: /users/{username}/campaigns/{campaignId}/
/// JSON files are stored directly in user folder: /users/{username}/
class UserStorage {
  static User? _currentUser;
  
  /// Gets the current logged-in user, defaults to guest if none.
  static User get currentUser => _currentUser ?? User.guest();
  
  /// Sets the current user.
  static void setCurrentUser(User user) {
    _currentUser = user;
  }

  /// Gets the base app directory.
  static Future<String> get _appDirectory async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Gets the user's data directory: /app/users/{username}/
  static Future<String> getUserDirectory([User? user]) async {
    final baseDir = await _appDirectory;
    final username = (user ?? currentUser).username;
    return '$baseDir/users/$username';
  }

  /// Gets the campaign directory for a specific campaign: /app/users/{username}/campaigns/{campaignId}/
  static Future<String> getCampaignDirectory(String campaignId, [User? user]) async {
    final userDir = await getUserDirectory(user);
    return '$userDir/campaigns/$campaignId';
  }

  /// Ensures user directory structure exists.
  static Future<void> ensureUserDirectoryExists([User? user]) async {
    final userDir = await getUserDirectory(user);
    final directory = Directory(userDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// Ensures campaign directory structure exists.
  static Future<void> ensureCampaignDirectoryExists(String campaignId, [User? user]) async {
    final campaignDir = await getCampaignDirectory(campaignId, user);
    final directory = Directory(campaignDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  // JSON file paths in user directory
  static Future<File> _photosJsonFile([User? user]) async {
    final userDir = await getUserDirectory(user);
    return File('$userDir/photos.json');
  }

  static Future<File> _campaignsJsonFile([User? user]) async {
    final userDir = await getUserDirectory(user);
    return File('$userDir/campaigns.json');
  }

  static Future<File> _molesJsonFile([User? user]) async {
    final userDir = await getUserDirectory(user);
    return File('$userDir/moles.json');
  }

  // Load/Save Photos
  static Future<List<Photo>> loadPhotos([User? user]) async {
    try {
      await ensureUserDirectoryExists(user);
      final file = await _photosJsonFile(user);
      if (!await file.exists()) return [];
      
      final contents = await file.readAsString();
      final List<dynamic> jsonData = json.decode(contents);
      return jsonData.map((json) => Photo.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> savePhotos(List<Photo> photos, [User? user]) async {
    await ensureUserDirectoryExists(user);
    final file = await _photosJsonFile(user);
    final jsonData = photos.map((photo) => photo.toJson()).toList();
    await file.writeAsString(json.encode(jsonData));
  }

  // Load/Save Campaigns
  static Future<List<Campaign>> loadCampaigns([User? user]) async {
    try {
      await ensureUserDirectoryExists(user);
      final file = await _campaignsJsonFile(user);
      if (!await file.exists()) return [];
      
      final contents = await file.readAsString();
      final List<dynamic> jsonData = json.decode(contents);
      return jsonData.map((json) => Campaign.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveCampaigns(List<Campaign> campaigns, [User? user]) async {
    await ensureUserDirectoryExists(user);
    final file = await _campaignsJsonFile(user);
    final jsonData = campaigns.map((campaign) => campaign.toJson()).toList();
    await file.writeAsString(json.encode(jsonData));
  }

  // Load/Save Moles
  static Future<List<Mole>> loadMoles([User? user]) async {
    try {
      await ensureUserDirectoryExists(user);
      final file = await _molesJsonFile(user);
      if (!await file.exists()) return [];
      
      final contents = await file.readAsString();
      final List<dynamic> jsonData = json.decode(contents);
      return jsonData.map((json) => Mole.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveMoles(List<Mole> moles, [User? user]) async {
    await ensureUserDirectoryExists(user);
    final file = await _molesJsonFile(user);
    final jsonData = moles.map((mole) => mole.toJson()).toList();
    await file.writeAsString(json.encode(jsonData));
  }

  // Load current user by username
  static Future<User?> loadCurrentUser(String username) async {
    try {
      final userDir = await getUserDirectory(User(username: username));
      final file = File('$userDir/user.json');
      if (!await file.exists()) return null;
      
      final contents = await file.readAsString();
      final jsonData = json.decode(contents);
      return User.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  // Create a new user
  static Future<void> createUser(User user) async {
    await ensureUserDirectoryExists(user);
    final file = File('${await getUserDirectory(user)}/user.json');
    await file.writeAsString(json.encode(user.toJson()));
  }
  
  // Update an existing user
  static Future<void> updateUser(User user) async {
    await ensureUserDirectoryExists(user);
    final file = File('${await getUserDirectory(user)}/user.json');
    await file.writeAsString(json.encode(user.toJson()));
    
    // Update the current user in memory if it's the same user
    if (currentUser.username == user.username) {
      setCurrentUser(user);
    }
  }
  
  static Future<void> saveCurrentUser() async {
    try {
      final userDir = await getUserDirectory();
      final userFile = File('$userDir/user.json');
      
      // Use the current user data that's already in memory
      await userFile.writeAsString(json.encode(currentUser.toJson()));
    } catch (e) {
      throw Exception('Failed to save current user: $e');
    }
  }
  
  /* static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final userDir = await getUserDirectory();
      final userFile = File('$userDir/current_user.json');
      
      if (await userFile.exists()) {
        final contents = await userFile.readAsString();
        return jsonDecode(contents);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load current user: $e');
    }
  } */
}