import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;
import 'dart:io';
import 'photo_gallery_screen.dart';
import '../models/photo.dart';
import '../models/spot.dart'; // Add import for Spot model
import '../storage/user_storage.dart'; // Changed from photo_storage
import '../storage/campaign_storage.dart'; // Import CampaignStorage
import '../models/campaign.dart'; // Import Campaign model

class CameraScreen extends StatefulWidget {
  final String? campaignId; // Add campaign support
  final Photo? templatePhoto; // Add template photo support
  
  const CameraScreen({super.key, this.campaignId, this.templatePhoto});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isInitialized = false;
  Campaign? _campaign; // Add campaign state
  bool _showTemplateOverlay = false; // State for template overlay visibility

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

      // If there's a template photo, show comparison dialog
      if (widget.templatePhoto != null) {
        developer.log('Showing photo comparison dialog', name: 'CameraScreen');
        try {
          final bool? acceptPhoto = await _showPhotoComparisonDialog(imagePath);
          developer.log('Comparison dialog result: $acceptPhoto', name: 'CameraScreen');
          
          if (acceptPhoto == true) {
            // User accepted the photo - replace template and exit
            developer.log('User accepted photo, replacing template', name: 'CameraScreen');
            await _replaceTemplateWithNewPhoto(imagePath);
            if (mounted) {
              Navigator.pop(context); // Exit camera screen
            }
            return;
          } else {
            // User rejected the photo - delete it and stay in camera
            developer.log('User rejected photo, deleting and staying in camera', name: 'CameraScreen');
            await File(imagePath).delete();
            developer.log('Photo rejected and deleted', name: 'CameraScreen');
            return;
          }
        } catch (e) {
          developer.log('Error in photo comparison dialog: $e', name: 'CameraScreen');
          // Clean up photo if error occurs
          try {
            await File(imagePath).delete();
          } catch (deleteError) {
            developer.log('Error deleting photo after dialog error: $deleteError', name: 'CameraScreen');
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error showing comparison dialog: $e')),
            );
          }
          return;
        }
      }

      // Original workflow for non-template photos
      String? description = await _showDescriptionDialog();
      if (description == null) {
        // User cancelled - delete the photo
        await File(imagePath).delete();
        return;
      }

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

      // Update campaign photoIds
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

  Future<bool?> _showPhotoComparisonDialog(String newPhotoPath) async {
    // Add mounted check before showing dialog
    if (!mounted) return false;
    
    developer.log('Building simple comparison dialog', name: 'CameraScreen');
    
    try {
      // Use a much simpler dialog without complex layouts
      return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Accept New Photo?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Compare your new photo with the template:'),
                const SizedBox(height: 16),
                
                // Simple side-by-side thumbnails
                Row(
                  children: [
                    // Template thumbnail
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Template',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 80,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue, width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Image.file(
                                File('${UserStorage.userDirectory}/${widget.templatePhoto!.relativePath}'),
                                fit: BoxFit.cover,
                                cacheWidth: 200, // Limit memory usage
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.image_not_supported, 
                                               color: Colors.grey, size: 24),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // New photo thumbnail
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'New Photo',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 80,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green, width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Image.file(
                                File(newPhotoPath),
                                fit: BoxFit.cover,
                                cacheWidth: 200, // Limit memory usage
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.image_not_supported, 
                                               color: Colors.grey, size: 24),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Text(
                  'Accept this photo? It will replace the template.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                developer.log('User chose to retake photo', name: 'CameraScreen');
                Navigator.pop(context, false);
              },
              child: const Text('Retake'),
            ),
            ElevatedButton(
              onPressed: () {
                developer.log('User chose to accept photo', name: 'CameraScreen');
                Navigator.pop(context, true);
              },
              child: const Text('Accept'),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      developer.log('Error showing dialog: $e', error: e, stackTrace: stackTrace, name: 'CameraScreen');
      return true; // Default to accepting the photo if dialog fails
    }
  }

  Future<void> _replaceTemplateWithNewPhoto(String newPhotoPath) async {
    try {
      developer.log('Starting template replacement process', name: 'CameraScreen');
      
      // Load all photos
      final allPhotos = await UserStorage.loadPhotos();
      developer.log('Loaded ${allPhotos.length} photos from storage', name: 'CameraScreen');
      
      // Find and remove the template photo
      final templateIndex = allPhotos.indexWhere((photo) => photo.id == widget.templatePhoto!.id);
      developer.log('Template photo index: $templateIndex', name: 'CameraScreen');
      
      if (templateIndex != -1) {
        // Delete the template photo file
        final templateFile = File('${UserStorage.userDirectory}/${widget.templatePhoto!.relativePath}');
        developer.log('Template file path: ${templateFile.path}', name: 'CameraScreen');
        
        if (await templateFile.exists()) {
          await templateFile.delete();
          developer.log('Template file deleted successfully', name: 'CameraScreen');
        } else {
          developer.log('Template file not found for deletion', name: 'CameraScreen');
        }
        
        // Remove template photo from list
        allPhotos.removeAt(templateIndex);
        developer.log('Template photo removed from photos list', name: 'CameraScreen');
      }

      // Create new photo object (non-template) with preserved spots from template
      final newPhoto = Photo(
        id: 'photo_${DateTime.now().millisecondsSinceEpoch}',
        relativePath: UserStorage.getRelativePath(newPhotoPath),
        dateTaken: DateTime.now(),
        description: widget.templatePhoto!.description, // Use template's description
        campaignId: widget.campaignId!,
        isTemplate: false, // This is not a template
        spots: widget.templatePhoto!.spots.map((spot) => Spot(
          position: spot.position,
          radius: spot.radius,
          moleId: spot.moleId,
        )).toList(), // Create deep copies of spots from template
      );
      developer.log('Created new photo object: ${newPhoto.id}', name: 'CameraScreen');

      // Add new photo to list
      allPhotos.add(newPhoto);
      await UserStorage.savePhotos(allPhotos);
      developer.log('Saved photos to storage', name: 'CameraScreen');

      // Update campaign photoIds - remove template and add new photo
      final campaigns = await CampaignStorage.loadCampaigns();
      final campaignIndex = campaigns.indexWhere((c) => c.id == widget.campaignId);
      if (campaignIndex != -1) {
        // Remove template photo ID
        campaigns[campaignIndex].photoIds.remove(widget.templatePhoto!.id);
        // Add new photo ID
        campaigns[campaignIndex].photoIds.add(newPhoto.id);
        await CampaignStorage.saveCampaigns(campaigns);
      }

      developer.log('Template replaced successfully with new photo', name: 'CameraScreen');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo accepted! Template replaced.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('Error replacing template: $e', name: 'CameraScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error replacing template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      body: Stack(
        children: [
          // Camera preview (full screen)
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          
          // Template image overlay (full screen semi-transparent)
          if (widget.templatePhoto != null && _showTemplateOverlay)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showTemplateOverlay = false;
                  });
                },
                child: Container(
                  color: Colors.black.withValues (alpha: 0.3),
                  child: Center(
                    child: FutureBuilder<bool>(
                      future: File('${UserStorage.userDirectory}/${widget.templatePhoto!.relativePath}').exists(),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues (alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File('${UserStorage.userDirectory}/${widget.templatePhoto!.relativePath}'),
                                fit: BoxFit.contain,
                                color: Colors.white.withValues (alpha: 0.7),
                                colorBlendMode: BlendMode.modulate,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
            ),
          
          // Template image thumbnail (small corner image)
          if (widget.templatePhoto != null && !_showTemplateOverlay)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showTemplateOverlay = true;
                  });
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues (alpha: 0.3),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: FutureBuilder<bool>(
                          future: File('${UserStorage.userDirectory}/${widget.templatePhoto!.relativePath}').exists(),
                          builder: (context, snapshot) {
                            if (snapshot.data == true) {
                              return Image.file(
                                File('${UserStorage.userDirectory}/${widget.templatePhoto!.relativePath}'),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              );
                            }
                            return Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      // Template indicator on thumbnail
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Template',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
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
