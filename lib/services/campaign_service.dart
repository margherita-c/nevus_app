import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../models/photo.dart';
import '../storage/campaign_storage.dart';
import '../storage/user_storage.dart';
import '../utils/dialog_utils.dart';
import '../screens/camera_screen.dart';
import '../services/photo_metadata_service.dart';
import 'dart:io';
import 'dart:developer' as developer;

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
  developer.log('Creating campaign from import with date: $date and ${imageFiles.length} files', name: 'CampaignService');
  
  final campaign = Campaign(
    id: 'campaign_${date.millisecondsSinceEpoch}',
    date: date,
    photoIds: [],
  );
  
  developer.log('Campaign object created with ID: ${campaign.id}', name: 'CampaignService');
  
  // First, add the campaign to storage
  await CampaignStorage.addCampaign(campaign);
  developer.log('Campaign added to storage', name: 'CampaignService');
  
  // Ensure campaign directory exists
  await UserStorage.ensureCampaignDirectoryExists(campaign.id);
  developer.log('Campaign directory created', name: 'CampaignService');
  
  // Copy photos to campaign directory and create Photo objects
  final campaignDir = await UserStorage.getCampaignDirectory(campaign.id);
  developer.log('Campaign directory path: $campaignDir', name: 'CampaignService');
  
  List<String> photoIds = [];
  
  for (int i = 0; i < imageFiles.length; i++) {
    final sourceFile = imageFiles[i];
    final extension = sourceFile.path.split('.').last;
    final photoId = 'photo_${date.millisecondsSinceEpoch}_$i';
    final targetFile = File('$campaignDir/$photoId.$extension');
    
    developer.log('Processing photo ${i + 1}/${imageFiles.length}: $photoId', name: 'CampaignService');
    
    await targetFile.create(recursive: true);
    await sourceFile.copy(targetFile.path);
    developer.log('Photo copied to: ${targetFile.path}', name: 'CampaignService');
    
    // Get the actual capture date from the photo's EXIF data
    final photoCaptureDate = await PhotoMetadataService.getPhotoCaptureDate(sourceFile) ?? date;
    developer.log('Photo capture date: $photoCaptureDate', name: 'CampaignService');
    
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
    developer.log('Photo object created and saved: $photoId', name: 'CampaignService');
    
    photoIds.add(photoId);
  }
  
  // Update campaign with photo IDs
  campaign.photoIds.addAll(photoIds);
  await CampaignStorage.updateCampaign(campaign);
  developer.log('Campaign updated with ${photoIds.length} photo IDs', name: 'CampaignService');
  
  return campaign;
}
}