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

## Android packaging (emulator + phone)
- minSdk 21 (unchanged from firebase-demo)
- `ndk.abiFilters` (committed): `armeabi-v7a`, `arm64-v8a`, `x86`, `x86_64`
  - arm* → physical phones (e.g. moto X30 Pro)
  - x86* → Android emulator (`sdk gphone64 x86 64`); without these, launch crashes with `libflutter.so` not found
- Emulator / day-to-day: `fvm flutter run` (or `fvm flutter run -d emulator-XXXX`)
- Phone sideload fat debug APK: `fvm flutter build apk --debug` (all filtered ABIs included)
  - Output: `build\app\outputs\flutter-apk\app-debug.apk`
- **Phone-only ARM APK (use this for moto X30 Pro sideload):**
  1. Temporarily set `abiFilters 'armeabi-v7a', 'arm64-v8a'` in `android/app/build.gradle` (do not commit)
  2. `fvm flutter build apk --debug --target-platform android-arm,android-arm64`
  3. Copy to distinct name: `build\app\outputs\flutter-apk\hanks-phone-arm64-debug.apk`
  4. Restore abiFilters to all four ABIs
  5. Verify: `aapt dump badging ...\hanks-phone-arm64-debug.apk` must show `native-code: 'arm64-v8a' 'armeabi-v7a'` (no x86-only)
- **Captain install path:** `D:\repo\tiktok-flutter-clone\build\app\outputs\flutter-apk\hanks-phone-arm64-debug.apk`
  - Size ~49 MB (≈46.8 MiB) — NOT the ~72.84 MiB / ~76 MB `app-debug.apk` which is often an emulator/x86 build
  - Stale QQ-browser / WeChat copies of the old x86-only APK install as `安装失败` / `应用与您的手机不兼容`
- Verify native libs: unzip APK and check `lib/arm64-v8a/libflutter.so` exists for phone; `lib/x86_64/libflutter.so` for emulator fat builds
- 2026-11-02: arm-only abiFilters broke emulator (`UnsatisfiedLinkError: libflutter.so`); expanded filters to include x86/x86_64 while keeping arm64 for phone
- 2026-11-02 (later): moto X30 Pro failed again on ~72.84 MiB APK — that file was x86/x86_64 only (`aapt` native-code). Built distinct `hanks-phone-arm64-debug.apk` with arm64-v8a+armeabi-v7a only (~49 MB)

## Historical Firebase demo (tagged `firebase-demo`)
- FVM Flutter 3.7.12 / Dart 2.19.6
- Keep README original deps; override firebase_core_platform_interface: 4.5.1
- Android: minSdk 21; Aliyun mirrors; local gradle zip
- apply com.google.gms.google-services at bottom of android/app/build.gradle
- Toolchain: Kotlin 1.8.22, AGP 7.3.1, google-services 4.3.15, Gradle 7.6.3

