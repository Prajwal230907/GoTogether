import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class PhoneAuthState {
  final bool isLoading;
  final String? error;
  final String? verificationId;
  final bool isCodeSent;

  PhoneAuthState({
    this.isLoading = false,
    this.error,
    this.verificationId,
    this.isCodeSent = false,
  });

  PhoneAuthState copyWith({
    bool? isLoading,
    String? error,
    String? verificationId,
    bool? isCodeSent,
  }) {
    return PhoneAuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      verificationId: verificationId ?? this.verificationId,
      isCodeSent: isCodeSent ?? this.isCodeSent,
    );
  }
}

class PhoneAuthViewModel extends Notifier<PhoneAuthState> {
  late final FirebaseAuth _auth;

  @override
  PhoneAuthState build() {
    _auth = FirebaseAuth.instance;
    return PhoneAuthState();
  }

  Timer? _timeoutTimer;

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    _timeoutTimer?.cancel();

    _timeoutTimer = Timer(const Duration(seconds: 60), () {
      if (state.isLoading) {
        state = state.copyWith(
          isLoading: false,
          error: "Verification timed out. Please check your internet connection and try again.",
        );
      }
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _timeoutTimer?.cancel();
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _timeoutTimer?.cancel();
          state = state.copyWith(isLoading: false, error: e.message);
        },
        codeSent: (String verificationId, int? resendToken) {
          _timeoutTimer?.cancel();
          state = state.copyWith(
            isLoading: false,
            verificationId: verificationId,
            isCodeSent: true,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _timeoutTimer?.cancel();
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } catch (e) {
      _timeoutTimer?.cancel();
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> verifyOtp(String smsCode) async {
    if (state.verificationId == null) {
      state = state.copyWith(error: "Verification ID is missing. Please request OTP again.");
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: smsCode,
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      await _auth.signInWithCredential(credential);
      state = state.copyWith(isLoading: false, error: null);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final phoneAuthViewModelProvider = NotifierProvider<PhoneAuthViewModel, PhoneAuthState>(PhoneAuthViewModel.new);
