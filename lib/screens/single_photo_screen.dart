import 'package:flutter/material.dart';
import '../models/photo.dart';
import '../models/spot.dart';
import '../storage/user_storage.dart';
import '../widgets/interactive_photo_viewer.dart';
import '../widgets/mark_mode_controls.dart';
import '../widgets/photo_info_panel.dart';
import '../utils/dialog_utils.dart';

class SinglePhotoScreen extends StatefulWidget {
  final Photo photo;
  final int index;
  final void Function(int, String) onEditDescription;
  final void Function(int) onDelete;

  const SinglePhotoScreen({
    super.key,
    required this.photo,
    required this.index,
    required this.onEditDescription,
    required this.onDelete,
  });

  @override
  SinglePhotoScreenState createState() => SinglePhotoScreenState();
}

class SinglePhotoScreenState extends State<SinglePhotoScreen> {
  bool markMode = false;
  int? selectedSpotIndex;
  MarkAction markAction = MarkAction.none;
  final TransformationController _transformationController = TransformationController();

  Future<void> _savePhotoChanges() async {
    try {
      final photos = await UserStorage.loadPhotos();
      if (widget.index >= 0 && widget.index < photos.length) {
        photos[widget.index] = widget.photo;
        await UserStorage.savePhotos(photos);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleMarkMode() async {
    if (markMode) {
      await _savePhotoChanges();
    }
    
    setState(() {
      markMode = !markMode;
      markAction = MarkAction.none;
      selectedSpotIndex = null;
    });
  }

  void _handleAddSpot(Offset position) async {
    final String? moleId = await DialogUtils.showMoleIdDialog(context: context);
    
    if (moleId != null && moleId.isNotEmpty) {
      setState(() {
        widget.photo.spots.add(Spot(
          position: position, 
          radius: 30, 
          moleId: moleId
        ));
        selectedSpotIndex = widget.photo.spots.length - 1;
        markAction = MarkAction.none;
      });
      
      await _savePhotoChanges();
    } else {
      setState(() {
        markAction = MarkAction.none;
      });
    }
  }

  void _handleDragSpot(Offset delta) async {
    if (selectedSpotIndex != null) {
      setState(() {
        widget.photo.spots[selectedSpotIndex!].position += delta;
      });
      await _savePhotoChanges();
    }
  }

  void _handleDeleteSpot() async {
    if (selectedSpotIndex == null) return;
    
    final confirm = await DialogUtils.showDeleteSpotDialog(
      context: context,
      moleId: widget.photo.spots[selectedSpotIndex!].moleId,
    );
    
    if (confirm == true) {
      setState(() {
        widget.photo.spots.removeAt(selectedSpotIndex!);
        selectedSpotIndex = null;
        markAction = MarkAction.none;
      });
      await _savePhotoChanges();
    }
  }

  void _handleEditSpotMoleId(int index, String newMoleId) async {
    setState(() {
      widget.photo.spots[index] = Spot(
        position: widget.photo.spots[index].position,
        radius: widget.photo.spots[index].radius,
        moleId: newMoleId,
      );
    });
    await _savePhotoChanges();
  }

  // Added quick edit method for spots
  void _handleQuickEditSpot(int index) async {
    final String? newMoleId = await DialogUtils.showEditMoleIdDialog(
      context: context,
      currentMoleId: widget.photo.spots[index].moleId,
    );
    
    if (newMoleId != null && newMoleId.isNotEmpty && newMoleId != widget.photo.spots[index].moleId) {
      _handleEditSpotMoleId(index, newMoleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mole ID updated!')),
        );
      }
    }
  }

  void _handleEditDescription(String newDescription) {
    widget.onEditDescription(widget.index, newDescription);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Description updated!')),
    );
  }

  Future<void> _deletePhoto() async {
    final confirm = await DialogUtils.showDeletePhotoDialog(context: context);
    
    if (confirm == true) {
      widget.onDelete(widget.index);
      Navigator.pop(context);
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
            onPressed: _deletePhoto,
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
            onPressed: _toggleMarkMode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Photo viewer section
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * (2 / 3),
              child: InteractivePhotoViewer(
                photo: widget.photo,
                isMarkMode: markMode,
                markAction: markAction,
                selectedSpotIndex: selectedSpotIndex,
                transformationController: _transformationController,
                onAddSpot: _handleAddSpot,
                onDragSpot: _handleDragSpot,
                onSelectSpot: (index) => setState(() {
                  selectedSpotIndex = index;
                  markAction = MarkAction.none;
                }),
                onEditSpot: _handleQuickEditSpot, // Add quick edit callback
              ),
            ),
            
            // Mark mode controls
            if (markMode)
              MarkModeControls(
                currentAction: markAction,
                hasSelectedSpot: selectedSpotIndex != null,
                onActionChanged: (action) => setState(() => markAction = action),
                onDeleteSpot: _handleDeleteSpot,
              ),

            // Photo information panel
            PhotoInfoPanel(
              photo: widget.photo,
              spots: widget.photo.spots,
              selectedSpotIndex: selectedSpotIndex,
              isMarkMode: markMode,
              onEditDescription: _handleEditDescription,
              onEditSpotMoleId: _handleEditSpotMoleId,
              onSelectSpot: (index) => setState(() {
                selectedSpotIndex = index;
                markAction = MarkAction.none;
              }),
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