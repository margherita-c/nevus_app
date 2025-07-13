import 'package:flutter/material.dart';
import 'dart:io';
import '../models/photo.dart';

class SinglePhotoScreen extends StatelessWidget {
  final Photo photo;
  final int index;
  final void Function(int, String) onEditMoleName;
  final void Function(int) onDelete;

  const SinglePhotoScreen({
    super.key,
    required this.photo,
    required this.index,
    required this.onEditMoleName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Photo'),
                  content: const Text('Are you sure you want to delete this photo? This action cannot be undone.'),
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
                onDelete(index);
                Navigator.pop(context);
              }
            },
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 400,
              child: Image.file(
                File(photo.path),
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text('Mole: ${photo.moleName}', style: const TextStyle(fontSize: 20)),
            Text('Date: ${photo.dateTaken}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                String? newName = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    final controller = TextEditingController(text: photo.moleName);
                    return AlertDialog(
                      title: const Text('Edit Mole Name'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(labelText: 'Mole Name'),
                        autofocus: true,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, controller.text),
                          child: const Text('Save'),
                        ),
                      ],
                    );
                  },
                );
                if (newName != null && newName.trim().isNotEmpty) {
                  onEditMoleName(index, newName.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mole name updated!')),
                  );
                }
              },
              child: const Text('Edit Name'),
            ),
          ],
        ),
      ),
    );
  }
}