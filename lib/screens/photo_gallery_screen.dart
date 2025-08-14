import 'package:flutter/material.dart';
import 'dart:io';
import 'camera_screen.dart';
import '../models/photo.dart';
import '../storage/user_storage.dart'; // Changed from photo_storage
import 'single_photo_screen.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  PhotoGalleryScreenState createState() => PhotoGalleryScreenState();
}

class PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<Photo> _imageFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _isLoading = true);
    final photos = await UserStorage.loadPhotos(); // Changed to UserStorage
    setState(() {
      _imageFiles = photos;
      _isLoading = false;
    });
  }

  Future<void> _saveImages() async {
    await UserStorage.savePhotos(_imageFiles); // Changed to UserStorage
  }

  void _editPhotoDescription(int index, String newDescription) async {
    setState(() {
      _imageFiles[index] = Photo(
        id: _imageFiles[index].id,
        path: _imageFiles[index].path,
        dateTaken: _imageFiles[index].dateTaken,
        description: newDescription, // Update description instead of moleName
        campaignId: _imageFiles[index].campaignId,
        spots: _imageFiles[index].spots,
      );
    });
    await _saveImages();
  }
  
  Future<void> _deleteImage(int index) async {
    setState(() {
      _imageFiles.removeAt(index);
    });
    await _saveImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Gallery - ${UserStorage.currentUser.username}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadImages();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _imageFiles.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No photos yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Take some photos with the camera!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: _imageFiles.length,
                  itemBuilder: (context, index) {
                    final photo = _imageFiles[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SinglePhotoScreen(
                              photo: photo,
                              index: index,
                              onEditDescription: _editPhotoDescription, // Changed from onEditMoleName
                              onDelete: (i) async => await _deleteImage(i),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((0.2 * 255).toInt()),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.file(
                                File(photo.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            // Photo description overlay
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(8.0),
                                    bottomRight: Radius.circular(8.0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      photo.description.isNotEmpty 
                                        ? photo.description 
                                        : 'No description',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${photo.spots.length} spots',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
        },
        tooltip: 'Take Photo',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}