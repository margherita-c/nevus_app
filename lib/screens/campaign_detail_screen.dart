import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/campaign.dart';
import '../models/photo.dart';
import '../models/spot.dart'; // Add import for Spot model
import '../models/mole.dart';
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
  List<Mole> _moles = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessingDialogShown = false;
  late Campaign _campaign;

  /// Check if the campaign is from today's date
  bool get _isCampaignFromToday {
    final now = DateTime.now();
    final campaignDate = _campaign.date;
    return campaignDate.year == now.year &&
           campaignDate.month == now.month &&
           campaignDate.day == now.day;
  }

  /// Check if there are any non-template photos in the campaign
  bool get _hasNonTemplatePhotos {
    return _campaignPhotos.any((photo) => !photo.isTemplate);
  }

  @override
  void initState() {
    super.initState();
    _campaign = widget.campaign;
    _loadCampaignPhotos();
  }

  Future<void> _loadCampaignPhotos() async {
    setState(() => _isLoading = true);
    
    // Load all photos and filter by campaign ID
    final allPhotos = await UserStorage.loadPhotos();
    // Reload campaigns to get updated photoIds
    final allCampaigns = await CampaignStorage.loadCampaigns();
    final updatedCampaign = allCampaigns.firstWhere(
      (c) => c.id == _campaign.id,
      orElse: () => _campaign, // Fallback to current if not found
    );
    _campaign = updatedCampaign; // Update local copy
    final campaignPhotoIds = _campaign.photoIds.toSet(); // Use Set to remove duplicates
    final campaignPhotos = allPhotos.where((photo) => campaignPhotoIds.contains(photo.id)).toList();
    // Ensure no duplicate photos in the final list
    final uniquePhotos = <String, Photo>{};
    for (final photo in campaignPhotos) {
      uniquePhotos[photo.id] = photo;
    }
    final finalCampaignPhotos = uniquePhotos.values.toList();
    final allMoles = await UserStorage.loadMoles();

    setState(() {
      _campaignPhotos = finalCampaignPhotos;
      _moles = allMoles;
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
      _showProcessingDialog('Importing photos...');

      // Ensure campaign directory exists
      await UserStorage.ensureCampaignDirectoryExists(_campaign.id);
      final campaignDir = await UserStorage.getCampaignDirectory(_campaign.id);

      List<Photo> newPhotos = [];
      List<String> newPhotoIds = [];

      for (int i = 0; i < images.length; i++) {
        final image = images[i];

        // Preserve original filename and ensure unique filename in campaign dir
        final originalBasename = image.name; // XFile exposes name property
        final originalNameWithoutExt = originalBasename.contains('.')
            ? originalBasename.substring(0, originalBasename.lastIndexOf('.'))
            : originalBasename;
        final extension = path.extension(image.path);

        String candidateName = originalBasename;
        int suffix = 1;
        String destinationPath = path.join(campaignDir, candidateName);
        while (await File(destinationPath).exists()) {
          final nameWithoutExt = originalNameWithoutExt;
          candidateName = '${nameWithoutExt}_$suffix$extension';
          destinationPath = path.join(campaignDir, candidateName);
          suffix++;
        }

        // Copy image to campaign directory
          final bool copied = await _copyFileInBackground(image.path, destinationPath);
          if (!copied) {
            // Skip this file if copy failed
            continue;
          }

        // Get description for this photo (allow user override). If left empty, use filename.
        String? description;
        if (mounted) {
          _closeProcessingDialog(); // Close loading dialog
          description = await _showDescriptionDialog(i + 1, images.length);
          if (description == null) {
            // User cancelled, clean up and stop
            await File(destinationPath).delete();
            break;
          }
          // Show loading dialog again if more photos to process
          if (mounted && i < images.length - 1) {
            _showProcessingDialog('Importing photos... (${i + 2}/${images.length})');
          }
        }

        // Create Photo object
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newPhoto = Photo(
          id: 'imported_photo_${timestamp}_$i',
          relativePath: UserStorage.getRelativePath(destinationPath),
          dateTaken: DateTime.now(), // Use import time as date taken
          description: (description != null && description.isNotEmpty)
              ? description
              : originalNameWithoutExt,
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
        final campaignIndex = campaigns.indexWhere((c) => c.id == _campaign.id);
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
      _closeProcessingDialog();

    } catch (e) {
      _closeProcessingDialog();
      
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

// Runs in the main isolate, delegates the actual file copy to a background isolate
Future<bool> _copyFileInBackground(String src, String dst) async {
  try {
    final result = await compute(_copyFileTask, {'src': src, 'dst': dst});
    return result == true;
  } catch (e) {
    return false;
  }
}

// Top-level function executed inside a background isolate by `compute`.
// Uses synchronous file operations inside the isolate to avoid async overhead there.
bool _copyFileTask(Map<String, String> args) {
  final src = args['src']!;
  final dst = args['dst']!;
  try {
    final File source = File(src);
    if (!source.existsSync()) return false;
    source.copySync(dst);
    return true;
  } catch (e) {
    return false;
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
      for (final photo in _campaignPhotos) {
        await UserStorage.deletePhoto(photo);
      }
      
      // Delete the campaign (this will also delete the campaign directory)
      await CampaignStorage.deleteCampaign(_campaign.id);
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _editPhotoDescription(int index, String newDescription) async {
    final photo = _campaignPhotos[index];
    final updatedPhoto = Photo(
      id: photo.id,
      relativePath: photo.relativePath,
      dateTaken: photo.dateTaken,
      description: newDescription,
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
    
    // Delete the photo and its file
    await UserStorage.deletePhoto(photo);
    
    // Also remove photo id from the campaign's photoIds and save campaigns
    final campaigns = await CampaignStorage.loadCampaigns();
    final campaignIndex = campaigns.indexWhere((c) => c.id == _campaign.id);
    if (campaignIndex != -1) {
      campaigns[campaignIndex].photoIds.remove(photo.id);
      await CampaignStorage.saveCampaigns(campaigns);
    }

    await _loadCampaignPhotos();
  }

  Future<void> _replicateCampaign() async {
    try {
      // Show loading dialog
      _showProcessingDialog('Finding latest campaign...');

      // Load all campaigns and find the latest one (excluding current)
      final campaigns = await CampaignStorage.loadCampaigns();
      campaigns.sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
      
      Campaign? latestCampaign;
      for (final campaign in campaigns) {
        if (campaign.id != _campaign.id && campaign.photoIds.isNotEmpty) {
          latestCampaign = campaign;
          break;
        }
      }

      if (latestCampaign == null) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No previous campaign with photos found to replicate'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Load all photos and get photos from the latest campaign
      final allPhotos = await UserStorage.loadPhotos();
    final latestCampaignPhotos = allPhotos
      .where((photo) => latestCampaign!.photoIds.contains(photo.id))
      .toList();

      if (latestCampaignPhotos.isEmpty) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No photos found in the latest campaign'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        _closeProcessingDialog(); // Close loading dialog
        // Show confirmation dialog
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Replicate Campaign'),
            content: Text(
              'This will copy ${latestCampaignPhotos.length} template photos from your latest campaign '
              '(${latestCampaign!.date.day}/${latestCampaign.date.month}/${latestCampaign.date.year}) '
              'to help you take consistent photos. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Replicate'),
              ),
            ],
          ),
        );

        if (confirm != true) return;

        // Show copying progress dialog
        _showProcessingDialog('Copying template photos...');
      }

      // Ensure campaign directory exists
      await UserStorage.ensureCampaignDirectoryExists(_campaign.id);
      final campaignDir = await UserStorage.getCampaignDirectory(_campaign.id);

      List<Photo> templatePhotos = [];
      List<String> newPhotoIds = [];

      for (int i = 0; i < latestCampaignPhotos.length; i++) {
        final originalPhoto = latestCampaignPhotos[i];
        
        // Get the original file path
        final originalFile = File('${UserStorage.userDirectory}/${originalPhoto.relativePath}');
        
        if (!await originalFile.exists()) {
          continue; // Skip if original file doesn't exist
        }

  // Create unique filename for template
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = path.extension(originalPhoto.relativePath);
        final fileName = 'template_${timestamp}_$i$extension';
        final destinationPath = path.join(campaignDir, fileName);

        // Copy the image file
        await originalFile.copy(destinationPath);

        // Create template photo object with preserved spots
        final templatePhoto = Photo(
          id: 'template_photo_${timestamp}_$i',
          relativePath: UserStorage.getRelativePath(destinationPath),
          dateTaken: DateTime.now(), // Use current time for template creation
          description: originalPhoto.description, // Keep same description
          isTemplate: true, // Mark as template
          spots: originalPhoto.spots.map((spot) => Spot(
            position: spot.position,
            radius: spot.radius,
            moleId: spot.moleId,
          )).toList(), // Create deep copies of spots from original photo
        );

        templatePhotos.add(templatePhoto);
        newPhotoIds.add(templatePhoto.id);
      }

        if (templatePhotos.isNotEmpty) {
        // Add template photos to storage
        allPhotos.addAll(templatePhotos);
        await UserStorage.savePhotos(allPhotos);

        // Update campaign photoIds by adding the new template photo IDs
        final updatedCampaigns = await CampaignStorage.loadCampaigns();
        final campaignIndex = updatedCampaigns.indexWhere((c) => c.id == _campaign.id);
        if (campaignIndex != -1) {
          updatedCampaigns[campaignIndex].photoIds.addAll(newPhotoIds);
          await CampaignStorage.saveCampaigns(updatedCampaigns);
        }

        // Reload campaign photos
        await _loadCampaignPhotos();

        if (mounted) {
          _closeProcessingDialog(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully copied ${templatePhotos.length} template photos'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          _closeProcessingDialog(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to copy template photos'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

    } catch (e) {
      _closeProcessingDialog();
      
      if (mounted) {
        _closeProcessingDialog();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error replicating campaign: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProcessingDialog(String message) {
    if (!mounted || _isProcessingDialogShown) return;
    _isProcessingDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _closeProcessingDialog() {
    if (!_isProcessingDialogShown) return;
    if (mounted && Navigator.canPop(context)) {
      try {
        Navigator.pop(context);
      } catch (_) {}
    }
    _isProcessingDialogShown = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Campaign ${_campaign.date.day}/${_campaign.date.month}/${_campaign.date.year}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isCampaignFromToday)
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(campaignId: _campaign.id),
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
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campaign Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Date: ${_campaign.date.day}/${_campaign.date.month}/${_campaign.date.year}'),
                Text('Time: ${_campaign.date.hour}:${_campaign.date.minute.toString().padLeft(2, '0')}'),
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
                        Text(
                          _isCampaignFromToday 
                            ? 'Take photos with the camera or import from gallery'
                            : 'You can only import photos for past campaigns',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isCampaignFromToday)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CameraScreen(campaignId: _campaign.id),
                                        ),
                                      ).then((_) => _loadCampaignPhotos());
                                    },
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Take Photo'),
                                  ),
                                if (_isCampaignFromToday) const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: _importPhotos,
                                  icon: const Icon(Icons.photo_library_outlined),
                                  label: const Text('Import Photos'),
                                ),
                              ],
                            ),
                            if (_isCampaignFromToday && !_hasNonTemplatePhotos) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _replicateCampaign,
                                icon: const Icon(Icons.copy),
                                label: const Text('Replicate Campaign'),
                              ),
                            ],
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
                        key: Key('photo_${photo.id}'),
                        photo: photo,
                        campaignId: _campaign.id,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SinglePhotoScreen(
                                photo: photo,
                                moles: _moles,
                                index: index,
                                onEditDescription: _editPhotoDescription,
                                onDelete: _deletePhoto,
                              ),
                            ),
                          ).then((_) => _loadCampaignPhotos());
                        },
                        onCameraReturn: _loadCampaignPhotos, // Add refresh callback
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isCampaignFromToday ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraScreen(campaignId: _campaign.id),
            ),
          ).then((_) => _loadCampaignPhotos());
        },
        tooltip: 'Take Photo',
        child: const Icon(Icons.camera_alt),
      ) : null,
    );
  }
}