import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../models/campaign.dart';
import '../models/photo.dart';
import '../storage/user_storage.dart';
import '../storage/campaign_storage.dart';
import 'camera_screen.dart';
import 'single_photo_screen.dart';
import '../widgets/photo_grid_item.dart';

class CampaignDetailScreen extends StatefulWidget {
  final Campaign campaign;

  const CampaignDetailScreen({super.key, required this.campaign});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  List<Photo> _campaignPhotos = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCampaignPhotos();
  }

  Future<void> _loadCampaignPhotos() async {
    setState(() => _isLoading = true);
    
    // Load all photos and filter by campaign ID
    final allPhotos = await UserStorage.loadPhotos();
    final campaignPhotos = allPhotos.where((photo) => photo.campaignId == widget.campaign.id).toList();
    
    setState(() {
      _campaignPhotos = campaignPhotos;
      _isLoading = false;
    });
  }

  Future<void> _importPhotos() async {
    try {
      // Allow user to select multiple images
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85, // Compress images to save space
      );

      if (images.isEmpty) return;

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Importing photos...'),
              ],
            ),
          ),
        );
      }

      // Ensure campaign directory exists
      await UserStorage.ensureCampaignDirectoryExists(widget.campaign.id);
      final campaignDir = await UserStorage.getCampaignDirectory(widget.campaign.id);

      List<Photo> newPhotos = [];
      List<String> newPhotoIds = [];

      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        
        // Create unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = path.extension(image.path);
        final fileName = 'imported_${timestamp}_$i$extension';
        final destinationPath = path.join(campaignDir, fileName);

        // Copy image to campaign directory
        final File sourceFile = File(image.path);
        await sourceFile.copy(destinationPath);

        // Get description for this photo
        String? description;
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          description = await _showDescriptionDialog(i + 1, images.length);
          if (description == null) {
            // User cancelled, clean up and stop
            await File(destinationPath).delete();
            break;
          }
          // Show loading dialog again if more photos to process
          if (i < images.length - 1) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Importing photos... (${i + 2}/${images.length})'),
                  ],
                ),
              ),
            );
          }
        }

        // Create Photo object
        final newPhoto = Photo(
          id: 'imported_photo_${timestamp}_$i',
          path: destinationPath,
          dateTaken: DateTime.now(), // Use import time as date taken
          description: description ?? 'Imported photo',
          campaignId: widget.campaign.id,
        );

        newPhotos.add(newPhoto);
        newPhotoIds.add(newPhoto.id);
      }

      if (newPhotos.isNotEmpty) {
        // Add photos to storage
        final allPhotos = await UserStorage.loadPhotos();
        allPhotos.addAll(newPhotos);
        await UserStorage.savePhotos(allPhotos);

        // Update campaign photoIds
        final campaigns = await CampaignStorage.loadCampaigns();
        final campaignIndex = campaigns.indexWhere((c) => c.id == widget.campaign.id);
        if (campaignIndex != -1) {
          campaigns[campaignIndex].photoIds.addAll(newPhotoIds);
          await CampaignStorage.saveCampaigns(campaigns);
        }

        // Reload campaign photos
        await _loadCampaignPhotos();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported ${newPhotos.length} photo(s)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing photos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showDescriptionDialog(int currentPhoto, int totalPhotos) async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Describe Photo $currentPhoto of $totalPhotos'),
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
            onPressed: () => Navigator.pop(context), // This returns null
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

  Future<void> _deleteCampaign() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Campaign'),
        content: Text('Are you sure you want to delete this campaign and all its ${_campaignPhotos.length} photos? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Delete all photos from this campaign
      final allPhotos = await UserStorage.loadPhotos();
      final remainingPhotos = allPhotos.where((photo) => photo.campaignId != widget.campaign.id).toList();
      await UserStorage.savePhotos(remainingPhotos);
      
      // Delete the campaign
      await CampaignStorage.deleteCampaign(widget.campaign.id);
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _editPhotoDescription(int index, String newDescription) async {
    final photo = _campaignPhotos[index];
    final updatedPhoto = Photo(
      id: photo.id,
      path: photo.path,
      dateTaken: photo.dateTaken,
      description: newDescription,
      campaignId: photo.campaignId,
      spots: photo.spots,
    );

    // Update in all photos
    final allPhotos = await UserStorage.loadPhotos();
    final globalIndex = allPhotos.indexWhere((p) => p.id == photo.id);
    if (globalIndex != -1) {
      allPhotos[globalIndex] = updatedPhoto;
      await UserStorage.savePhotos(allPhotos);
      await _loadCampaignPhotos();
    }
  }

  Future<void> _deletePhoto(int index) async {
    final photo = _campaignPhotos[index];
    
    // Remove from all photos
    final allPhotos = await UserStorage.loadPhotos();
    allPhotos.removeWhere((p) => p.id == photo.id);
    await UserStorage.savePhotos(allPhotos);
    
    await _loadCampaignPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Campaign ${widget.campaign.date.day}/${widget.campaign.date.month}/${widget.campaign.date.year}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CameraScreen(campaignId: widget.campaign.id),
                ),
              ).then((_) => _loadCampaignPhotos());
            },
            tooltip: 'Take Photo',
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: _importPhotos,
            tooltip: 'Import Photos',
          ),
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteCampaign();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Campaign', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Campaign Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campaign Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Date: ${widget.campaign.date.day}/${widget.campaign.date.month}/${widget.campaign.date.year}'),
                Text('Time: ${widget.campaign.date.hour}:${widget.campaign.date.minute.toString().padLeft(2, '0')}'),
                Text('Photos: ${_campaignPhotos.length}'),
              ],
            ),
          ),
          
          // Photos Grid
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _campaignPhotos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No photos in this campaign',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Take photos with the camera or import from gallery',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CameraScreen(campaignId: widget.campaign.id),
                                  ),
                                ).then((_) => _loadCampaignPhotos());
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Take Photo'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _importPhotos,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Import Photos'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: _campaignPhotos.length,
                    itemBuilder: (context, index) {
                      final photo = _campaignPhotos[index];
                      return PhotoGridItem(
                        photo: photo,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SinglePhotoScreen(
                                photo: photo,
                                index: index,
                                onEditDescription: _editPhotoDescription,
                                onDelete: _deletePhoto,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraScreen(campaignId: widget.campaign.id),
            ),
          ).then((_) => _loadCampaignPhotos());
        },
        tooltip: 'Take Photo',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}