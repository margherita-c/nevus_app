import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'photo_gallery_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  void _openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
  }

  void _openGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PhotoGalleryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _openCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open Camera'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('View Gallery'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}