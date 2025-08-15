import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../models/photo.dart';
import '../storage/user_storage.dart';
import '../storage/campaign_storage.dart';
import 'camera_screen.dart';
import 'single_photo_screen.dart';
import '../widgets/photo_grid_item.dart'; // Add this import

class CampaignDetailScreen extends StatefulWidget {
  final Campaign campaign;

  const CampaignDetailScreen({super.key, required this.campaign});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  List<Photo> _campaignPhotos = [];
  bool _isLoading = true;

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
            tooltip: 'Add Photo',
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
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No photos in this campaign',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the camera button to add photos',
                          style: TextStyle(color: Colors.grey),
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
                      return PhotoGridItem( // Updated to use widget
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
        tooltip: 'Add Photo',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}