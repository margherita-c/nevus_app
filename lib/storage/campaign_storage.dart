import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import '../models/campaign.dart';
import 'user_storage.dart';

class CampaignStorage {
  /// Gets the campaigns JSON file for the current user
  static Future<File> get _localFile async {
    final userDir = UserStorage.userDirectory;
    return File('$userDir/campaigns.json');
  }

  static Future<List<Campaign>> loadCampaigns() async {
    try {
      await UserStorage.ensureUserDirectoryExists();
      final file = await _localFile;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonData = json.decode(contents);
      return jsonData.map((json) => Campaign.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveCampaigns(List<Campaign> campaigns) async {
    await UserStorage.ensureUserDirectoryExists();
    final file = await _localFile;
    final jsonData = campaigns.map((campaign) => campaign.toJson()).toList();
    var encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(jsonData));
  }

  static Future<void> addCampaign(Campaign campaign) async {
    final campaigns = await loadCampaigns();
    campaigns.add(campaign);
    await saveCampaigns(campaigns);
  }

  static Future<void> deleteCampaign(String campaignId) async {
    // Delete the campaign directory and all its files
    try {
      final campaignDir = await UserStorage.getCampaignDirectory(campaignId);
      final directory = Directory(campaignDir);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        developer.log('Deleted campaign directory: $campaignDir', name: 'CampaignStorage');
      }
    } catch (e) {
      developer.log('Error deleting campaign directory for $campaignId: $e', name: 'CampaignStorage');
      // Continue with removing from storage even if file deletion fails
    }

    // Remove from campaigns storage
    final campaigns = await loadCampaigns();
    campaigns.removeWhere((campaign) => campaign.id == campaignId);
    await saveCampaigns(campaigns);
  }

  static Future<void> updateCampaign(Campaign updatedCampaign) async {
    final campaigns = await loadCampaigns();
    final index = campaigns.indexWhere((campaign) => campaign.id == updatedCampaign.id);
    if (index != -1) {
      campaigns[index] = updatedCampaign;
      await saveCampaigns(campaigns);
    }
  }

  static Future<Campaign?> getCampaignById(String campaignId) async {
    final campaigns = await loadCampaigns();
    try {
      return campaigns.firstWhere((campaign) => campaign.id == campaignId);
    } catch (e) {
      return null;
    }
  }
}