// Create: lib/utils/dialog_utils.dart
import 'package:flutter/material.dart';

import '../models/mole.dart';
import '../storage/user_storage.dart';

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

  /// Shows an edit mole ID dialog with dropdown selection
  static Future<String?> showEditMoleIdDialog({
    required BuildContext context,
    required String currentMoleId,
  }) async {
    try {
      final existingMoles = await UserStorage.loadMoles();
      
      return showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Change Mole Assignment'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Currently assigned to: $currentMoleId'),
                  const SizedBox(height: 16),
                  if (existingMoles.isNotEmpty) ...[
                    const Text('Select different mole:'),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: existingMoles.length,
                        itemBuilder: (context, index) {
                          final mole = existingMoles[index];
                          final isCurrentMole = mole.id == currentMoleId;
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCurrentMole ? Colors.green : Colors.blue,
                              child: Text(
                                mole.name.isNotEmpty ? mole.name[0].toUpperCase() : 'M',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(mole.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (mole.description.isNotEmpty)
                                  Text(mole.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (isCurrentMole)
                                  const Text('(Currently assigned)', 
                                    style: TextStyle(color: Colors.green, fontSize: 12)),
                              ],
                            ),
                            trailing: isCurrentMole ? const Icon(Icons.check, color: Colors.green) : null,
                            onTap: () => Navigator.pop(context, mole.id),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                  ],
                  const Text('Or create a new mole:'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Simply return a special value to indicate "create new"
                      Navigator.pop(context, 'CREATE_NEW_MOLE');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Mole'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Fallback to simple text input if loading fails
      return showTextInputDialog(
        context: context,
        title: 'Edit Mole ID',
        labelText: 'Mole ID',
        initialValue: currentMoleId,
      );
    }
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

  /// Shows a mole selection dialog with existing moles and create new option
  static Future<String?> showMoleSelectionDialog({
    required BuildContext context,
  }) async {
    try {
      final existingMoles = await UserStorage.loadMoles();
      
      return showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select or Create Mole'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (existingMoles.isNotEmpty) ...[
                    const Text('Select existing mole:'),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: existingMoles.length,
                        itemBuilder: (context, index) {
                          final mole = existingMoles[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                mole.name.isNotEmpty ? mole.name[0].toUpperCase() : 'M',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(mole.name),
                            subtitle: mole.description.isNotEmpty 
                                ? Text(mole.description, maxLines: 1, overflow: TextOverflow.ellipsis)
                                : null,
                            onTap: () => Navigator.pop(context, mole.id),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                  ],
                  const Text('Or create a new mole:'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context); // Close this dialog
                      final newMoleId = await showCreateMoleDialog(context);
                      if (newMoleId != null) {
                        Navigator.pop(context, newMoleId); // Return the new mole ID
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Mole'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Fallback to simple text input if loading fails
      return showMoleIdDialog(context: context);
    }
  }

  /// Shows dialog to create a new mole
  static Future<String?> showCreateMoleDialog(BuildContext context) async {
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final descriptionController = TextEditingController();
        
        return AlertDialog(
          title: const Text('Create New Mole'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Mole Name',
                  hintText: 'e.g., Left shoulder mole',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Describe the mole characteristics',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                  });
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        // Create the new mole
        final newMole = Mole(
          id: 'mole_${DateTime.now().millisecondsSinceEpoch}',
          name: result['name']!,
          description: result['description'] ?? '',
        );

        // Save to storage
        final allMoles = await UserStorage.loadMoles();
        allMoles.add(newMole);
        await UserStorage.saveMoles(allMoles);

        return newMole.id;
      } catch (e) {
        // If saving fails, return null
        return null;
      }
    }
    
    return null;
  }
}