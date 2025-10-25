import 'package:flutter/material.dart';
import 'camera_screen.dart';
import '../models/photo.dart';
import '../models/mole.dart';
import '../storage/user_storage.dart';
import 'single_photo_screen.dart';
import '../widgets/app_bar_title.dart'; // Add this import
import '../widgets/photo_grid_item.dart'; // Add this import

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  PhotoGalleryScreenState createState() => PhotoGalleryScreenState();
}

class PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<Photo> _imageFiles = [];
  List<Mole> _moles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _isLoading = true);
    final photos = await UserStorage.loadPhotos();
    final allMoles = await UserStorage.loadMoles();
    setState(() {
      _imageFiles = photos;
      _moles = allMoles;
      _isLoading = false;
    });
  }

  Future<void> _saveImages() async {
    await UserStorage.savePhotos(_imageFiles);
  }

  void _editPhotoDescription(int index, String newDescription) async {
    setState(() {
      _imageFiles[index] = Photo(
        id: _imageFiles[index].id,
        relativePath: _imageFiles[index].relativePath,
        dateTaken: _imageFiles[index].dateTaken,
        description: newDescription,
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
        title: const AppBarTitle(title: 'Gallery'), // Updated to use widget
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
                    return PhotoGridItem( // Updated to use widget
                      key: Key('photo_${photo.id}'),
                      photo: photo,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SinglePhotoScreen(
                              photo: photo,
                              moles: _moles,
                              index: index,
                              onEditDescription: _editPhotoDescription,
                              onDelete: (i) async => await _deleteImage(i),
                            ),
                          ),
                        );
                      },
                      onCameraReturn: _loadImages, // Add refresh callback for gallery
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