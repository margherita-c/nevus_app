import 'package:flutter/material.dart';
import 'dart:io';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import '../models/photo.dart';
import '../models/mole.dart';
import 'spot_widget.dart';
import 'mark_mode_controls.dart';
import '../storage/user_storage.dart';

class InteractivePhotoViewer extends StatelessWidget {
  final Photo photo;
  final List<Mole> moles;
  final bool isMarkMode;
  final MarkAction markAction;
  final int? selectedSpotIndex;
  final TransformationController transformationController;
  final Function(Offset) onAddSpot;
  final Function(Offset) onDragSpot;
  final Function(double) onResizeSpot; // Added resize callback
  final Function(int) onSelectSpot;
  final Function(int) onEditSpot; // Added edit spot callback

  const InteractivePhotoViewer({
    super.key,
    required this.photo,
    required this.moles,
    required this.isMarkMode,
    required this.markAction,
    this.selectedSpotIndex,
    required this.transformationController,
    required this.onAddSpot,
    required this.onDragSpot,
    required this.onResizeSpot,
    required this.onSelectSpot,
    required this.onEditSpot,
  });

  @override
  Widget build(BuildContext context) {
    UserStorage.ensureUserDirectoryExists();
    final fullPath = '${UserStorage.userDirectory}/${photo.relativePath}';
    return Stack(
      children: [
        // Interactive viewer with image and spots
        Positioned.fill(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 5.0,
            panEnabled: !isMarkMode,
            scaleEnabled: !isMarkMode,
            transformationController: transformationController,
            child: Stack(
              children: [
                // Base image
                Positioned.fill(
                  child: Image.file(
                    File(fullPath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ),
                // Spots
                ...photo.spots.asMap().entries.map((entry) {
                  final index = entry.key;
                  final spot = entry.value;
                  // Build a map from the list of moles that lets me retrieve the mole by its ID
                  final moleMap = {for (var mole in moles) mole.id: mole};
                  final currentMole = moleMap[spot.moleId] ?? Mole.defaultMole();
                  
                  return SpotWidget(
                    spot: spot,
                    mole: currentMole,
                    isSelected: selectedSpotIndex == index,
                    isMarkMode: isMarkMode,
                    isResizeMode: markAction == MarkAction.resize && selectedSpotIndex == index,
                    onTap: () => onSelectSpot(index),
                    onEdit: () => onEditSpot(index), // Add edit callback
                  );
                }),
              ],
            ),
          ),
        ),
        // Mark mode gesture overlay
        if (isMarkMode)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: markAction == MarkAction.add
                ? (details) => _handleAddSpot(details)
                : null,
              onPanUpdate: markAction == MarkAction.drag && selectedSpotIndex != null
                ? (details) => _handleDragSpot(details)
                : markAction == MarkAction.resize && selectedSpotIndex != null
                ? (details) => _handleResizeSpot(details)
                : null,
              // Add this line to allow zoom gestures to pass through:
              onScaleStart: markAction == MarkAction.none ? (_) {} : null,
              onScaleUpdate: markAction == MarkAction.none ? (_) {} : null,
            ),
          ),
      ],
    );
  }

  void _handleAddSpot(TapDownDetails details) {
    final Matrix4 transform = transformationController.value;
    final Matrix4 invertedTransform = Matrix4.inverted(transform);
    final Vector3 transformed = invertedTransform.transform3(Vector3(
      details.localPosition.dx,
      details.localPosition.dy,
      0,
    ));
    final Offset transformedPosition = Offset(transformed.x, transformed.y);
    onAddSpot(transformedPosition);
  }

  void _handleDragSpot(DragUpdateDetails details) {
    final double scale = transformationController.value.getMaxScaleOnAxis();
    final Offset transformedDelta = details.delta / scale;
    onDragSpot(transformedDelta);
  }

  void _handleResizeSpot(DragUpdateDetails details) {
    // Calculate resize delta based on vertical drag movement
    final double scale = transformationController.value.getMaxScaleOnAxis();
    final double resizeDelta = -details.delta.dy / scale; // Negative so dragging up increases size
    onResizeSpot(resizeDelta);
  }
}