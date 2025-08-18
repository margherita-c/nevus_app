import 'package:flutter/material.dart';
import '../models/photo.dart';
import '../models/spot.dart';
import '../utils/dialog_utils.dart';

class PhotoInfoPanel extends StatelessWidget {
  final Photo photo;
  final List<Spot> spots;
  final int? selectedSpotIndex;
  final bool isMarkMode;
  final Function(String) onEditDescription;
  final Function(int, String) onEditSpotMoleId;
  final Function(int) onSelectSpot;

  const PhotoInfoPanel({
    super.key,
    required this.photo,
    required this.spots,
    this.selectedSpotIndex,
    required this.isMarkMode,
    required this.onEditDescription,
    required this.onEditSpotMoleId,
    required this.onSelectSpot,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhotoInfoCard(context),
          if (spots.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSpotsSection(context),
          ],
          const SizedBox(height: 24),
          _buildEditDescriptionButton(context),
        ],
      ),
    );
  }

  Widget _buildPhotoInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Body Region: ${photo.description.isNotEmpty ? photo.description : "Not specified"}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Date: ${photo.dateTaken.day}/${photo.dateTaken.month}/${photo.dateTaken.year}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_pin, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Spots marked: ${spots.length}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Marked Spots:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...spots.asMap().entries.map((entry) {
          final index = entry.key;
          final spot = entry.value;
          final isSelected = selectedSpotIndex == index;
          
          return Card(
            color: isSelected ? Colors.blue.shade50 : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isSelected ? Colors.blue : Colors.red,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                'Mole ID: ${spot.moleId}',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                'Position: (${spot.position.dx.toInt()}, ${spot.position.dy.toInt()})',
              ),
              trailing: isMarkMode 
                ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _handleEditMoleId(context, index, spot.moleId),
                  )
                : null,
              onTap: isMarkMode ? () => onSelectSpot(index) : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEditDescriptionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _handleEditDescription(context),
        icon: const Icon(Icons.edit),
        label: const Text('Edit Description'),
      ),
    );
  }

  Future<void> _handleEditMoleId(BuildContext context, int index, String currentMoleId) async {
    final String? newMoleId = await DialogUtils.showEditMoleIdDialog(
      context: context,
      currentMoleId: currentMoleId,
    );
    
    if (newMoleId != null && newMoleId.isNotEmpty && newMoleId != currentMoleId) {
      onEditSpotMoleId(index, newMoleId);
    }
  }

  Future<void> _handleEditDescription(BuildContext context) async {
    final String? newDescription = await DialogUtils.showEditDescriptionDialog(
      context: context,
      currentDescription: photo.description,
    );
    
    if (newDescription != null && newDescription.trim().isNotEmpty) {
      onEditDescription(newDescription.trim());
    }
  }
}