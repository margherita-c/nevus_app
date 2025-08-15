import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../storage/campaign_storage.dart';
import 'campaign_detail_screen.dart';
import '../services/campaign_service.dart'; // Add this import
import '../widgets/app_bar_title.dart'; // Add this import

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
    final newCampaign = await CampaignService.createNewCampaign(context);
    if (newCampaign != null) {
      await _loadCampaigns();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(title: 'Campaigns'), // Updated to use widget
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
                      future: CampaignService.getActualPhotoCount(campaign.id), // Updated to use service
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
                          future: CampaignService.getActualPhotoCount(campaign.id), // Updated to use service
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