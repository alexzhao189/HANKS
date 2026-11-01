# forge local build notes (tiktok-flutter-clone)

## Current: local SQLite MVP (post `firebase-demo` tag)
- Fake login only: hanks@gmail.com / 123 (hardcoded)
- SQLite (sqflite) for users/videos/comments/followers
- Media under app documents (`hanks_media/`); playback via local file paths
- Firebase Auth/Firestore/Storage removed; google-services plugin stripped
- i18n (en/zh/ja) kept

## Historical Firebase demo (tagged `firebase-demo`)
- FVM Flutter 3.7.12 / Dart 2.19.6
- Keep README original deps; override firebase_core_platform_interface: 4.5.1
- Android: minSdk 21; Aliyun mirrors; local gradle zip
- apply com.google.gms.google-services at bottom of android/app/build.gradle
- Toolchain: Kotlin 1.8.22, AGP 7.3.1, google-services 4.3.15, Gradle 7.6.3
