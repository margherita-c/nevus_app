import 'package:flutter/material.dart';
import '../models/mole.dart';
import '../models/campaign.dart';
import '../models/photo.dart';
import '../storage/user_storage.dart';
import '../storage/campaign_storage.dart';
import '../widgets/app_bar_title.dart';
import 'mole_detail_screen.dart';

class MoleListScreen extends StatefulWidget {
  const MoleListScreen({super.key});

  @override
  State<MoleListScreen> createState() => _MoleListScreenState();
}

class _MoleListScreenState extends State<MoleListScreen> {
  List<Mole> _moles = [];
  List<Photo> _latestCampaignPhotos = [];
  Campaign? _latestCampaign;
  bool _isLoading = true;
  Map<String, int> _molePhotoCount = {}; // Track how many photos each mole appears in

  @override
  void initState() {
    super.initState();
    _loadMolesFromLatestCampaign();
  }

  Future<void> _loadMolesFromLatestCampaign() async {
    setState(() => _isLoading = true);

    try {
      // Load all campaigns and find the latest one
      final campaigns = await CampaignStorage.loadCampaigns();
      if (campaigns.isEmpty) {
        setState(() {
          _moles = [];
          _isLoading = false;
        });
        return;
      }

      // Sort campaigns by date to get the latest
      campaigns.sort((a, b) => b.date.compareTo(a.date));
      _latestCampaign = campaigns.first;

      // Load all photos and filter by latest campaign
      final allPhotos = await UserStorage.loadPhotos();
      _latestCampaignPhotos = allPhotos
          .where((photo) => photo.campaignId == _latestCampaign!.id)
          .toList();

      // Extract unique mole IDs from spots in latest campaign photos
      Set<String> uniqueMoleIds = {};
      for (final photo in _latestCampaignPhotos) {
        for (final spot in photo.spots) {
          uniqueMoleIds.add(spot.moleId);
        }
      }

      // Load existing moles
      final allMoles = await UserStorage.loadMoles();
      
      // Filter moles that appear in the latest campaign or create new ones
      List<Mole> campaignMoles = [];
      Map<String, int> photoCount = {};

      for (final moleId in uniqueMoleIds) {
        // Count photos for this mole
        int count = 0;
        for (final photo in _latestCampaignPhotos) {
          if (photo.spots.any((spot) => spot.moleId == moleId)) {
            count++;
          }
        }
        photoCount[moleId] = count;

        // Find existing mole or create new one
        Mole? existingMole = allMoles.cast<Mole?>().firstWhere(
          (mole) => mole?.id == moleId,
          orElse: () => null,
        );

        if (existingMole != null) {
          campaignMoles.add(existingMole);
        } else {
          // Create a new mole for IDs that don't exist yet
          final newMole = Mole(
            id: moleId,
            name: 'Mole ${moleId.split('_').last}',
            description: 'New mole tracked in latest campaign',
          );
          campaignMoles.add(newMole);
          
          // Add to all moles and save
          allMoles.add(newMole);
          await UserStorage.saveMoles(allMoles);
        }
      }

      setState(() {
        _moles = campaignMoles;
        _molePhotoCount = photoCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _moles = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading moles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToMoleDetail(Mole mole) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoleDetailScreen(mole: mole),
      ),
    );
    // Refresh the list when returning from detail screen
    _loadMolesFromLatestCampaign();
  }

  Future<void> _createNewMole() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final descriptionController = TextEditingController();
        
        return AlertDialog(
          title: const Text('Create New Mole'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Mole Name',
                  hintText: 'e.g., Left shoulder mole',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the mole characteristics',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                  });
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final newMole = Mole(
        id: 'mole_${DateTime.now().millisecondsSinceEpoch}',
        name: result['name']!,
        description: result['description']!,
      );

      // Save the new mole
      final allMoles = await UserStorage.loadMoles();
      allMoles.add(newMole);
      await UserStorage.saveMoles(allMoles);

      // Refresh the list
      _loadMolesFromLatestCampaign();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New mole created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(title: 'Tracked Moles'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _createNewMole,
            icon: const Icon(Icons.add),
            tooltip: 'Create New Mole',
          ),
        ],
      ),
      body: Column(
        children: [
          // Campaign Info Header
          if (_latestCampaign != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest Campaign',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${_latestCampaign!.date.day}/${_latestCampaign!.date.month}/${_latestCampaign!.date.year}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Photos: ${_latestCampaignPhotos.length} | Moles tracked: ${_moles.length}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

          // Moles List
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _moles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_pin_circle, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No moles tracked yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _latestCampaign == null 
                            ? 'Create a campaign and take photos to start tracking moles'
                            : 'Add spots to your photos to start tracking moles',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _createNewMole,
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Mole'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _moles.length,
                    itemBuilder: (context, index) {
                      final mole = _moles[index];
                      final photoCount = _molePhotoCount[mole.id] ?? 0;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              mole.name.isNotEmpty ? mole.name[0].toUpperCase() : 'M',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            mole.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (mole.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  mole.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Appears in $photoCount photo${photoCount != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _navigateToMoleDetail(mole),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewMole,
        tooltip: 'Create New Mole',
        child: const Icon(Icons.add),
      ),
    );
  }
}