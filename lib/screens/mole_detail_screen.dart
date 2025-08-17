import 'package:flutter/material.dart';
import 'dart:io';
import '../models/mole.dart';
import '../models/photo.dart';
import '../storage/user_storage.dart';
import '../widgets/app_bar_title.dart';
import 'single_photo_screen.dart';

class MoleDetailScreen extends StatefulWidget {
  final Mole mole;

  const MoleDetailScreen({super.key, required this.mole});

  @override
  State<MoleDetailScreen> createState() => _MoleDetailScreenState();
}

class _MoleDetailScreenState extends State<MoleDetailScreen> {
  List<Photo> _molePhotos = [];
  bool _isLoading = true;
  late Mole _currentMole;

  @override
  void initState() {
    super.initState();
    _currentMole = widget.mole;
    _loadMolePhotos();
  }

  Future<void> _loadMolePhotos() async {
    setState(() => _isLoading = true);

    try {
      // Load all photos
      final allPhotos = await UserStorage.loadPhotos();
      
      // Filter photos that contain spots with this mole's ID
      final molePhotos = allPhotos.where((photo) {
        return photo.spots.any((spot) => spot.moleId == _currentMole.id);
      }).toList();

      // Sort by date taken (newest first)
      molePhotos.sort((a, b) => b.dateTaken.compareTo(a.dateTaken));

      setState(() {
        _molePhotos = molePhotos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _molePhotos = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading photos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editMoleInfo() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: _currentMole.name);
        final descriptionController = TextEditingController(text: _currentMole.description);
        
        return AlertDialog(
          title: const Text('Edit Mole Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Mole Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      // Update the mole
      final updatedMole = Mole(
        id: _currentMole.id,
        name: result['name']!.isNotEmpty ? result['name']! : _currentMole.name,
        description: result['description']!,
      );

      // Save to storage
      final allMoles = await UserStorage.loadMoles();
      final moleIndex = allMoles.indexWhere((m) => m.id == _currentMole.id);
      if (moleIndex != -1) {
        allMoles[moleIndex] = updatedMole;
        await UserStorage.saveMoles(allMoles);
        
        setState(() {
          _currentMole = updatedMole;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mole information updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteMole() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Mole'),
        content: Text(
          'Are you sure you want to delete "${_currentMole.name}"?\n\n'
          'This will also remove all spots marking this mole from ${_molePhotos.length} photo(s). '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Remove the mole from storage
        final allMoles = await UserStorage.loadMoles();
        allMoles.removeWhere((m) => m.id == _currentMole.id);
        await UserStorage.saveMoles(allMoles);

        // Remove all spots with this mole ID from photos
        final allPhotos = await UserStorage.loadPhotos();
        bool photosChanged = false;
        for (final photo in allPhotos) {
          final originalSpotCount = photo.spots.length;
          photo.spots.removeWhere((spot) => spot.moleId == _currentMole.id);
          if (photo.spots.length != originalSpotCount) {
            photosChanged = true;
          }
        }
        
        if (photosChanged) {
          await UserStorage.savePhotos(allPhotos);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mole deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting mole: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildPhotoThumbnail(Photo photo, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SinglePhotoScreen(
              photo: photo,
              index: index,
              onEditDescription: (_, _) {}, // Not used in this context
              onDelete: (_) {}, // Not used in this context
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Image.file(
                  File(photo.path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues (alpha: 0.7)],
                    ),
                  ),
                  child: Text(
                    '${photo.dateTaken.day}/${photo.dateTaken.month}/${photo.dateTaken.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(title: _currentMole.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _editMoleInfo,
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Mole Info',
          ),
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteMole();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Mole', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mole Information Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              _currentMole.name.isNotEmpty ? _currentMole.name[0].toUpperCase() : 'M',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentMole.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${_currentMole.id}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_currentMole.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Description:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(_currentMole.description),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.photo_library, color: Colors.grey.shade600, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Tracked in ${_molePhotos.length} photo${_molePhotos.length != 1 ? 's' : ''}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Photos Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Photo History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                _molePhotos.isEmpty
                  ? Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.photo_camera_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No photos yet',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start taking photos and marking this mole to track changes over time',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _molePhotos.length,
                        itemBuilder: (context, index) {
                          return _buildPhotoThumbnail(_molePhotos[index], index);
                        },
                      ),
                    ),

                // Statistics Card
                if (_molePhotos.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Tracking Statistics',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'First Photo',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                Text(
                                  '${_molePhotos.last.dateTaken.day}/${_molePhotos.last.dateTaken.month}/${_molePhotos.last.dateTaken.year}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Latest Photo',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                Text(
                                  '${_molePhotos.first.dateTaken.day}/${_molePhotos.first.dateTaken.month}/${_molePhotos.first.dateTaken.year}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _editMoleInfo,
        tooltip: 'Edit Mole Info',
        child: const Icon(Icons.edit),
      ),
    );
  }
}