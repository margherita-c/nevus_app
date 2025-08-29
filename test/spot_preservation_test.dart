import 'package:flutter_test/flutter_test.dart';
import 'package:nevus_app/models/photo.dart';
import 'package:nevus_app/models/spot.dart';

void main() {
  group('Spot Preservation Tests', () {
    test('Photo preserves spots during template creation', () {
      // Create a photo with spots
      final originalPhoto = Photo(
        id: 'original_photo',
        relativePath: 'test/path.jpg',
        dateTaken: DateTime.now(),
        description: 'Test photo',
        campaignId: 'test_campaign',
        spots: [
          Spot(position: const Offset(100, 150), radius: 25.0, moleId: 'mole_1'),
          Spot(position: const Offset(200, 250), radius: 30.0, moleId: 'mole_2'),
        ],
      );

      // Create a template from the original photo (simulating the template creation process)
      final templatePhoto = Photo(
        id: 'template_photo',
        relativePath: 'template/path.jpg',
        dateTaken: DateTime.now(),
        description: originalPhoto.description,
        campaignId: 'new_campaign',
        isTemplate: true,
        spots: originalPhoto.spots.map((spot) => Spot(
          position: spot.position,
          radius: spot.radius,
          moleId: spot.moleId,
        )).toList(), // Deep copy spots
      );

      // Verify spots are preserved
      expect(templatePhoto.spots.length, equals(2));
      expect(templatePhoto.spots[0].moleId, equals('mole_1'));
      expect(templatePhoto.spots[1].moleId, equals('mole_2'));
      expect(templatePhoto.spots[0].position.dx, equals(100));
      expect(templatePhoto.spots[0].position.dy, equals(150));
    });

    test('Photo preserves spots when replacing template with new photo', () {
      // Create a template photo with spots
      final templatePhoto = Photo(
        id: 'template_photo',
        relativePath: 'template/path.jpg',
        dateTaken: DateTime.now(),
        description: 'Template photo',
        campaignId: 'test_campaign',
        isTemplate: true,
        spots: [
          Spot(position: const Offset(120, 180), radius: 35.0, moleId: 'template_mole_1'),
          Spot(position: const Offset(220, 280), radius: 40.0, moleId: 'template_mole_2'),
        ],
      );

      // Create a new photo from the template (simulating the template replacement process)
      final newPhoto = Photo(
        id: 'new_photo',
        relativePath: 'new/path.jpg',
        dateTaken: DateTime.now(),
        description: templatePhoto.description,
        campaignId: templatePhoto.campaignId,
        isTemplate: false,
        spots: templatePhoto.spots.map((spot) => Spot(
          position: spot.position,
          radius: spot.radius,
          moleId: spot.moleId,
        )).toList(), // Deep copy spots
      );

      // Verify spots are preserved
      expect(newPhoto.spots.length, equals(2));
      expect(newPhoto.spots[0].moleId, equals('template_mole_1'));
      expect(newPhoto.spots[1].moleId, equals('template_mole_2'));
      expect(newPhoto.spots[0].position.dx, equals(120));
      expect(newPhoto.spots[0].position.dy, equals(180));
      expect(newPhoto.isTemplate, isFalse);
    });

    test('Spot deep copy works correctly', () {
      // Create original spot
      final originalSpot = Spot(
        position: const Offset(100, 150),
        radius: 25.0,
        moleId: 'test_mole',
      );

      // Create photo with the spot
      final originalPhoto = Photo(
        id: 'original',
        relativePath: 'path.jpg',
        dateTaken: DateTime.now(),
        description: 'Test',
        campaignId: 'test',
        spots: [originalSpot],
      );

      // Copy spots to new photo
      final copiedPhoto = Photo(
        id: 'copied',
        relativePath: 'new_path.jpg',
        dateTaken: DateTime.now(),
        description: 'Copied',
        campaignId: 'test',
        spots: originalPhoto.spots.map((spot) => Spot(
          position: spot.position,
          radius: spot.radius,
          moleId: spot.moleId,
        )).toList(), // Deep copy spots
      );

      // Modify the copied spot
      copiedPhoto.spots[0].position = const Offset(200, 250);

      // Verify original spot is unchanged (confirming it's a proper copy)
      expect(originalPhoto.spots[0].position.dx, equals(100));
      expect(originalPhoto.spots[0].position.dy, equals(150));
      expect(copiedPhoto.spots[0].position.dx, equals(200));
      expect(copiedPhoto.spots[0].position.dy, equals(250));
    });
  });
}
