import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_viewmodel.dart';
import '../data/models.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  
  // List of maps containing controllers for each emergency contact
  final List<Map<String, TextEditingController>> _contactControllers = [];
  
  bool _isLoading = false;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final user = ref.read(profileViewModelProvider).value;
      _nameController = TextEditingController(text: user?.name ?? '');
      _phoneController = TextEditingController(text: user?.phone ?? '');
      
      if (user != null) {
        for (var contact in user.emergencyContacts) {
          _contactControllers.add({
            'name': TextEditingController(text: contact.name),
            'phone': TextEditingController(text: contact.phone),
          });
        }
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    for (var map in _contactControllers) {
      map['name']!.dispose();
      map['phone']!.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      try {
        setState(() => _isLoading = true);
        await ref.read(profileViewModelProvider.notifier).updatePhoto(bytes);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating photo: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final currentUser = ref.read(profileViewModelProvider).value;
      if (currentUser != null) {
        // Collect emergency contacts from controllers
        final List<EmergencyContact> newContacts = _contactControllers.map((map) {
          return EmergencyContact(
            name: map['name']!.text.trim(),
            phone: map['phone']!.text.trim(),
          );
        }).toList();

        final updatedUser = currentUser.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          emergencyContacts: newContacts,
        );
        
        await ref.read(profileViewModelProvider.notifier).updateProfile(updatedUser);
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
           context.pop();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addEmergencyContact() {
    if (_contactControllers.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 3 emergency contacts allowed')));
      return;
    }
    setState(() {
      _contactControllers.add({
        'name': TextEditingController(),
        'phone': TextEditingController(),
      });
    });
  }

  void _removeEmergencyContact(int index) {
    setState(() {
      final removed = _contactControllers.removeAt(index);
      removed['name']!.dispose();
      removed['phone']!.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileViewModelProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                      child: user.photoUrl == null ? const Icon(Icons.person, size: 50) : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
              validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone), helperText: "Update requires re-verification (not implemented)"),
              keyboardType: TextInputType.phone,
              // validation can be stricter
              validator: (value) => value == null || value.length < 10 ? 'Enter valid phone number' : null,
            ),
            
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text('Emergency Contacts (${_contactControllers.length}/3)', style: Theme.of(context).textTheme.titleMedium),
                 IconButton(icon: const Icon(Icons.add_circle, color: Colors.blue), onPressed: _addEmergencyContact),
              ],
            ),
            if (_contactControllers.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text('Add up to 3 emergency contacts', style: TextStyle(color: Colors.grey)),
              ),
            
            ..._contactControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controllers = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.end,
                         children: [
                           IconButton(onPressed: () => _removeEmergencyContact(index), icon: const Icon(Icons.delete, color: Colors.red, size: 20)),
                         ],
                       ),
                       TextFormField(
                         controller: controllers['name'],
                         decoration: const InputDecoration(labelText: 'Contact Name', icon: Icon(Icons.person_outline)),
                         validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                       ),
                       TextFormField(
                         controller: controllers['phone'],
                         decoration: const InputDecoration(labelText: 'Contact Phone', icon: Icon(Icons.phone_outlined)),
                         keyboardType: TextInputType.phone,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                       ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
