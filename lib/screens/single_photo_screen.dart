import 'package:flutter/material.dart';
import 'dart:io';
import '../models/photo.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'dart:developer' as developer;
import '../models/spot.dart';
import '../storage/user_storage.dart'; // Add this import

class SinglePhotoScreen extends StatefulWidget {
  final Photo photo;
  final int index;
  final void Function(int, String) onEditDescription; // Changed from onEditMoleName
  final void Function(int) onDelete;

  const SinglePhotoScreen({
    super.key,
    required this.photo,
    required this.index,
    required this.onEditDescription,
    required this.onDelete,
  });

  @override
  _SinglePhotoScreenState createState() => _SinglePhotoScreenState();
}

enum MarkAction { none, add, drag }

class _SinglePhotoScreenState extends State<SinglePhotoScreen> {
  bool markMode = false;
  int? selectedSpotIndex;
  MarkAction markAction = MarkAction.none;
  final TransformationController _transformationController = TransformationController();

  Future<void> _savePhotoChanges() async {
    // Save the photo with updated spots using UserStorage
    final photos = await UserStorage.loadPhotos();
    if (widget.index >= 0 && widget.index < photos.length) {
      photos[widget.index] = widget.photo;
      await UserStorage.savePhotos(photos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Details'),
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
                widget.onDelete(widget.index);
                Navigator.pop(context);
              }
            },
            tooltip: 'Delete',
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              color: markMode ? Colors.white : null,
            ),
            style: IconButton.styleFrom(
              backgroundColor: markMode ? Colors.blue : null,
              foregroundColor: markMode ? Colors.white : null,
            ),
            tooltip: markMode ? 'Exit Mark Mode' : 'Mark Mode',
            onPressed: () async {
              // If exiting mark mode, save changes
              if (markMode) {
                await _savePhotoChanges();
              }
              
              setState(() {
                markMode = !markMode;
                markAction = MarkAction.none;
                selectedSpotIndex = null;
                developer.log("Mark mode toggled: $markMode", name: 'SinglePhotoScreen');
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * (2 / 3),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 5.0,
                      panEnabled: !markMode,
                      scaleEnabled: !markMode,
                      transformationController: _transformationController,
                      child: Stack(
                        children: [
                          // Image as the base layer
                          Positioned.fill(
                            child: Image.file(
                              File(widget.photo.path),
                              fit: BoxFit.contain,
                            ),
                          ),
                          // Render spots - these will now transform with the image
                          ...widget.photo.spots.asMap().entries.map((entry) {
                            final i = entry.key;
                            final spot = entry.value;
                            return Positioned(
                              left: spot.position.dx - spot.radius,
                              top: spot.position.dy - spot.radius,
                              child: GestureDetector(
                                onTap: () {
                                  if (markMode) {
                                    setState(() {
                                      selectedSpotIndex = i;
                                    });
                                  }
                                },
                                child: Container(
                                  width: spot.radius * 2,
                                  height: spot.radius * 2,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedSpotIndex == i ? Colors.blue : Colors.red,
                                      width: selectedSpotIndex == i ? 4 : 2,
                                    ),
                                    color: Colors.red.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  // Add GestureDetector as an overlay only when in mark mode
                  if (markMode)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: markAction == MarkAction.add
                          ? (details) async {
                              // Transform the tap position to account for zoom/pan
                              final Matrix4 transform = _transformationController.value;
                              final Matrix4 invertedTransform = Matrix4.inverted(transform);
                              final Vector3 transformed = invertedTransform.transform3(Vector3(
                                details.localPosition.dx,
                                details.localPosition.dy,
                                0,
                              ));
                              final Offset transformedPosition = Offset(transformed.x, transformed.y);

                              setState(() {
                                widget.photo.spots.add(Spot(
                                  position: transformedPosition, 
                                  radius: 30, 
                                  moleId: "mole_${DateTime.now().millisecondsSinceEpoch}"
                                ));
                                selectedSpotIndex = widget.photo.spots.length - 1;
                                markAction = MarkAction.none;
                              });
                              
                              // Save changes immediately
                              await _savePhotoChanges();
                            }
                          : null,
                        onPanUpdate: markAction == MarkAction.drag && selectedSpotIndex != null
                          ? (details) async {
                              // Transform the drag delta to account for zoom
                              final double scale = _transformationController.value.getMaxScaleOnAxis();
                              final Offset transformedDelta = details.delta / scale;
                              
                              setState(() {
                                widget.photo.spots[selectedSpotIndex!].position += transformedDelta;
                              });
                              
                              // Save changes immediately
                              await _savePhotoChanges();
                            }
                          : null,
                      ),
                    ),
                ],
              ),
            ),
            if (markMode)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.add_circle,
                          color: markAction == MarkAction.add ? Colors.blue : Colors.black),
                      tooltip: 'Add Mark',
                      onPressed: () {
                        setState(() {
                          markAction = MarkAction.add;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.remove_circle,
                          color: (selectedSpotIndex != null && markAction == MarkAction.none)
                              ? Colors.red
                              : Colors.black),
                      tooltip: 'Delete Mark',
                      onPressed: selectedSpotIndex != null
                          ? () async {
                              setState(() {
                                widget.photo.spots.removeAt(selectedSpotIndex!);
                                selectedSpotIndex = null;
                              });
                              // Save changes after deletion
                              await _savePhotoChanges();
                            }
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.open_with,
                          color: markAction == MarkAction.drag ? Colors.blue : Colors.black),
                      tooltip: 'Drag Mark',
                      onPressed: selectedSpotIndex != null
                          ? () {
                              setState(() {
                                markAction = MarkAction.drag;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Body Region: ${widget.photo.description.isNotEmpty ? widget.photo.description : "Not specified"}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${widget.photo.dateTaken.day}/${widget.photo.dateTaken.month}/${widget.photo.dateTaken.year}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Spots marked: ${widget.photo.spots.length}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                String? newDescription = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    final controller = TextEditingController(text: widget.photo.description);
                    return AlertDialog(
                      title: const Text('Edit Body Region'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Body Region Description',
                          hintText: 'e.g., Left shoulder, Upper back',
                        ),
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
                if (newDescription != null && newDescription.trim().isNotEmpty) {
                  widget.onEditDescription(widget.index, newDescription.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Description updated!')),
                  );
                }
              },
              child: const Text('Edit Description'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}