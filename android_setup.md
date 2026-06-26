# Android Setup Notes

After running `flutter create --org com.plantdoc --project-name plantdoc_ai .`

## Required AndroidManifest.xml permissions

Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

Add to `<application>` tag for HTTP support (dev only):
```xml
android:usesCleartextTraffic="true"
```

## iOS Info.plist keys

Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>PlantDoc AI needs camera access to photograph plant leaves for disease analysis.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>PlantDoc AI needs photo library access to select plant images for analysis.</string>
```

## Build Steps

```bash
# 1. Create platform folders
flutter create --org com.plantdoc --project-name plantdoc_ai .

# 2. Install dependencies
flutter pub get

# 3. Generate launcher icons
dart run flutter_launcher_icons

# 4. Build APK
flutter build apk --release

# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```
