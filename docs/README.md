# GoTogether

GoTogether is a college-exclusive ride-sharing platform built with Flutter and Firebase.

## Project Structure

- `mobile_flutter/`: Main Flutter application for Passengers and Drivers.
- `cloud_functions/`: Firebase Cloud Functions (Node.js/TypeScript).
- `firebase/`: Firebase configuration (Firestore, Storage, Security Rules).
- `admin_dashboard/`: Web-based admin dashboard.
- `docs/`: Project documentation.

## Prerequisites

- Flutter SDK (Stable)
- Node.js (v18+)
- Firebase CLI (`npm install -g firebase-tools`)
- Java JDK (for Android builds)
- Android Studio

## Setup Instructions

### 1. Firebase Emulators

The project is designed to run locally using Firebase Emulators.

1. Navigate to the `firebase/` directory (or root if configured there, but we have a dedicated folder, we might need to adjust command execution).
   *Actually, the firebase.json is in `gotogether/firebase/`.*

2. Install dependencies for Cloud Functions:
   ```bash
   cd gotogether/cloud_functions
   npm install
   ```

3. Start the emulators:
   ```bash
   cd gotogether/firebase
   firebase emulators:start --only firestore,auth,functions,storage
   ```
   *Note: Ports have been configured to avoid conflicts: Firestore (8081), Auth (9100), Functions (5002), Storage (9200), UI (4001).*

### 2. Flutter App

1. Navigate to `gotogether/mobile_flutter`:
   ```bash
   cd gotogether/mobile_flutter
   flutter pub get
   ```

2. Run the app pointing to the local emulator:
   ```bash
   flutter run
   ```
   *The app is configured to connect to localhost emulators automatically in debug mode.*

## Documentation

- [API Documentation](docs/API.md)
- [Firestore Schema](docs/firestore_schema.md)
- [Firebase Rules](docs/firebase_rules.md)
- [Android Migration](docs/android_migration.md)
