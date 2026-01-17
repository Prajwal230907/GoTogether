import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';

class DriverVerificationScreen extends ConsumerStatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  ConsumerState<DriverVerificationScreen> createState() => _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends ConsumerState<DriverVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleModelController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  
  File? _collegeIdImage;
  File? _licenseImage;
  File? _rcImage;
  File? _vehicleImage;
  File? _driverPhotoImage;

  bool _isUploading = false;

  Future<void> _pickImage(void Function(File?) onPick) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        onPick(File(pickedFile.path));
      });
    }
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _submitVerification() async {
    // BYPASS: Validation skipped for testing
    // if (!_formKey.currentState!.validate()) return;
    // if (_collegeIdImage == null || _licenseImage == null || _rcImage == null || _vehicleImage == null || _driverPhotoImage == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload all required documents.')));
    //   return;
    // }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // BYPASS: Image upload skipped for testing
      /*
      final collegeIdUrl = await _uploadFile(_collegeIdImage!, 'drivers/${user.uid}/college_id.jpg');
      final licenseUrl = await _uploadFile(_licenseImage!, 'drivers/${user.uid}/license.jpg');
      final rcUrl = await _uploadFile(_rcImage!, 'drivers/${user.uid}/rc.jpg');
      final vehicleUrl = await _uploadFile(_vehicleImage!, 'drivers/${user.uid}/vehicle.jpg');
      final driverPhotoUrl = await _uploadFile(_driverPhotoImage!, 'drivers/${user.uid}/driver_photo.jpg');

      if (collegeIdUrl == null || licenseUrl == null || rcUrl == null || vehicleUrl == null || driverPhotoUrl == null) {
        throw Exception('Failed to upload one or more images.');
      }
      */

      // BYPASS: Using dummy URLs
      const dummyUrl = 'https://via.placeholder.com/150';

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'driverVerificationStatus': 'verified', // BYPASS: Auto-verified
        'vehicleModel': _vehicleModelController.text.trim().isEmpty ? 'Test Vehicle' : _vehicleModelController.text.trim(),
        'vehiclePlate': _vehiclePlateController.text.trim().isEmpty ? 'TEST-1234' : _vehiclePlateController.text.trim(),
        'documents': {
          'collegeId': dummyUrl,
          'license': dummyUrl,
          'rc': dummyUrl,
          'vehicle': dummyUrl,
          'driverPhoto': dummyUrl,
        },
        'submittedAt': FieldValue.serverTimestamp(),
        'verifiedAt': FieldValue.serverTimestamp(), // Added verifiedAt
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bypass: Driver Auto-Verified!')));
        context.go('/driver_home'); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting verification: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildImagePicker(String label, File? image, void Function(File?) onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickImage(onPick),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).canvasColor,
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(image, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.blue[400]),
                      const SizedBox(height: 8),
                      Text('Tap to upload', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Verification', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [AppColorsDark.primaryGradientStart, AppColorsDark.primaryGradientEnd]
                  : [AppColorsLight.primaryGradientStart, AppColorsLight.primaryGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vehicle Details',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _vehicleModelController,
                              decoration: InputDecoration(
                                labelText: 'Vehicle Model',
                                hintText: 'e.g. Swift Dzire',
                                prefixIcon: const Icon(Icons.directions_car),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _vehiclePlateController,
                              decoration: InputDecoration(
                                labelText: 'Vehicle Plate Number',
                                hintText: 'e.g. KA 01 AB 1234',
                                prefixIcon: const Icon(Icons.confirmation_number),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Required Documents',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                            ),
                            const SizedBox(height: 16),
                            _buildImagePicker('College ID', _collegeIdImage, (f) => _collegeIdImage = f),
                            _buildImagePicker('Driving License', _licenseImage, (f) => _licenseImage = f),
                            _buildImagePicker('Vehicle RC', _rcImage, (f) => _rcImage = f),
                            _buildImagePicker('Vehicle Photo', _vehicleImage, (f) => _vehicleImage = f),
                            _buildImagePicker('Driver Photo', _driverPhotoImage, (f) => _driverPhotoImage = f),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submitVerification,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF0072FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: const Text('Submit for Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
