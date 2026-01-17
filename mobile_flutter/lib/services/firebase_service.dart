import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../data/models.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, user.uid);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null; // Or rethrow
    }
  }

  Future<void> updateUserProfile(UserModel updated) async {
    try {
      await _firestore.collection('users').doc(updated.uid).update(updated.toMap());
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  Future<String?> uploadProfilePhoto(Uint8List bytes, String uid) async {
    try {
      final ref = _storage.ref().child('user_photos/$uid/profile.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile photo: $e');
      throw e;
    }
  }

  Future<void> updateEmergencyContacts(List<EmergencyContact> contacts) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final contactMaps = contacts.map((e) => e.toMap()).toList();
      await _firestore.collection('users').doc(user.uid).update({
        'emergencyContacts': contactMaps,
      });
    } catch (e) {
      print('Error updating emergency contacts: $e');
      throw e;
    }
  }
  
  Future<void> changePhoneNumber(String newPhone) async {
     // TODO: Implement phone number change logic requiring re-verification
     throw UnimplementedError('Phone number change not implemented');
  }

  Future<void> deleteAccountCompletely() async {
     final user = _auth.currentUser;
     if (user == null) return;
     
     try {
       // 1. Delete Firestore Data
       await _firestore.collection('users').doc(user.uid).delete();
       
       // 2. Delete Storage Files (Profile Photo)
        try {
          await _storage.ref().child('user_photos/${user.uid}/profile.jpg').delete();
        } catch (e) {
          // Ignore if file doesn't exist
          print('Storage delete error (might be benign): $e');
        }

       // 3. Delete Auth Account
       await user.delete();
     } catch (e) {
       print('Error deleting account: $e');
       throw e;
     }
  }
}
