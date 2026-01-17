# Demo Script

## Prerequisites
1. Start Emulators: `firebase emulators:start`
2. Run Seed Script: `node cloud_functions/scripts/seed.js` (from root)
3. Run Flutter App: `flutter run`

## Demo Flow

### 1. Passenger Booking
1. Login as Passenger (Phone: `+919876543211`).
2. **Check the terminal** where `firebase emulators:start` is running. You will see a log like `[Auth] Generated SMS code for +919876543211: 123456`.
3. Enter that OTP code in the app.
4. See "College Gate 1 -> City Center" ride in list.
3. Tap on ride -> Book.
4. Check Firestore: `bookings` collection has new doc.

### 2. Driver Flow
1. Login as Driver (Phone: `+919876543210`).
2. **Check the terminal** for the OTP code (same as above).
3. Switch to "Driver Mode".
3. Create new ride "Library -> Hostel".
4. Check Firestore: `rides` collection has new doc.

### 3. SOS
1. Tap SOS button (if implemented).
2. Check Firestore: `sos` collection has new doc.
