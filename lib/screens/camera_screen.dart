import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;
import 'photo_gallery_screen.dart';
import '../models/photo.dart';
import '../storage/photo_storage.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras![0], ResolutionPreset.high);

    await _controller!.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = path.join(
      directory.path,
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    developer.log('Saving picture to $imagePath', name: 'CameraScreen');

    try {
      XFile picture = await _controller!.takePicture();
      await picture.saveTo(imagePath);

      final newPhoto = Photo(
        path: imagePath,
        dateTaken: DateTime.now.toString(),
        moleName: '', // or prompt user for a name
      );

      // Load, add, and save
      List<Photo> photos = await PhotoStorage.loadPhotos();
      photos.add(newPhoto);
      await PhotoStorage.savePhotos(photos);
      developer.log('Photo saved successfully', name: 'CameraScreen');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Picture saved!'),
            action: SnackBarAction(
              label: 'View Gallery',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PhotoGalleryScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      developer.log('Error taking picture: $e', name: 'CameraScreen');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error taking picture')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PhotoGalleryScreen(),
                ),
              );
            },
            tooltip: 'View Gallery',
          ),
        ],
      ),
      body: CameraPreview(_controller!),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        tooltip: 'Take Picture',
        child: const Icon(Icons.camera),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
