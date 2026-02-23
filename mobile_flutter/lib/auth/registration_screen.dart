import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  File? _idCardImage;
  bool _isLoading = false;
  String _selectedRole = 'passenger'; // default role

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _idCardImage = File(pickedFile.path);
      });
    }
  }

  bool _isValidCollegeEmail(String email) {
    // Check if email ends with .edu or @college.edu (placeholder for real college domain)
    final emailLower = email.toLowerCase().trim();
    return emailLower.endsWith('.edu') || emailLower.endsWith('@college.edu');
  }

  Future<void> _completeRegistration() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _idCardImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and upload ID card')));
      return;
    }

    if (!_isValidCollegeEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Must use a valid college email (.edu or @college.edu)')));
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Upload ID Card
      final folder = _selectedRole == 'driver' ? 'drivers' : 'users';
      final ref = FirebaseStorage.instance.ref().child('$folder/${user.uid}/id_card.jpg');
      await ref.putFile(_idCardImage!);
      final idCardUrl = await ref.getDownloadURL();

      // Save User Data securely binding the role
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': user.phoneNumber,
        'idCardUrl': idCardUrl,
        'verified': false,
        'role': _selectedRole, // 'passenger' or 'driver'
        'createdAt': FieldValue.serverTimestamp(),
        'fcmTokens': [],
      });
      
      if (mounted) {
        if (_selectedRole == 'driver') {
          context.go('/driver_home');
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _selectedRole == 'passenger' ? const Color(0xFF2E7EFF) : const Color(0xFFA855F7);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Complete Profile', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Role Selection
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'passenger'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'passenger' ? const Color(0xFF2E7EFF).withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text('Passenger', style: TextStyle(
                              color: _selectedRole == 'passenger' ? const Color(0xFF2E7EFF) : Colors.grey,
                              fontWeight: FontWeight.bold,
                            )),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'driver'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'driver' ? const Color(0xFFA855F7).withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text('Driver', style: TextStyle(
                              color: _selectedRole == 'driver' ? const Color(0xFFA855F7) : Colors.grey,
                              fontWeight: FontWeight.bold,
                            )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24.0),
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: primaryColor))
                    : _buildForm(primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
             enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
             focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
             fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'College Email (.edu or @college.edu)',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
             enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
             focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
             fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _idCardImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_idCardImage!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file, size: 40, color: primaryColor.withOpacity(0.5)),
                      const SizedBox(height: 8),
                      Text('Upload Student ID', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      Text('(Valid College ID needed)', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _completeRegistration,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: primaryColor,
             elevation: 0,
            foregroundColor: Colors.white,
          ),
          child: Text('Register as ${_selectedRole == 'passenger' ? 'Passenger' : 'Driver'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
