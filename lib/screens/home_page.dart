import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'photo_gallery_screen.dart';
import 'campaigns_screen.dart'; // Add this import
import '../storage/user_storage.dart';
import '../storage/campaign_storage.dart'; // Add this import
import '../models/campaign.dart'; // Add this import
import 'auth_screen.dart';
import '../models/user.dart';
import 'campaign_detail_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Campaign> _campaigns = [];
  bool _isLoading = false;

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
    final campaignName = await _showCreateCampaignDialog();
    if (campaignName != null && campaignName.isNotEmpty) {
      final newCampaign = Campaign(
        id: 'campaign_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
      );
      
      await CampaignStorage.addCampaign(newCampaign);
      await _loadCampaigns();
      
      // Navigate to camera to start taking photos for this campaign
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(campaignId: newCampaign.id),
          ),
        ).then((_) => _loadCampaigns());
      }
    }
  }

  Future<String?> _showCreateCampaignDialog() async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Campaign'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Start a new mole tracking session'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Campaign Name (Optional)',
                hintText: 'e.g., Monthly Check - ${DateTime.now().month}/${DateTime.now().year}',
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
            child: const Text('Create'),
          ),
        ],
      ),
    );
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
      // Clear current user
      UserStorage.setCurrentUser(User.guest());
      
      // Navigate back to auth screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  Future<int> _getActualPhotoCount(String campaignId) async {
    final allPhotos = await UserStorage.loadPhotos();
    return allPhotos.where((photo) => photo.campaignId == campaignId).length;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = UserStorage.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Nevus App'),
            if (!currentUser.isGuest) ...[
              const Text(' - '),
              Text(
                currentUser.username,
                style: const TextStyle(fontWeight: FontWeight.normal),
              ),
            ] else ...[
              const Text(' - Guest'),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
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
                      'Welcome, ${currentUser.isGuest ? 'Guest' : currentUser.username}!',
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
            
            // Quick Actions
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
                              future: _getActualPhotoCount(campaign.id), // Use actual photo count
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