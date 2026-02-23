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

  Future<String?> _uploadFile(File file, String fileName, String uid) async {
    try {
      final imagePath = file.path;
      print('Debug: imagePath is $imagePath');
      
      if (imagePath.isEmpty) {
         throw Exception("imagePath is empty");
      }
      if (!await File(imagePath).exists()) {
         throw Exception("File does not exist before upload");
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('drivers/$uid/documents/$fileName.jpg');

      // Use putFile which is safer for larger files
      final uploadTask = storageRef.putFile(File(imagePath));
      final snapshot = await uploadTask;
      
      if (snapshot.state != TaskState.success) {
        throw Exception("Upload failed with state: ${snapshot.state}");
      }
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
      
    } on FirebaseException catch (e) {
      print("Firebase Storage Error: ${e.code}");
      print("Message: ${e.message}");
      rethrow;
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_licenseImage == null || _rcImage == null || _vehicleImage == null || _driverPhotoImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload all required documents.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in.");
      
      final uid = user.uid;

      // Fetch user data for the verification record
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      final String driverName = userData['name'] ?? 'Unknown';
      final String driverCollege = userData['college'] ?? 'Unknown';
      final String existingCollegeIdUrl = userData['documents']?['collegeId'] ?? '';

      final licenseUrl = await _uploadFile(_licenseImage!, 'license', uid);
      final rcUrl = await _uploadFile(_rcImage!, 'rc', uid);
      final selfieUrl = await _uploadFile(_driverPhotoImage!, 'selfie', uid);
      // Optional: vehicleUrl not strictly in the user's final list, but the screen has it. Let's upload it anyway.
      final vehicleUrl = await _uploadFile(_vehicleImage!, 'vehicle', uid);

      if (licenseUrl == null || rcUrl == null || selfieUrl == null || vehicleUrl == null) {
        throw Exception('Failed to upload one or more images.');
      }

      final vModel = _vehicleModelController.text.trim();
      final vPlate = _vehiclePlateController.text.trim();

      // Write to verifications collection for Admin
      await FirebaseFirestore.instance.collection('verifications').doc(uid).set({
        'driverId': uid,
        'name': driverName,
        'college': driverCollege,
        'vehicleModel': vModel,
        'plateNumber': vPlate,
        'collegeIdUrl': existingCollegeIdUrl, // Sourced from registration if available
        'licenseUrl': licenseUrl,
        'rcUrl': rcUrl,
        'selfieUrl': selfieUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'verifiedAt': null,
        'adminRemarks': '',
      });

      await FirebaseFirestore.instance.collection('drivers').doc(uid).set({
        'licenseUrl': licenseUrl,
        'rcUrl': rcUrl,
        'selfieUrl': selfieUrl,
        'vehicleUrl': vehicleUrl,
        'verificationStatus': "pending",
        'vehicleModel': vModel,
        'vehiclePlate': vPlate,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'driverVerificationStatus': 'pending', 
        'isVerified': false, // Add this explicit flag for ride creation
        'documents': {
          'license': licenseUrl,
          'rc': rcUrl,
          'driverPhoto': selfieUrl,
          'vehicle': vehicleUrl,
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification Submitted Successfully!')));
        context.go('/driver_home'); 
      }
    } on FirebaseException catch (e) {
      print("Firebase Storage Error: ${e.code}");
      print("Message: ${e.message}");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Firebase Error: ${e.message ?? e.code}')));
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
