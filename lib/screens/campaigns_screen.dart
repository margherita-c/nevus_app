import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../storage/campaign_storage.dart';
import '../storage/user_storage.dart';
import 'camera_screen.dart';
import 'campaign_detail_screen.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  List<Campaign> _campaigns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _isLoading = true);
    final campaigns = await CampaignStorage.loadCampaigns();
    setState(() {
      _campaigns = campaigns..sort((a, b) => b.date.compareTo(a.date)); // Sort by date, newest first
      _isLoading = false;
    });
  }

  Future<void> _createNewCampaign() async {
    final selectedDate = await _showCreateCampaignDialog();
    if (selectedDate != null) {
      // Check if a campaign with this date already exists
      final existingCampaigns = await CampaignStorage.loadCampaigns();
      final dateExists = existingCampaigns.any((campaign) => 
        _isSameDate(campaign.date, selectedDate)
      );
      
      if (dateExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('A campaign for ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} already exists'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      final newCampaign = Campaign(
        id: 'campaign_${selectedDate.millisecondsSinceEpoch}',
        date: selectedDate,
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

  Future<DateTime?> _showCreateCampaignDialog() async {
    DateTime selectedDate = DateTime.now();
    
    return await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Campaign'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select the date for this mole tracking session'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedDate),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _getActualPhotoCount(String campaignId) async {
    final allPhotos = await UserStorage.loadPhotos();
    return allPhotos.where((photo) => photo.campaignId == campaignId).length;
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Campaigns'),
            if (!UserStorage.currentUser.isGuest) ...[
              const Text(' - '),
              Text(UserStorage.currentUser.username),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewCampaign,
            tooltip: 'New Campaign',
          ),
        ],
      ),
      body: _isLoading
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
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first campaign to start tracking your moles',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _campaigns.length,
              itemBuilder: (context, index) {
                final campaign = _campaigns[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: FutureBuilder<int>(
                      future: _getActualPhotoCount(campaign.id),
                      builder: (context, snapshot) {
                        final photoCount = snapshot.data ?? campaign.photoIds.length;
                        return CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            '$photoCount',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                    title: Text('Campaign ${campaign.date.day}/${campaign.date.month}/${campaign.date.year}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<int>(
                          future: _getActualPhotoCount(campaign.id),
                          builder: (context, snapshot) {
                            final photoCount = snapshot.data ?? campaign.photoIds.length;
                            return Text('$photoCount photos');
                          },
                        ),
                        Text(
                          'Created: ${campaign.date.hour}:${campaign.date.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewCampaign,
        tooltip: 'New Campaign',
        child: const Icon(Icons.add),
      ),
    );
  }
}