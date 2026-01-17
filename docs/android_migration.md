# Android Migration Guide

## Steps to Open in Android Studio

1. **Open Android Studio**.
2. Select **Open**.
3. Navigate to `d:/GoTogether/gotogether/mobile_flutter/android`.
4. Click **OK**.
5. Wait for Gradle Sync to complete.

## Configuration

### 1. google-services.json
- Download `google-services.json` from Firebase Console.
- Place it in `mobile_flutter/android/app/`.

### 2. Google Maps API Key
- Open `mobile_flutter/android/app/src/main/AndroidManifest.xml`.
- Add your API key:
  ```xml
  <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_API_KEY"/>
  ```

### 3. Keystore (Release Build)
- Create a keystore:
  ```bash
  keytool -genkey -v -keystore my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias
  ```
- Configure `key.properties` and `build.gradle`.

## Running
- Select your device/emulator in Android Studio.
- Click **Run**.
