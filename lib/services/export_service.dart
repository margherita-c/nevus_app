import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ExportService {
  static Future<void> exportUserData(String username) async {
    try {
      // Get the app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final userDir = Directory('${appDir.path}/users/$username');
      
      if (!await userDir.exists()) {
        throw Exception('User data not found');
      }

      // Create archive
      final archive = Archive();
      
      // Add all files from user directory to archive, starting from username as root
      await _addDirectoryToArchive(archive, userDir, username);
      
      // Encode archive to zip
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        throw Exception('Failed to create zip file');
      }
      
      // Save zip to temporary directory
      final tempDir = await getTemporaryDirectory();
      
      // Format date as YYYY-MM-DD
      final dateFormatter = DateFormat('yyyy-MM-dd');
      final currentDate = dateFormatter.format(DateTime.now());
      
      final zipFile = File('${tempDir.path}/${username}_export_$currentDate.zip');
      await zipFile.writeAsBytes(zipData);
      
      // Share the zip file
      await Share.shareXFiles(
        [XFile(zipFile.path)],
        text: 'Nevus app data export for $username',
        subject: 'Nevus Data Export',
      );
      
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }
  
  static Future<void> _addDirectoryToArchive(Archive archive, Directory dir, String basePath) async {
    await for (final entity in dir.list(recursive: false)) {
      final relativePath = entity.path.split('/').last;
      final archivePath = '$basePath/$relativePath';
      
      if (entity is File) {
        final bytes = await entity.readAsBytes();
        final file = ArchiveFile(archivePath, bytes.length, bytes);
        archive.addFile(file);
      } else if (entity is Directory) {
        await _addDirectoryToArchive(archive, entity, archivePath);
      }
    }
  }
}