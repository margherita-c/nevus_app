import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:exif/exif.dart';

class PhotoMetadataService {
  /// Extracts the actual capture date from photo EXIF data
  static Future<DateTime?> getPhotoCaptureDate(File imageFile) async {
    try {
      developer.log('Reading EXIF from: ${imageFile.path}', name: 'PhotoMetadataService');
      final Uint8List bytes = await imageFile.readAsBytes();
      final Map<String, IfdTag> data = await readExifFromBytes(bytes);
      
      developer.log('EXIF data keys: ${data.keys.toList()}', name: 'PhotoMetadataService');
      
      // Try different EXIF date fields in order of preference
      final dateFields = [
        'EXIF DateTimeOriginal',
        'EXIF DateTime',
        'Image DateTime',
      ];
      
      for (final field in dateFields) {
        final dateTag = data[field];
        if (dateTag != null) {
          final dateString = dateTag.toString();
          developer.log('Found date field $field: $dateString', name: 'PhotoMetadataService');
          final parsedDate = _parseExifDate(dateString);
          if (parsedDate != null) {
            developer.log('Parsed date: $parsedDate', name: 'PhotoMetadataService');
            return parsedDate;
          }
        }
      }
      
      // If no EXIF date found, fall back to file modification date
      final fallbackDate = await imageFile.lastModified();
      developer.log('No EXIF date found, using file date: $fallbackDate', name: 'PhotoMetadataService');
      return fallbackDate;
    } catch (e) {
      developer.log('EXIF reading failed: $e, using file date', name: 'PhotoMetadataService');
      // If EXIF reading fails, fall back to file modification date
      return await imageFile.lastModified();
    }
  }
  
  /// Parses EXIF date string format (YYYY:MM:DD HH:MM:SS) to DateTime
  static DateTime? _parseExifDate(String dateString) {
    try {
      // EXIF date format is usually "YYYY:MM:DD HH:MM:SS"
      // Convert to "YYYY-MM-DD HH:MM:SS" format
      final parts = dateString.split(' ');
      if (parts.length >= 2) {
        final datePart = parts[0].replaceAll(':', '-');
        final timePart = parts[1];
        final isoString = '${datePart}T$timePart';
        return DateTime.parse(isoString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Gets the earliest capture date from a list of image files
  static Future<DateTime> getEarliestPhotoDate(List<File> imageFiles) async {
    developer.log('Processing ${imageFiles.length} files for date extraction', name: 'PhotoMetadataService');
    DateTime? earliestDate;
    
    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      developer.log('Processing file ${i + 1}/${imageFiles.length}: ${file.path}', name: 'PhotoMetadataService');
      
      final captureDate = await getPhotoCaptureDate(file);
      developer.log('File ${i + 1} date: $captureDate', name: 'PhotoMetadataService');
      
      if (captureDate != null) {
        if (earliestDate == null || captureDate.isBefore(earliestDate)) {
          earliestDate = captureDate;
          developer.log('New earliest date: $earliestDate', name: 'PhotoMetadataService');
        }
      }
    }
    
    // If we couldn't get any dates, use current time as fallback
    final finalDate = earliestDate ?? DateTime.now();
    developer.log('Final campaign date: $finalDate', name: 'PhotoMetadataService');
    return finalDate;
  }
}
