import 'package:flutter/material.dart';
import '../storage/user_storage.dart';
import '../widgets/app_bar_title.dart';
import 'fitzpatrick_info_screen.dart'; // Add this import

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  
  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  int? _selectedSkinType;
  bool _isLoading = false;
  bool _hasChanges = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
  final List<Map<String, dynamic>> _skinTypeOptions = [
    {'value': 1, 'label': 'Type I - Very fair, always burns'},
    {'value': 2, 'label': 'Type II - Fair, usually burns'},
    {'value': 3, 'label': 'Type III - Medium, sometimes burns'},
    {'value': 4, 'label': 'Type IV - Olive, rarely burns'},
    {'value': 5, 'label': 'Type V - Brown, very rarely burns'},
    {'value': 6, 'label': 'Type VI - Dark brown/black, never burns'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final currentUser = UserStorage.currentUser;
    _fullNameController.text = currentUser.fullName ?? '';
    _selectedDateOfBirth = currentUser.dateOfBirth;
    _selectedGender = currentUser.gender;
    _selectedSkinType = currentUser.skinType;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select your date of birth',
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _hasChanges = true;
      });
    }
  }

  void _showFitzpatrickInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FitzpatrickInfoScreen()),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || !_hasChanges) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = UserStorage.currentUser;
      final updatedUser = currentUser.copyWith(
        fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        gender: _selectedGender,
        skinType: _selectedSkinType,
      );

      // Update the user in memory first
      UserStorage.setCurrentUser(updatedUser);
      
      // Then save to file
      await UserStorage.saveCurrentUser();

      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = UserStorage.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(title: 'Edit Account'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Username (read-only)
                      TextFormField(
                        initialValue: currentUser.username,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        enabled: false,
                      ),
                      const SizedBox(height: 16),

                      // Full Name
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        onChanged: (_) => _onFieldChanged(),
                      ),
                      const SizedBox(height: 16),

                      // Date of Birth
                      InkWell(
                        onTap: _selectDateOfBirth,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.cake),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _selectedDateOfBirth != null
                                ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                                : 'Select your date of birth',
                            style: TextStyle(
                              color: _selectedDateOfBirth != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gender
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people),
                        ),
                        items: _genderOptions.map((gender) {
                          return DropdownMenuItem(value: gender, child: Text(gender));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedGender = value);
                          _onFieldChanged();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Skin Type with Info Button
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedSkinType,
                              decoration: const InputDecoration(
                                labelText: 'Skin Type (Fitzpatrick Scale)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.palette),
                              ),
                              isExpanded: true, // Add this to prevent overflow
                              items: _skinTypeOptions.map<DropdownMenuItem<int>>((skinType) {
                                return DropdownMenuItem<int>(
                                  value: skinType['value'] as int,
                                  child: Text(
                                    skinType['label'] as String,
                                    overflow: TextOverflow.ellipsis, // Add this to handle long text
                                    maxLines: 1, // Ensure single line
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedSkinType = value);
                                _onFieldChanged();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _showFitzpatrickInfo,
                            icon: const Icon(Icons.info_outline),
                            tooltip: 'Learn about Fitzpatrick Scale',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                              foregroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Account Stats Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Statistics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      if (currentUser.age != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text('Age: ${currentUser.age} years old'),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      Row(
                        children: [
                          const Icon(Icons.account_circle, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('Username: ${currentUser.username}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          const Icon(Icons.person_outline, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('Display Name: ${currentUser.displayName}'),
                        ],
                      ),
                      
                      if (currentUser.skinType != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.palette, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Skin Type: ${currentUser.skinTypeDescription}')),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button (large)
              if (_hasChanges)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Saving...'),
                          ],
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16),
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}