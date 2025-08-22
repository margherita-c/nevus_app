import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../services/export_service.dart';
import '../services/photo_metadata_service.dart';
import 'campaign_detail_screen.dart';
import 'photo_gallery_screen.dart';
import 'auth_screen.dart';
import 'campaigns_screen.dart';
import 'edit_account_screen.dart';
import 'mole_list_screen.dart';
import '../storage/user_storage.dart';
import '../storage/campaign_storage.dart';
import '../models/campaign.dart';
import '../models/user.dart';
import '../services/campaign_service.dart';
import '../widgets/app_bar_title.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Campaign> _campaigns = [];
  bool _isLoading = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _isLoading = true);
    final campaigns = await CampaignStorage.loadCampaigns();
    setState(() {
      _campaigns = campaigns;
      _isLoading = false;
    });
  }

  Future<void> _createNewCampaign() async {
    final newCampaign = await CampaignService.createNewCampaign(context);
    if (newCampaign != null) {
      await _loadCampaigns();
    }
  }

  Future<void> _editAccount() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditAccountScreen()),
    );
    // Refresh the page in case user data was updated
    setState(() {});
  }

  Future<void> _exportUserData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final currentUser = UserStorage.currentUser;
      await ExportService.exportUserData(currentUser.username);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      UserStorage.setCurrentUser(User.guest());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  Future<void> _importCampaign() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _isLoading = true);
      
      try {
        // Convert file picker results to File objects
        final imageFiles = result.files
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();
        
        // Get the earliest capture date from photo EXIF data
        final campaignDate = await PhotoMetadataService.getEarliestPhotoDate(imageFiles);

        developer.log('Creating campaign with date: $campaignDate', name: 'HomeScreen.ImportCampaign');

        // Create the campaign using CampaignService
        final campaign = await CampaignService.createCampaignFromImport(
          campaignDate,
          imageFiles,
        );
        
        developer.log('Campaign created: ${campaign.id}', name: 'HomeScreen.ImportCampaign');
        
        setState(() => _isLoading = false);
        
        if (mounted) {
          final dateStr = '${campaign.date.day}/${campaign.date.month}/${campaign.date.year}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Campaign "$dateStr" imported with ${result.files.length} photos')),
          );
          
          // Reload campaigns to show the new one
          await _loadCampaigns();
        }
      } catch (e) {
        developer.log('Import error: $e', name: 'HomeScreen.ImportCampaign', error: e);
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to import campaign: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = UserStorage.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(title: 'Nevus App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              } else if (value == 'edit_account') {
                _editAccount();
              } else if (value == 'export_data') {
                _exportUserData();
              }
            },
            itemBuilder: (context) => [
              // Only show edit account and export for non-guest users
              if (!currentUser.isGuest) ...[
                const PopupMenuItem(
                  value: 'edit_account',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit Account'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'export_data',
                  child: Row(
                    children: [
                      Icon(Icons.file_download, size: 20),
                      const SizedBox(width: 8),
                      const Text('Export Data'),
                      if (_isExporting) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      currentUser.isGuest ? Icons.login : Icons.logout,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(currentUser.isGuest ? 'Login' : 'Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${currentUser.displayName}!',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Track your moles and monitor changes over time.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick Actions - 2x2 Grid
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createNewCampaign,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('New Campaign'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _importCampaign,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Import Campaign'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PhotoGalleryScreen()),
                      );
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('All Photos'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MoleListScreen()),
                      );
                    },
                    icon: const Icon(Icons.person_pin_circle),
                    label: const Text('Moles'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Campaigns Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Campaigns',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CampaignsScreen()),
                    ).then((_) => _loadCampaigns());
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Campaigns List
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _campaigns.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.campaign, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No campaigns yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            'Create your first campaign to start tracking',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _campaigns.take(3).length, // Show only 3 recent
                      itemBuilder: (context, index) {
                        final campaign = _campaigns[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.folder),
                            title: Text('Campaign ${campaign.date.day}/${campaign.date.month}/${campaign.date.year}'),
                            subtitle: FutureBuilder<int>(
                              future: CampaignService.getActualPhotoCount(campaign.id),
                              builder: (context, snapshot) {
                                final photoCount = snapshot.data ?? campaign.photoIds.length;
                                return Text('$photoCount photos');
                              },
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CampaignDetailScreen(campaign: campaign),
                                ),
                              ).then((_) => _loadCampaigns());
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}