// Create: lib/services/campaign_service.dart
import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../storage/campaign_storage.dart';
import '../storage/user_storage.dart';
import '../utils/dialog_utils.dart';
import '../screens/camera_screen.dart';

class CampaignService {
  static bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static Future<Campaign?> createNewCampaign(BuildContext context) async {
    final selectedDate = await DialogUtils.showCreateCampaignDialog(context);
    if (selectedDate == null) return null;

    // Check if a campaign with this date already exists
    final existingCampaigns = await CampaignStorage.loadCampaigns();
    final dateExists = existingCampaigns.any((campaign) => 
      _isSameDate(campaign.date, selectedDate)
    );
    
    if (dateExists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('A campaign for ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} already exists'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return null;
    }
    
    final newCampaign = Campaign(
      id: 'campaign_${selectedDate.millisecondsSinceEpoch}',
      date: selectedDate,
    );
    
    await CampaignStorage.addCampaign(newCampaign);
    
    // Navigate to camera to start taking photos for this campaign
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(campaignId: newCampaign.id),
        ),
      );
    }
    
    return newCampaign;
  }

  static Future<int> getActualPhotoCount(String campaignId) async {
    final allPhotos = await UserStorage.loadPhotos();
    return allPhotos.where((photo) => photo.campaignId == campaignId).length;
  }
}