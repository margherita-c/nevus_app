import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;
import 'photo_gallery_screen.dart';
import '../models/photo.dart';
import '../storage/user_storage.dart'; // Changed from photo_storage

class CameraScreen extends StatefulWidget {
  final String? campaignId; // Add campaign support
  
  const CameraScreen({super.key, this.campaignId});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras![0], ResolutionPreset.high);

    await _controller!.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;

    // Use campaign directory if campaign is specified
    String imagePath;
    if (widget.campaignId != null) {
      final campaignDir = await UserStorage.getCampaignDirectory(widget.campaignId!);
      await UserStorage.ensureCampaignDirectoryExists(widget.campaignId!);
      imagePath = path.join(campaignDir, '${DateTime.now().millisecondsSinceEpoch}.jpg');
    } else {
      // Fallback to user directory
      final userDir = await UserStorage.getUserDirectory();
      await UserStorage.ensureUserDirectoryExists();
      imagePath = path.join(userDir, '${DateTime.now().millisecondsSinceEpoch}.jpg');
    }
    
    developer.log('Saving picture to $imagePath', name: 'CameraScreen');

    try {
      XFile picture = await _controller!.takePicture();
      await picture.saveTo(imagePath);

      // Show dialog to get photo description
      String? description = await _showDescriptionDialog();
      if (description == null) return; // User cancelled

      final newPhoto = Photo(
        id: 'photo_${DateTime.now().millisecondsSinceEpoch}',
        path: imagePath,
        dateTaken: DateTime.now(),
        description: description,
        campaignId: widget.campaignId ?? 'default_campaign',
      );

      // Load, add, and save using UserStorage
      List<Photo> photos = await UserStorage.loadPhotos();
      photos.add(newPhoto);
      await UserStorage.savePhotos(photos);
      developer.log('Photo saved successfully', name: 'CameraScreen');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Picture saved!'),
            action: SnackBarAction(
              label: 'View Gallery',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PhotoGalleryScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      developer.log('Error taking picture: $e', name: 'CameraScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error taking picture'))
        );
      }
    }
  }

  Future<String?> _showDescriptionDialog() async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Describe Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Which body region does this photo show?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Body Region',
                hintText: 'e.g., Left shoulder, Upper back, Right arm',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.campaignId != null ? 'Campaign Photo' : 'Camera'),
            if (!UserStorage.currentUser.isGuest) ...[
              const Text(' - '),
              Text(UserStorage.currentUser.username),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PhotoGalleryScreen(),
                ),
              );
            },
            tooltip: 'View Gallery',
          ),
        ],
      ),
      body: CameraPreview(_controller!),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        tooltip: 'Take Picture',
        child: const Icon(Icons.camera),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
