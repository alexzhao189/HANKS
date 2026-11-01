# forge local build notes (tiktok-flutter-clone)
- FVM Flutter 3.7.12 / Dart 2.19.6
- Keep README original deps; override only firebase_core_platform_interface: 4.4.1 (verifyExtends)
- Android: minSdk 21; Aliyun mirrors; local gradle zip; proxy commented
- Toolchain bump for video_compress / androidx (cf Issue #17 Kotlin mismatch):
  Kotlin 1.8.22, AGP 7.3.1, google-services 4.4.0, Gradle 7.6.3
- Issues to watch at runtime: #2/#10 video_compress null on iOS; #14 CocoaPods iOS; #19 no LICENSE
- PR #3: firestore rules for README (not merged)
