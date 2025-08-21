import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:archive/archive.dart';
import 'home_screen.dart';
import '../storage/user_storage.dart';
import '../models/user.dart';
import '../models/photo.dart';
import 'dart:convert';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a username')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if user exists
      final existingUser = await UserStorage.loadCurrentUser(username);
      
      if (existingUser != null) {
        // Existing user - load their data
        UserStorage.setCurrentUser(existingUser);
      } else {
        // New user - create with minimal data
        final newUser = User(username: username);
        UserStorage.setCurrentUser(newUser);
        await UserStorage.createUser(newUser);
      }
      
      // Ensure user directory exists
      await UserStorage.ensureUserDirectoryExists();

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loginAsGuest() async {
    setState(() => _isLoading = true);

    try {
      // Set guest user
      UserStorage.setCurrentUser(User.guest());
      
      // Ensure guest directory exists
      await UserStorage.ensureUserDirectoryExists();

      setState(() => _isLoading = false);

      // Navigate to home page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _importAccount(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      
      setState(() => _isLoading = true);
      
      try {
        // Read and extract zip file
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        
        // Debug: Log archive contents
        developer.log('Archive contents:', name: 'AuthScreen.Import');
        for (final file in archive) {
          developer.log('File: ${file.name}, isFile: ${file.isFile}', name: 'AuthScreen.Import');
        }
        
        // Find user data file to get the actual username
        String? actualUsername;
        for (final file in archive) {
          final basename = file.name.split('/').last;
          developer.log('Checking file: ${file.name}, basename: $basename', name: 'AuthScreen.Import');
          if (file.isFile && basename == 'user.json') {
            final userData = String.fromCharCodes(file.content as List<int>);
            final userJson = jsonDecode(userData);
            actualUsername = userJson['username'];
            developer.log('Found username: $actualUsername', name: 'AuthScreen.Import');
            break;
          }
        }
        
        if (actualUsername == null) {
          throw Exception('No user data found in archive');
        }
        
        developer.log('Importing data for username: $actualUsername', name: 'AuthScreen.Import');
        
        // Create new user with the actual username from the archive
        final importedUser = User(username: actualUsername);
        UserStorage.setCurrentUser(importedUser);
        
        // Ensure user directory exists
        await UserStorage.ensureUserDirectoryExists(importedUser);
        final userDir = await UserStorage.getUserDirectory(importedUser);
        
        // Extract all files to the user's directory
        int filesExtracted = 0;
        for (final archiveFile in archive) {
          if (archiveFile.isFile) {
            // The archive structure is: username/filepath
            // We need to extract to: userDir/filepath (removing the username prefix)
            final pathParts = archiveFile.name.split('/');
            if (pathParts.length > 1 && pathParts[0] == actualUsername) {
              // Remove the username from the path
              final relativePath = pathParts.sublist(1).join('/');
              final outputFile = File('$userDir/$relativePath');
              
              developer.log('Extracting: ${archiveFile.name} -> ${outputFile.path}', name: 'AuthScreen.Import');
              
              await outputFile.create(recursive: true);
              await outputFile.writeAsBytes(archiveFile.content as List<int>);
              filesExtracted++;
            }
          }
        }
        
        developer.log('Extracted $filesExtracted files', name: 'AuthScreen.Import');
        
        // Fix photo paths in the imported data
        await _fixImportedPhotoPaths(importedUser);
        
        // Validate the import
        await _validateImport(importedUser);
        
        setState(() => _isLoading = false);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account "$actualUsername" imported successfully! ($filesExtracted files)'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to home screen with the imported account
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        developer.log('Import error: $e', name: 'AuthScreen.Import', error: e);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to import account: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // User cancelled file selection
      developer.log('User cancelled file selection', name: 'AuthScreen.Import');
    }
  }

  /// Fixes photo paths after importing to point to the correct local file locations
  Future<void> _fixImportedPhotoPaths(User user) async {
    try {
      developer.log('Fixing imported photo paths for user: ${user.username}', name: 'AuthScreen.Import');
      
      // Load the imported photos
      final photos = await UserStorage.loadPhotos(user);
      bool pathsChanged = false;
      
      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        final originalPath = photo.path;
        
        // Extract filename from the original path
        final filename = originalPath.split('/').last;
        
        // Check if this photo belongs to a campaign
        if (photo.campaignId.isNotEmpty && photo.campaignId != 'default_campaign') {
          // Look for the file in the campaign directory
          final campaignDir = await UserStorage.getCampaignDirectory(photo.campaignId, user);
          final newPath = '$campaignDir/$filename';
          
          if (await File(newPath).exists()) {
            // Update the photo with the correct path
            photos[i] = Photo(
              id: photo.id,
              path: newPath,
              dateTaken: photo.dateTaken,
              description: photo.description,
              campaignId: photo.campaignId,
              spots: photo.spots,
            );
            pathsChanged = true;
            developer.log('Updated photo path: $originalPath -> $newPath', name: 'AuthScreen.Import');
          } else {
            developer.log('Warning: Photo file not found at expected location: $newPath', name: 'AuthScreen.Import');
          }
        } else {
          // Look for the file in the user's root directory
          final userDir = await UserStorage.getUserDirectory(user);
          final newPath = '$userDir/$filename';
          
          if (await File(newPath).exists()) {
            photos[i] = Photo(
              id: photo.id,
              path: newPath,
              dateTaken: photo.dateTaken,
              description: photo.description,
              campaignId: photo.campaignId,
              spots: photo.spots,
            );
            pathsChanged = true;
            developer.log('Updated photo path: $originalPath -> $newPath', name: 'AuthScreen.Import');
          } else {
            developer.log('Warning: Photo file not found at expected location: $newPath', name: 'AuthScreen.Import');
          }
        }
      }
      
      // Save the updated photos if any paths were changed
      if (pathsChanged) {
        await UserStorage.savePhotos(photos, user);
        developer.log('Updated ${photos.length} photo paths', name: 'AuthScreen.Import');
      } else {
        developer.log('No photo paths needed updating', name: 'AuthScreen.Import');
      }
      
    } catch (e) {
      developer.log('Error fixing photo paths: $e', name: 'AuthScreen.Import', error: e);
      // Don't throw here as import was otherwise successful
    }
  }

  /// Validates the imported data and logs summary information
  Future<void> _validateImport(User user) async {
    try {
      developer.log('Validating imported data for user: ${user.username}', name: 'AuthScreen.Import');
      
      // Check photos
      final photos = await UserStorage.loadPhotos(user);
      int validPhotos = 0;
      for (final photo in photos) {
        if (await File(photo.path).exists()) {
          validPhotos++;
        }
      }
      
      // Check campaigns
      final campaigns = await UserStorage.loadCampaigns(user);
      
      // Check moles
      final moles = await UserStorage.loadMoles(user);
      
      developer.log(
        'Import validation complete - Photos: $validPhotos/${photos.length} valid, Campaigns: ${campaigns.length}, Moles: ${moles.length}',
        name: 'AuthScreen.Import'
      );
      
    } catch (e) {
      developer.log('Error validating import: $e', name: 'AuthScreen.Import', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nevus App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Nevus App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track your moles and monitor changes over time',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading 
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isLoading ? null : _loginAsGuest,
                child: const Text('Continue as Guest'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _importAccount(context),
                child: const Text('Import Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}