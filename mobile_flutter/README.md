# mobile_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Phone Authentication Setup

### 1. Android Studio Setup
To use Firebase Phone Authentication, you need to add your SHA-1 and SHA-256 fingerprints to the Firebase Console.

1. Open the project in Android Studio.
2. Open the **Gradle** pane on the right side.
3. Navigate to `android` -> `app` -> `Tasks` -> `android` -> `signingReport`.
4. Double-click `signingReport` to run it.
5. Copy the SHA-1 and SHA-256 keys from the output.
6. Go to your Firebase Console -> Project Settings -> General.
7. Add the fingerprints under "Your apps" for the Android app.
8. Download the updated `google-services.json` and place it in `android/app/`.

### 2. Enable Phone Auth
1. Go to Firebase Console -> Authentication -> Sign-in method.
2. Enable **Phone**.

### 3. Testing Notes
Firebase Phone Auth works best on a real device. For emulators, use the test numbers configured in the Firebase Console.

**Test Number:**
- Phone: `+911234567890`
- Code: `123456`
