# forge local build notes (tiktok-flutter-clone)
- FVM Flutter 3.7.12 / Dart 2.19.6
- Keep README original deps; override firebase_core_platform_interface: 4.5.1
  (4.4.1 = MethodChannel vs native Pigeon → MissingPluginException Firebase#initializeCore;
   4.5.2+ drops verifyExtends which firebase_core 1.24 still calls)
- Android: minSdk 21; Aliyun mirrors; local gradle zip; proxy commented
- apply com.google.gms.google-services at bottom of android/app/build.gradle
- Toolchain bump for video_compress / androidx (cf Issue #17 Kotlin mismatch):
  Kotlin 1.8.22, AGP 7.3.1, google-services 4.3.15 (4.4.0 failed to merge google_app_id into APK), Gradle 7.6.3
- Issues to watch at runtime: #2/#10 video_compress null on iOS; #14 CocoaPods iOS; #19 no LICENSE
- PR #3: firestore rules for README (not merged)
