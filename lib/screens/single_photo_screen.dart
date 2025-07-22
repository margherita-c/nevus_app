import 'package:flutter/material.dart';
import 'dart:io';
import '../models/photo.dart';

class SinglePhotoScreen extends StatefulWidget {
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
  _SinglePhotoScreenState createState() => _SinglePhotoScreenState();
}

enum MarkAction { none, add, drag }

class _SinglePhotoScreenState extends State<SinglePhotoScreen> {
  bool markMode = false;
  int? selectedSpotIndex;
  MarkAction markAction = MarkAction.none;

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
                widget.onDelete(widget.index);
                Navigator.pop(context);
              }
            },
            tooltip: 'Delete',
          ),
          IconButton(
            icon: Icon(Icons.edit), // Pencil icon for mark mode
            tooltip: 'Mark Mode',
            onPressed: () {
              setState(() {
                markMode = !markMode;
                markAction = MarkAction.none;
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
                      child: Stack(  // Add Stack inside InteractiveViewer
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
                                    color: Colors.red.withOpacity(0.2),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
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
                          ? (details) {
                              final localPos = details.localPosition;
                              setState(() {
                                widget.photo.spots.add(Spot(position: localPos, radius: 30));
                                selectedSpotIndex = widget.photo.spots.length - 1;
                                markAction = MarkAction.none;
                              });
                            }
                          : null,
                        onPanUpdate: markAction == MarkAction.drag && selectedSpotIndex != null
                          ? (details) {
                              setState(() {
                                widget.photo.spots[selectedSpotIndex!].position += details.delta;
                              });
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
                          ? () {
                              setState(() {
                                widget.photo.spots.removeAt(selectedSpotIndex!);
                                selectedSpotIndex = null;
                              });
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
            Text('Mole: ${widget.photo.moleName}', style: const TextStyle(fontSize: 20)),
            Text('Date: ${widget.photo.dateTaken}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                String? newName = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    final controller = TextEditingController(text: widget.photo.moleName);
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
                  widget.onEditMoleName(widget.index, newName.trim());
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