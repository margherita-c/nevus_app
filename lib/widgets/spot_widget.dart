import 'package:flutter/material.dart';
import 'package:nevus_app/models/mole.dart';
import '../models/spot.dart';

class SpotWidget extends StatelessWidget {
  final Spot spot;
  final Mole mole;
  final bool isSelected;
  final bool isMarkMode;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const SpotWidget({
    super.key,
    required this.spot,
    required this.mole,
    required this.isSelected,
    required this.isMarkMode,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: spot.position.dx - spot.radius,
      top: spot.position.dy - spot.radius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Spot circle - now clean without any number
          GestureDetector(
            onTap: isMarkMode ? onTap : null,
            child: Container(
              width: spot.radius * 2,
              height: spot.radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.red,
                  width: isSelected ? 4 : 2,
                ),
                color: Colors.red.withValues(alpha: 0.0),
              ),
            ),
          ),
          // Mole name and edit button below the spot
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 150),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mole name
                Text(
                  mole.name.length > 32
                      ? '${mole.name.substring(0, 32)}...'
                      : mole.name,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                // Edit button (only in mark mode)
                if (isMarkMode) ...[
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}