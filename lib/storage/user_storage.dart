import 'dart:convert';
import 'dart:developer' as developer;
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
  static String _userDirectory = '';
  // In-process write queue to serialize file writes and avoid concurrent writes
  static Future<void> _writeQueue = Future.value();
  
  /// Gets the current logged-in user, defaults to guest if none.
  static User get currentUser => _currentUser ?? User.guest();
  
  /// Sets the current user.
  static void setCurrentUser(User user) async {
    _currentUser = user;
    final baseDir = await _appDirectory;
    _userDirectory = '$baseDir/users/${user.username}';
  }

  /// Gets the base app directory.
  static Future<String> get _appDirectory async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static String get userDirectory => _userDirectory;

  /// Gets the users directory: /app/users/
  static Future<String> getUsersDirectory([User? user]) async {
    final baseDir = await _appDirectory;
    return '$baseDir/users';
  }

  /// Gets the campaign directory for a specific campaign: /app/users/{username}/campaigns/{friendlyName}/
  static Future<String> getCampaignDirectory(String campaignId, [User? user]) async {
    final userDir = userDirectory;
    
    // Try to get the campaign to extract the date for a friendly name
    // We need to import CampaignStorage here or use a different approach
    try {
      // Load campaigns.json directly from the user directory to avoid circular imports
      final campaignsFile = File('$userDir/campaigns.json');
      if (await campaignsFile.exists()) {
        final contents = await campaignsFile.readAsString();
        final List<dynamic> jsonData = json.decode(contents);
        final campaigns = jsonData.map((json) => Campaign.fromJson(json)).toList();
        
        final campaign = campaigns.cast<Campaign?>().firstWhere(
          (c) => c?.id == campaignId, 
          orElse: () => null
        );
        
        if (campaign != null) {
          // Use friendly name based on date
          final friendlyName = getFriendlyCampaignFolderName(campaign.date);
          return '$userDir/campaigns/$friendlyName';
        }
      }
    } catch (e) {
      // Fall through to fallback
    }
    
    // Fallback to campaignId for backwards compatibility
    return '$userDir/campaigns/$campaignId';
  }

  ///Get relative directory
  static String getRelativePath(String fullPath) {
    if (fullPath.startsWith(_userDirectory)) {
      return fullPath.substring(_userDirectory.length + 1); // +1 to remove the slash
    }
    return fullPath; // Return as-is if not under base path
  }

  /// Get full path from relative path
  static String getFullPath(String relativePath) {
    return '$_userDirectory/$relativePath';
  }

  /// Generates a friendly folder name for a campaign based on its date
  static String getFriendlyCampaignFolderName(DateTime campaignDate) {
    return 'Campaign_${campaignDate.year}-${campaignDate.month.toString().padLeft(2, '0')}-${campaignDate.day.toString().padLeft(2, '0')}';
  }

  /// Migrates existing campaign folders to use friendly names
  static Future<void> migrateCampaignFolders([User? user]) async {
    try {
      final userDir = userDirectory;
      final campaignsDir = Directory('$userDir/campaigns');
      
      if (!await campaignsDir.exists()) return;
      
      // Load campaigns.json directly to avoid circular imports
      final campaignsFile = File('$userDir/campaigns.json');
      if (!await campaignsFile.exists()) return;
      
      final contents = await campaignsFile.readAsString();
      final List<dynamic> jsonData = json.decode(contents);
      final campaigns = jsonData.map((json) => Campaign.fromJson(json)).toList();
      
      for (final campaign in campaigns) {
        final oldFolderPath = '$userDir/campaigns/${campaign.id}';
        final newFolderName = getFriendlyCampaignFolderName(campaign.date);
        final newFolderPath = '$userDir/campaigns/$newFolderName';
        
        final oldFolder = Directory(oldFolderPath);
        final newFolder = Directory(newFolderPath);
        
        // Only migrate if old folder exists and new folder doesn't
        if (await oldFolder.exists() && !await newFolder.exists()) {
          await oldFolder.rename(newFolderPath);
          developer.log('Migrated campaign folder: ${campaign.id} -> $newFolderName', name: 'UserStorage.Migrate');
        }
      }
    } catch (e) {
      developer.log('Error during campaign folder migration: $e', name: 'UserStorage.Migrate', error: e);
    }
  }

  /// Ensures user directory structure exists.
  static Future<void> ensureUserDirectoryExists([User? user]) async {
    final userDir = userDirectory;
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
    final userDir = userDirectory;
    return File('$userDir/photos.json');
  }

  static Future<File> _campaignsJsonFile([User? user]) async {
    final userDir = userDirectory;
    return File('$userDir/campaigns.json');
  }

  static Future<File> _molesJsonFile([User? user]) async {
    final userDir = userDirectory;
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
    var encoder = JsonEncoder.withIndent('  ');
    final contents = encoder.convert(jsonData);

    // Serialize writes to avoid overlapping file writes
    _writeQueue = _writeQueue.then((_) => _atomicWrite(file, contents));
    await _writeQueue;
  }

  static Future<void> _atomicWrite(File file, String contents) async {
    final tmp = File('${file.path}.tmp.${DateTime.now().millisecondsSinceEpoch}');
    await tmp.writeAsString(contents);
    try {
      if (await file.exists()) {
        // Attempt to replace the original file
        await file.delete();
      }
    } catch (_) {}
    await tmp.rename(file.path);
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
    var encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(jsonData));
  }

  // Load/Save Moles
  static Future<List<Mole>> loadMoles([User? user]) async {
    try {
      await ensureUserDirectoryExists(user);
      final file = await _molesJsonFile(user);
    
      if (!await file.exists()) {
        return [];
      }
    
      final contents = await file.readAsString();
      final List<dynamic> jsonData = json.decode(contents);
      return jsonData.map((json) => Mole.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load moles: $e');
    }
  }

  static Future<void> saveMoles(List<Mole> moles, [User? user]) async {
    try {
      await ensureUserDirectoryExists(user);
      final file = await _molesJsonFile(user);
      final jsonData = moles.map((mole) => mole.toJson()).toList();
      var encoder = JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(jsonData));
    } catch (e) {
      throw Exception('Failed to save moles: $e');
    }
  }

  // Load current user by username
  static Future<User?> loadUser(String username) async {
    try {
      final baseDir = await _appDirectory;
      _userDirectory = '$baseDir/users/$username';
      final userDir = userDirectory;
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
    final file = File('$userDirectory/user.json');
    var encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(user.toJson()));
  }
  
  // Update an existing user
  static Future<void> updateUser(User user) async {
    await ensureUserDirectoryExists(user);
    final file = File('$userDirectory/user.json');
    var encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(user.toJson()));

    // Update the current user in memory if it's the same user
    if (currentUser.username == user.username) {
      setCurrentUser(user);
    }
  }
  
  static Future<void> saveCurrentUser() async {
    try {
      final userFile = File('$userDirectory/user.json');
      
      // Use the current user data that's already in memory
      var encoder = JsonEncoder.withIndent('  ');
      await userFile.writeAsString(encoder.convert(currentUser.toJson()));
    } catch (e) {
      throw Exception('Failed to save current user: $e');
    }
  }

  /// Delete a photo and its associated file
  static Future<void> deletePhoto(Photo photo) async {
    try {
      // Delete the actual file
      final fullPath = getFullPath(photo.relativePath);
      final file = File(fullPath);
      if (await file.exists()) {
        await file.delete();
        developer.log('Deleted photo file: $fullPath', name: 'UserStorage');
      }

      // Remove from photos storage
      final allPhotos = await loadPhotos();
      allPhotos.removeWhere((p) => p.id == photo.id);
      await savePhotos(allPhotos);
      
      developer.log('Deleted photo from storage: ${photo.id}', name: 'UserStorage');
    } catch (e) {
      developer.log('Error deleting photo ${photo.id}: $e', name: 'UserStorage');
      rethrow;
    }
  }
}