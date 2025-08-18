// Create: lib/utils/dialog_utils.dart
import 'package:flutter/material.dart';

class DialogUtils {
  static Future<DateTime?> showCreateCampaignDialog(BuildContext context) async {
    DateTime selectedDate = DateTime.now();
    
    return await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Campaign'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select the date for this mole tracking session'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedDate),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a text input dialog with the given parameters
  static Future<String?> showTextInputDialog({
    required BuildContext context,
    required String title,
    required String labelText,
    String? hintText,
    String? initialValue,
    String confirmButtonText = 'Save',
    String cancelButtonText = 'Cancel',
    bool autofocus = true,
    int maxLines = 1,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: initialValue);
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
              border: const OutlineInputBorder(),
            ),
            autofocus: autofocus,
            maxLines: maxLines,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(cancelButtonText),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(confirmButtonText),
            ),
          ],
        );
      },
    );
  }

  /// Shows a confirmation dialog with the given parameters
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmButtonText = 'Delete',
    String cancelButtonText = 'Cancel',
    Color? confirmButtonColor = Colors.red,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelButtonText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmButtonText,
              style: TextStyle(color: confirmButtonColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a mole ID assignment dialog
  static Future<String?> showMoleIdDialog({
    required BuildContext context,
    String? initialValue,
  }) async {
    return showTextInputDialog(
      context: context,
      title: 'Assign Mole ID',
      labelText: 'Mole ID',
      hintText: 'Enter mole identifier',
      initialValue: initialValue ?? "mole_${DateTime.now().millisecondsSinceEpoch}",
      confirmButtonText: 'Add',
    );
  }

  /// Shows an edit mole ID dialog
  static Future<String?> showEditMoleIdDialog({
    required BuildContext context,
    required String currentMoleId,
  }) async {
    return showTextInputDialog(
      context: context,
      title: 'Edit Mole ID',
      labelText: 'Mole ID',
      initialValue: currentMoleId,
    );
  }

  /// Shows an edit description dialog
  static Future<String?> showEditDescriptionDialog({
    required BuildContext context,
    required String currentDescription,
  }) async {
    return showTextInputDialog(
      context: context,
      title: 'Edit Body Region',
      labelText: 'Body Region Description',
      hintText: 'e.g., Left shoulder, Upper back',
      initialValue: currentDescription,
    );
  }

  /// Shows a delete spot confirmation dialog
  static Future<bool?> showDeleteSpotDialog({
    required BuildContext context,
    required String moleId,
  }) async {
    return showConfirmationDialog(
      context: context,
      title: 'Delete Spot',
      content: 'Delete spot with ID: $moleId?',
    );
  }

  /// Shows a delete photo confirmation dialog
  static Future<bool?> showDeletePhotoDialog({
    required BuildContext context,
  }) async {
    return showConfirmationDialog(
      context: context,
      title: 'Delete Photo',
      content: 'Are you sure you want to delete this photo? This action cannot be undone.',
    );
  }
}