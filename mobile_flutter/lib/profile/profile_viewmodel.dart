import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';
import '../services/firebase_service.dart';

// Provider for FirebaseService
final firebaseServiceProvider = Provider<FirebaseService>((ref) => FirebaseService());

final profileViewModelProvider = AsyncNotifierProvider<ProfileViewModel, UserModel?>(ProfileViewModel.new);

class ProfileViewModel extends AsyncNotifier<UserModel?> {
  
  FirebaseService get _service => ref.read(firebaseServiceProvider);

  @override
  Future<UserModel?> build() async {
    return _service.getCurrentUserProfile();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getCurrentUserProfile());
  }

  Future<void> updateProfile(UserModel updated) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.updateUserProfile(updated);
      return updated;
    });
  }

  Future<void> updatePhoto(Uint8List imageBytes) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
       final url = await _service.uploadProfilePhoto(imageBytes, currentUser.uid);
       if (url != null) {
         final updated = currentUser.copyWith(photoUrl: url);
         await _service.updateUserProfile(updated);
         return updated;
       }
       return currentUser;
    });
  }
  
  Future<void> updateEmergencyContacts(List<EmergencyContact> contacts) async {
      final currentUser = state.value;
      if (currentUser == null) return;
      
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
         final updated = currentUser.copyWith(emergencyContacts: contacts);
         await _service.updateUserProfile(updated);
         return updated;
      });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> deleteAccount() async {
    await _service.deleteAccountCompletely();
    state = const AsyncValue.data(null);
  }
}
