import 'package:flutter/material.dart';

enum MarkAction { none, add, edit }

class MarkModeControls extends StatelessWidget {
  final MarkAction currentAction;
  final bool hasSelectedSpot;
  final Function(MarkAction) onActionChanged;
  final VoidCallback onDeleteSpot;

  const MarkModeControls({
    super.key,
    required this.currentAction,
    required this.hasSelectedSpot,
    required this.onActionChanged,
    required this.onDeleteSpot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.add_circle,
            label: 'Add',
            isActive: currentAction == MarkAction.add,
            onPressed: () => onActionChanged(
              currentAction == MarkAction.add ? MarkAction.none : MarkAction.add,
            ),
          ),
          _buildControlButton(
            icon: Icons.open_with,
            label: 'Edit',
            isActive: currentAction == MarkAction.edit,
            isEnabled: hasSelectedSpot,
            onPressed: hasSelectedSpot
                ? () => onActionChanged(
                    currentAction == MarkAction.edit ? MarkAction.none : MarkAction.edit,
                  )
                : null,
          ),
          _buildControlButton(
            icon: Icons.delete,
            label: 'Delete',
            isActive: false,
            isEnabled: hasSelectedSpot,
            color: hasSelectedSpot ? Colors.red : Colors.grey,
            onPressed: hasSelectedSpot ? onDeleteSpot : null,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    bool isEnabled = true,
    Color? color,
    VoidCallback? onPressed,
  }) {
    final effectiveColor = color ?? (isActive ? Colors.blue : Colors.grey);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: effectiveColor, size: 32),
          onPressed: isEnabled ? onPressed : null,
        ),
        Text(
          label,
          style: TextStyle(
            color: effectiveColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}