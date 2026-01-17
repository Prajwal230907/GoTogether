# Walkthrough

## Completed Work
- **Monorepo Setup**: Created `gotogether` with `mobile_flutter`, `cloud_functions`, `firebase`, and `docs`.
- **Firebase**: Configured Firestore, Storage, and Emulators (Ports: 8081, 9100, 5002, 9200).
- **Cloud Functions**: Implemented `onCreateBooking`, `onPaymentWebhook`, `sendFCM` and a seed script.
- **Flutter App**:
    - **Auth**: Phone Login + Profile Creation (College ID placeholder).
    - **Passenger**: Home screen with Ride List and Booking dialog.
    - **Driver**: Create Ride and Simulate Location.
    - **Platforms**: Added Web and Windows support.

## Verification Steps

### 1. Start Emulators
```bash
cd gotogether/firebase
firebase emulators:start --project demo-gotogether --only firestore,auth,storage,functions
```

### 2. Seed Data
```bash
cd gotogether
node cloud_functions/scripts/seed.js
```

### 3. Run App (Chrome)
```bash
cd gotogether/mobile_flutter
flutter run -d chrome
```

### 4. Test Flow
1. **Login**: Use Phone `+919876543211`, OTP `123456`.
2. **Book Ride**:
    - You should see a ride from "College Gate 1" to "City Center".
    - Tap the arrow icon.
    - Click **Book** in the dialog.
    - Verify "Booking Confirmed!" message.
3. **Driver Mode**:
    - Click "Driver Mode" in the app bar.
    - Click "Create a Ride" to add a new ride.
    - Click "Start Trip" to simulate location updates (check console for logs).
