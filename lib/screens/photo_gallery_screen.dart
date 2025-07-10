import 'package:flutter/material.dart';
//import 'package:path_provider/path_provider.dart';
//import 'dart:developer' as developer;
import 'dart:io';
import 'camera_screen.dart';
import '../models/photo.dart';
import '../utils/photo_storage.dart';

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
    final photos = await PhotoStorage.loadPhotos();
    setState(() {
      _imageFiles = photos;
      _isLoading = false;
    });
  }

Future<void> _saveImages() async {
    await PhotoStorage.savePhotos(_imageFiles);
  }

  // Example: Call this after editing a mole name
  void _editMoleName(int index, String newName) async {
    setState(() {
      _imageFiles[index] = Photo(
        path: _imageFiles[index].path,
        dateTaken: _imageFiles[index].dateTaken,
        moleName: newName,
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

  void _addPhoto(Photo newPhoto) async {
    setState(() {
      _imageFiles.add(newPhoto);
    });
    await _saveImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
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
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => Padding(
                          padding: EdgeInsets.only(
                            left: 16.0,
                            right: 16.0,
                            top: 16.0,
                            bottom: MediaQuery.of(context).viewInsets.bottom + 300.0,
                          ),
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.8,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                              SizedBox(
                                width: 500,
                                height: 500,
                                child: Image.file(
                                File(photo.path),
                                fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text('Mole: ${photo.moleName}'),
                              Text('Date: ${photo.dateTaken}'),
                              ],
                            ),
                            ),
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            File(photo.path),
                            fit: BoxFit.cover,
                          ),
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