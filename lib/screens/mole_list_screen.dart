import 'package:flutter/material.dart';
import '../models/mole.dart';
import '../storage/user_storage.dart';
import '../widgets/app_bar_title.dart';
import '../widgets/body_part_selector.dart';
import 'mole_detail_screen.dart';

class MoleListScreen extends StatefulWidget {
  const MoleListScreen({super.key});

  @override
  State<MoleListScreen> createState() => _MoleListScreenState();
}

class _MoleListScreenState extends State<MoleListScreen> {
  List<Mole> _moles = [];
  bool _isLoading = true;
  Map<String, int> _molePhotoCount = {}; // Track how many photos each mole appears in

  @override
  void initState() {
    super.initState();
    _loadMoles();
  }

  Future<void> _loadMoles() async {
    setState(() => _isLoading = true);

    try {
      // Load all moles
      final allMoles = await UserStorage.loadMoles();
      
      // Load all photos to calculate photo count for each mole
      final allPhotos = await UserStorage.loadPhotos();

      // Calculate photo count for each mole
      Map<String, int> photoCount = {};
      for (final mole in allMoles) {
        int count = 0;
        for (final photo in allPhotos) {
          if (photo.spots.any((spot) => spot.moleId == mole.id)) {
            count++;
          }
        }
        photoCount[mole.id] = count;
      }

      setState(() {
        _moles = allMoles;
        _molePhotoCount = photoCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _moles = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading moles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToMoleDetail(Mole mole) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoleDetailScreen(mole: mole),
      ),
    );
    // Refresh the list when returning from detail screen
    _loadMoles();
  }

  Future<void> _createNewMole() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final descriptionController = TextEditingController();
        String? selectedBodyPart;
        
        return AlertDialog(
          title: const Text('Create New Mole'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Mole Name',
                    hintText: 'e.g., Left shoulder mole, Back center mole',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                BodyPartSelector(
                  onChanged: (bodyPart) {
                    selectedBodyPart = bodyPart;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the mole characteristics',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
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
                    'bodyPart': selectedBodyPart,
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
        final newMole = Mole(
          id: 'mole_${DateTime.now().millisecondsSinceEpoch}',
          name: result['name']!,
          description: result['description'] ?? '',
          bodyPart: result['bodyPart'],
        );

        // Load existing moles for current user
        final allMoles = await UserStorage.loadMoles();
        allMoles.add(newMole);
        
        // Save to user's moles.json file
        await UserStorage.saveMoles(allMoles);

        // Refresh the list
        await _loadMoles();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New mole created and saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating mole: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(title: 'Tracked Moles'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _createNewMole,
            icon: const Icon(Icons.add),
            tooltip: 'Create New Mole',
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _moles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_pin_circle, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No moles tracked yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first mole to start tracking',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createNewMole,
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Mole'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Moles Summary Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_pin_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_moles.length} mole${_moles.length != 1 ? 's' : ''} tracked',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Moles List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _moles.length,
                    itemBuilder: (context, index) {
                      final mole = _moles[index];
                      final photoCount = _molePhotoCount[mole.id] ?? 0;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              mole.name.isNotEmpty ? mole.name[0].toUpperCase() : 'M',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            mole.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (mole.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  mole.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Appears in $photoCount photo${photoCount != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _navigateToMoleDetail(mole),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewMole,
        tooltip: 'Create New Mole',
        child: const Icon(Icons.add),
      ),
    );
  }
}