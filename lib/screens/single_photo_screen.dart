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
              child: GestureDetector(
                behavior: HitTestBehavior.translucent, // Add this line
                onTapDown: (details) {
                  if (markMode && markAction == MarkAction.add) {
                    // Get the RenderBox of the Stack widget instead
                    final RenderBox stackBox = context.findRenderObject() as RenderBox;
                    final localPos = stackBox.globalToLocal(details.globalPosition);
                    
                    // Adjust for the SizedBox offset - subtract the AppBar height and any padding
                    final adjustedPos = Offset(
                      localPos.dx,
                      localPos.dy - (AppBar().preferredSize.height + MediaQuery.of(context).padding.top),
                    );
                    
                    setState(() {
                      widget.photo.spots.add(Spot(position: adjustedPos, radius: 30));
                      selectedSpotIndex = widget.photo.spots.length - 1;
                      markAction = MarkAction.none;
                    });
                  }
                },
                onPanUpdate: (details) {
                  if (markMode && markAction == MarkAction.drag && selectedSpotIndex != null) {
                    setState(() {
                      widget.photo.spots[selectedSpotIndex!].position += details.delta;
                    });
                  }
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 5.0,
                        panEnabled: !markMode,   // Allow pan when NOT in mark mode
                        scaleEnabled: !markMode, // Allow zoom when NOT in mark mode
                        constrained: true,       // Add this line
                        boundaryMargin: const EdgeInsets.all(20.0), // Add this line for better zoom experience
                        transformationController: TransformationController(), // Add this line
                        child: Image.file(
                          File(widget.photo.path),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
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
                          // onScaleUpdate: (details) {
                          //   if (!markMode && selectedSpotIndex == i) {
                          //     setState(() {
                          //       spot.radius = (spot.radius * details.scale).clamp(10.0, 200.0);
                          //     });
                          //   }
                          // },
                          // This is commented so tha the spots are easier to drag and select
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