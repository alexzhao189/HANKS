# forge local build notes (tiktok-flutter-clone)

## Current: local SQLite MVP auth (register + login)
- Auth is local SQLite only (no Firebase). Register inserts into `users`; login looks up email and verifies password.
- Passwords stored as **plaintext** for this offline demo MVP (no crypto package). Do not use for production.
- Optional register avatar → `hanks_media/profilePics/<uid>.jpg`; path stored in `users.profilePhoto`.
- Session uid in SharedPreferences (`local_session_uid`); restore on launch.
- DB version **2**: adds `users.password`. Fresh installs start with empty users (register required).
- Migration from v1: ALTER ADD password; legacy seeded `hanks@gmail.com` / uid `local-hanks` gets password `123` so clear-data is usually not required. If login still fails after upgrade, clear app data once and register again.
- Duplicate email → snackbar `emailAlreadyRegistered` (en/zh/ja). Wrong password → `invalidCredentials`.
- i18n (en/zh/ja) kept; GetX patterns unchanged.

## Android packaging (phone install)
- minSdk 21 (unchanged from firebase-demo)
- `ndk.abiFilters`: armeabi-v7a + arm64-v8a (required for physical arm64 phones e.g. moto X30 Pro / Android 15)
- Build for captain phone: `fvm flutter build apk --debug --target-platform android-arm,android-arm64`
- Output: `build\app\outputs\flutter-apk\app-debug.apk`
- Do NOT deliver an emulator-only APK (x86 / x86_64 only) — installer shows 应用与您的手机不兼容
- 2026-11-02: failed APK had native-code only x86+x86_64; fixed by arm rebuild + abiFilters

## Historical Firebase demo (tagged `firebase-demo`)
- FVM Flutter 3.7.12 / Dart 2.19.6
- Keep README original deps; override firebase_core_platform_interface: 4.5.1
- Android: minSdk 21; Aliyun mirrors; local gradle zip
- apply com.google.gms.google-services at bottom of android/app/build.gradle
- Toolchain: Kotlin 1.8.22, AGP 7.3.1, google-services 4.3.15, Gradle 7.6.3
