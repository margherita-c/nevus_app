import 'dart:io';
import 'dart:typed_data';
import 'package:exif/exif.dart';

class PhotoMetadataService {
  /// Extracts the actual capture date from photo EXIF data
  static Future<DateTime?> getPhotoCaptureDate(File imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final Map<String, IfdTag> data = await readExifFromBytes(bytes);
      
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
          return _parseExifDate(dateString);
        }
      }
      
      // If no EXIF date found, fall back to file modification date
      return await imageFile.lastModified();
    } catch (e) {
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
    DateTime? earliestDate;
    
    for (final file in imageFiles) {
      final captureDate = await getPhotoCaptureDate(file);
      if (captureDate != null) {
        if (earliestDate == null || captureDate.isBefore(earliestDate)) {
          earliestDate = captureDate;
        }
      }
    }
    
    // If we couldn't get any dates, use current time as fallback
    return earliestDate ?? DateTime.now();
  }
}
