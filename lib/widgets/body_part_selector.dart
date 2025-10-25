import 'package:flutter/material.dart';

class BodyPartSelector extends StatefulWidget {
  final String? initialBodyPart;
  final ValueChanged<String?>? onChanged;

  const BodyPartSelector({
    super.key,
    this.initialBodyPart,
    this.onChanged,
  });

  @override
  State<BodyPartSelector> createState() => _BodyPartSelectorState();
}

class _BodyPartSelectorState extends State<BodyPartSelector> {
  String? _selectedCategory;
  String? _selectedSubPart;

  // Define the hierarchical body parts
  final Map<String, List<String>> _bodyParts = {
    'Head and Neck': ['Head', 'Scalp', 'Face', 'Neck'],
    'Upper Body (Torso and Arms)': ['Chest', 'Abdomen / Belly', 'Back'],
    'Arms and Hands': ['Shoulder', 'Arm', 'Forearm', 'Hand'],
    'Lower Body (Legs, Feet)': ['Leg', 'Thighs', 'Knees', 'Foot'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialBodyPart != null) {
      _parseInitialBodyPart(widget.initialBodyPart!);
    }
  }

  void _parseInitialBodyPart(String bodyPart) {
    // Try to parse "Category: SubPart" format
    if (bodyPart.contains(':')) {
      final parts = bodyPart.split(':');
      if (parts.length == 2) {
        final category = parts[0].trim();
        final subPart = parts[1].trim();
        if (_bodyParts.containsKey(category) && _bodyParts[category]!.contains(subPart)) {
          setState(() {
            _selectedCategory = category;
            _selectedSubPart = subPart;
          });
        }
      }
    }
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
      _selectedSubPart = null; // Reset sub-part when category changes
    });
    _notifyChange();
  }

  void _onSubPartChanged(String? subPart) {
    setState(() {
      _selectedSubPart = subPart;
    });
    _notifyChange();
  }

  void _notifyChange() {
    final bodyPart = _selectedCategory != null && _selectedSubPart != null
        ? '$_selectedCategory: $_selectedSubPart'
        : null;
    widget.onChanged?.call(bodyPart);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Body Part',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          items: _bodyParts.keys.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: _onCategoryChanged,
        ),
        const SizedBox(height: 16),
        if (_selectedCategory != null)
          DropdownButtonFormField<String>(
            value: _selectedSubPart,
            decoration: const InputDecoration(
              labelText: 'Specific Part',
              border: OutlineInputBorder(),
            ),
            items: _bodyParts[_selectedCategory]!.map((subPart) {
              return DropdownMenuItem<String>(
                value: subPart,
                child: Text(subPart),
              );
            }).toList(),
            onChanged: _onSubPartChanged,
          ),
      ],
    );
  }
}