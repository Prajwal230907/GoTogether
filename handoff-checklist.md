# Handoff Checklist

## Files to Copy/Configure

- [ ] **google-services.json**: Place in `mobile_flutter/android/app/`.
- [ ] **GoogleService-Info.plist**: Place in `mobile_flutter/ios/Runner/` (if iOS).
- [ ] **.env**: Create in `cloud_functions/` with keys if not using `functions:config`.

## Environment Variables
Run these commands to set up Cloud Functions config:
```bash
firebase functions:config:set razorpay.key_id="KEY" razorpay.key_secret="SECRET"
firebase functions:config:get > .runtimeconfig.json
```

## Running Locally
1. `cd gotogether/firebase`
2. `firebase emulators:start --only firestore,auth,functions,storage`
3. `cd ../cloud_functions`
4. `node scripts/seed.js` (Optional)
5. `cd ../mobile_flutter`
6. `flutter run`

## Android Studio
- Open `mobile_flutter/android` folder.
- Sync Gradle.
- Run.
