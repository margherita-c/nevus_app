import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;
import 'photo_gallery_screen.dart';
import '../models/photo.dart';
import '../storage/user_storage.dart'; // Changed from photo_storage
import '../storage/campaign_storage.dart'; // Import CampaignStorage
import '../models/campaign.dart'; // Import Campaign model

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
  Campaign? _campaign; // Add campaign state

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadCampaign(); // Load campaign information
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        developer.log('No cameras available', name: 'CameraScreen');
        return;
      }
      
      _controller = CameraController(
        cameras![0], 
        ResolutionPreset.high,
        enableAudio: false, // Disable audio to prevent hanging
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      developer.log('Camera initialization error: $e', name: 'CameraScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _loadCampaign() async {
    if (widget.campaignId != null) {
      try {
        final campaign = await CampaignStorage.getCampaignById(widget.campaignId!);
        if (mounted && campaign != null) {
          setState(() {
            _campaign = campaign;
          });
        }
      } catch (e) {
        developer.log('Error loading campaign: $e', name: 'CameraScreen');
      }
    }
  }

  String _getCameraTitle() {
    if (widget.campaignId != null && _campaign != null) {
      // Format date as YYYY-MM-DD to match folder naming
      final dateStr = '${_campaign!.date.year}-${_campaign!.date.month.toString().padLeft(2, '0')}-${_campaign!.date.day.toString().padLeft(2, '0')}';
      return 'Campaign $dateStr';
    }
    return 'Camera';
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
      developer.log('Error: Take picture without campaign', name: 'CameraScreen');
      return;
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
        relativePath: UserStorage.getRelativePath(imagePath),
        dateTaken: DateTime.now(),
        description: description,
        campaignId: widget.campaignId ?? 'default_campaign',
      );

      // Load, add, and save photo using UserStorage
      List<Photo> photos = await UserStorage.loadPhotos();
      photos.add(newPhoto);
      await UserStorage.savePhotos(photos);

      // *** ADD THIS: Update campaign photoIds ***
      if (widget.campaignId != null) {
        await _updateCampaignPhotoIds(widget.campaignId!, newPhoto.id);
      }

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

  Future<void> _updateCampaignPhotoIds(String campaignId, String photoId) async {
    final campaigns = await CampaignStorage.loadCampaigns();
    final campaignIndex = campaigns.indexWhere((c) => c.id == campaignId);
    
    if (campaignIndex != -1) {
      // Add the photo ID to the campaign's photoIds list
      campaigns[campaignIndex].photoIds.add(photoId);
      await CampaignStorage.saveCampaigns(campaigns);
      developer.log('Updated campaign $campaignId with photo $photoId', name: 'CameraScreen');
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
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getCameraTitle()),
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
