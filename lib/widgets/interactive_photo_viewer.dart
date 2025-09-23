import 'package:flutter/material.dart';
import 'dart:io';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import '../models/photo.dart';
import '../models/mole.dart';
import 'mark_mode_controls.dart';
import 'spot_widget.dart';
import '../storage/user_storage.dart';

class InteractivePhotoViewer extends StatefulWidget {
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
  State<InteractivePhotoViewer> createState() => _InteractivePhotoViewerState();
}

class _InteractivePhotoViewerState extends State<InteractivePhotoViewer> {
  bool _isResizingSpot = false;
  double _lastScale = 1.0;

  @override
  Widget build(BuildContext context) {
    UserStorage.ensureUserDirectoryExists();
    final fullPath = '${UserStorage.userDirectory}/${widget.photo.relativePath}';
    return Stack(
      children: [
        // Interactive viewer with image and spots
        Positioned.fill(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 5.0,
            // Disable image pan/scale while actively resizing to avoid conflicts
            panEnabled: !(_isResizingSpot || widget.isMarkMode && widget.markAction == MarkAction.edit),
            scaleEnabled: !(_isResizingSpot || widget.isMarkMode && widget.markAction == MarkAction.edit),
            transformationController: widget.transformationController,
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
                ...widget.photo.spots.asMap().entries.map((entry) {
                  final index = entry.key;
                  final spot = entry.value;
                  // Build a map from the list of moles that lets me retrieve the mole by its ID
                  final moleMap = {for (var mole in widget.moles) mole.id: mole};
                  final currentMole = moleMap[spot.moleId] ?? Mole.defaultMole();
                  
                  return SpotWidget(
                    spot: spot,
                    mole: currentMole,
                    isSelected: widget.selectedSpotIndex == index,
                    isMarkMode: widget.isMarkMode,
                    isResizeMode: _isResizingSpot && widget.selectedSpotIndex == index,
                    onTap: () => widget.onSelectSpot(index),
                    onEdit: () => widget.onEditSpot(index),
                  );
                }),
              ],
            ),
          ),
        ),
        // Mark mode gesture overlay
        if (widget.isMarkMode)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: widget.markAction == MarkAction.add
                ? (details) => _handleAddSpot(details)
                : null,
              // Use scale gestures to support two-finger pinch-to-resize and single-finger drag.
              onScaleStart: (details) => _handleScaleStart(details),
              onScaleUpdate: (details) => _handleScaleUpdate(details),
              onScaleEnd: (details) => _handleScaleEnd(details),
            ),
          ),
      ],
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastScale = 1.0;
    // We don't set _isResizingSpot yet; wait until a meaningful scale change occurs.
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // Get current image transformation scale so we can convert screen deltas to image-space
    final double imageScale = widget.transformationController.value.getMaxScaleOnAxis();

    // Detect pinch (two-finger) by checking scale change
    final bool pinchDetected = (details.scale - 1.0).abs() > 0.02;

    if (pinchDetected && widget.markAction == MarkAction.edit && widget.selectedSpotIndex != null) {
      if (!_isResizingSpot) setState(() => _isResizingSpot = true);

      final scaleFactor = details.scale / _lastScale;
      _lastScale = details.scale;

      final currentSpot = widget.photo.spots[widget.selectedSpotIndex!];
      final double deltaRadius = currentSpot.radius * (scaleFactor - 1.0);
      widget.onResizeSpot(deltaRadius);
      return;
    }

    // If not a pinch and the action is drag, use focalPointDelta as movement
    if (!pinchDetected && widget.markAction == MarkAction.edit && widget.selectedSpotIndex != null) {
      final Offset transformedDelta = (details.focalPointDelta) / imageScale;
      widget.onDragSpot(transformedDelta);
      return;
    }

    // If we were resizing but user stopped scaling, reset flag
    if (_isResizingSpot) setState(() => _isResizingSpot = false);
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_isResizingSpot) setState(() => _isResizingSpot = false);
    _lastScale = 1.0;
  }

  void _handleAddSpot(TapDownDetails details) {
    final Matrix4 transform = widget.transformationController.value;
    final Matrix4 invertedTransform = Matrix4.inverted(transform);
    final Vector3 transformed = invertedTransform.transform3(Vector3(
      details.localPosition.dx,
      details.localPosition.dy,
      0,
    ));
    final Offset transformedPosition = Offset(transformed.x, transformed.y);
    widget.onAddSpot(transformedPosition);
  }
}