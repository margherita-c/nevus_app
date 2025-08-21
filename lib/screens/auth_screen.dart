import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'home_screen.dart';
import '../storage/user_storage.dart';
import '../models/user.dart';
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
        
        // Find user data file to get the actual username
        String? actualUsername;
        for (final file in archive) {
          final basename = file.name.split('/').last;
          if (file.isFile && basename == 'user.json') {
            final userData = String.fromCharCodes(file.content as List<int>);
            final userJson = jsonDecode(userData);
            actualUsername = userJson['username'];
            break;
          }
        }
        
        if (actualUsername == null) {
          throw Exception('No user data found in archive');
        }
        
        // Create new user with the actual username from the archive
        final importedUser = User(username: actualUsername);
        UserStorage.setCurrentUser(importedUser);
        
        // Extract all files to the user's directory
        final usersDir = await UserStorage.getUsersDirectory();
        
        for (final file in archive) {
          if (file.isFile) {
            final outputFile = File('$usersDir/${file.name}');
            await outputFile.create(recursive: true);
            await outputFile.writeAsBytes(file.content as List<int>);
          }
        }
        
        setState(() => _isLoading = false);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account "$actualUsername" imported successfully!')),
          );
          
          // Navigate to home screen with the imported account
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to import account: $e')),
          );
        }
      }
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