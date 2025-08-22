// Create: lib/services/campaign_service.dart
import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../models/photo.dart';
import '../storage/campaign_storage.dart';
import '../storage/user_storage.dart';
import '../utils/dialog_utils.dart';
import '../screens/camera_screen.dart';
import '../services/photo_metadata_service.dart';
import 'dart:io';

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

  static Future<Campaign> createCampaignFromImport(DateTime date, List<File> imageFiles) async {
  final campaign = Campaign(
    id: 'campaign_${date.millisecondsSinceEpoch}',
    date: date,
    photoIds: [],
  );
  
  // First, add the campaign to storage
  await CampaignStorage.addCampaign(campaign);
  
  // Ensure campaign directory exists
  await UserStorage.ensureCampaignDirectoryExists(campaign.id);
  
  // Copy photos to campaign directory and create Photo objects
  final campaignDir = await UserStorage.getCampaignDirectory(campaign.id);
  List<String> photoIds = [];
  
  for (int i = 0; i < imageFiles.length; i++) {
    final sourceFile = imageFiles[i];
    final extension = sourceFile.path.split('.').last;
    final photoId = 'photo_${date.millisecondsSinceEpoch}_$i';
    final targetFile = File('$campaignDir/$photoId.$extension');
    
    await targetFile.create(recursive: true);
    await sourceFile.copy(targetFile.path);
    
    // Get the actual capture date from the photo's EXIF data
    final photoCaptureDate = await PhotoMetadataService.getPhotoCaptureDate(sourceFile) ?? date;
    
    // Create Photo object and add to storage
    final photo = Photo(
      id: photoId,
      path: targetFile.path,
      dateTaken: photoCaptureDate,
      description: 'Imported photo ${i + 1}',
      campaignId: campaign.id,
    );
    
    // Add photo to photos storage
    final photos = await UserStorage.loadPhotos();
    photos.add(photo);
    await UserStorage.savePhotos(photos);
    
    photoIds.add(photoId);
  }
  
  // Update campaign with photo IDs
  campaign.photoIds.addAll(photoIds);
  await CampaignStorage.updateCampaign(campaign);
  
  return campaign;
}
}