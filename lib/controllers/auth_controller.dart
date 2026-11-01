import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/l10n/l10n_helper.dart';
import 'package:tiktok_tutorial/models/user.dart' as model;
import 'package:tiktok_tutorial/views/screens/auth/login_screen.dart';
import 'package:tiktok_tutorial/views/screens/home_screen.dart';
import 'package:flutter/material.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  late Rx<User?> _user;
  final Rx<File?> _pickedImage = Rx<File?>(null);
  final RxBool isLoading = false.obs;

  /// When true, authStateChanges must not navigate away mid-signup
  /// (createUser fires before Storage/Firestore finish).
  bool _completingRegistration = false;

  File? get profilePhoto => _pickedImage.value;
  User get user => _user.value!;

  @override
  void onReady() {
    super.onReady();
    _user = Rx<User?>(firebaseAuth.currentUser);
    _user.bindStream(firebaseAuth.authStateChanges());
    ever(_user, _setInitialScreen);

    // Storage uploads from CN / flaky VPN benefit from longer retries.
    try {
      firebaseStorage.setMaxUploadRetryTime(const Duration(seconds: 120));
      firebaseStorage.setMaxOperationRetryTime(const Duration(seconds: 120));
      debugPrint(
        'FirebaseStorage ready: bucket=${firebaseStorage.bucket} '
        'app=${firebaseStorage.app.name}',
      );
    } catch (e, st) {
      debugPrint('FirebaseStorage retry config failed: $e\n$st');
    }
  }

  _setInitialScreen(User? user) {
    if (_completingRegistration) return;
    if (user == null) {
      Get.offAll(() => LoginScreen());
    } else {
      Get.offAll(() => const HomeScreen());
    }
  }

  void pickImage() async {
    try {
      // Downscale/compress at pick time — large gallery HEIC/JPEG often
      // triggers firebase_storage [unknown] on putFile over weak links.
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (pickedImage != null) {
        final file = File(pickedImage.path);
        if (!await file.exists()) {
          Get.snackbar(
            'Profile Picture',
            'Could not read the selected image file.',
          );
          return;
        }
        _pickedImage.value = file;
        final bytes = await file.length();
        debugPrint(
          'pickImage ok: path=${file.path} sizeBytes=$bytes '
          'mime=${pickedImage.mimeType}',
        );
        final l10n = tryL10n();
        Get.snackbar(
          l10n?.profilePictureTitle ?? 'Profile Picture',
          l10n?.profilePictureSuccess ??
              'You have successfully selected your profile picture!',
        );
      }
    } catch (e, st) {
      debugPrint('pickImage failed: $e\n$st');
      Get.snackbar('Profile Picture', 'Failed to pick image: $e');
    }
  }

  // upload to firebase storage
  Future<String> _uploadToStorage(File image) async {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Not signed in; cannot upload profile photo.');
    }

    final path = 'profilePics/$uid';
    final bucket = firebaseStorage.bucket;
    final fileSize = await image.length();
    debugPrint(
      '_uploadToStorage start: bucket=$bucket path=$path '
      'file=${image.path} sizeBytes=$fileSize '
      'authUid=$uid',
    );

    if (fileSize <= 0) {
      throw StateError('Profile photo is empty (0 bytes). Pick again.');
    }
    // Soft cap — if somehow still huge, fail with a clear message.
    if (fileSize > 8 * 1024 * 1024) {
      throw StateError(
        'Profile photo is ${fileSize ~/ (1024 * 1024)}MB; '
        'please pick a smaller image (under 8MB).',
      );
    }

    final Reference ref = firebaseStorage.ref().child('profilePics').child(uid);

    // Prefer putData + explicit contentType: more reliable than putFile on
    // Android (path/URI quirks) and satisfies rules that match image/*.
    final Uint8List bytes = await image.readAsBytes();
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: <String, String>{
        'uid': uid,
        'source': 'signup_profile',
      },
    );

    UploadTask uploadTask = ref.putData(bytes, metadata);
    try {
      TaskSnapshot snap = await uploadTask.timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          uploadTask.cancel();
          throw TimeoutException(
            'Storage upload timed out after 120s '
            '(bucket=$bucket path=$path size=$fileSize). '
            'Check VPN/network, Storage rules, and App Check.',
          );
        },
      );
      debugPrint(
        '_uploadToStorage putData done: state=${snap.state} '
        'bytesTransferred=${snap.bytesTransferred}',
      );
      String downloadUrl = await snap.ref.getDownloadURL().timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw TimeoutException(
          'getDownloadURL timed out (bucket=$bucket path=$path).',
        ),
      );
      debugPrint('_uploadToStorage ok: urlLen=${downloadUrl.length}');
      return downloadUrl;
    } on FirebaseException catch (e, st) {
      debugPrint(
        '_uploadToStorage FirebaseException: plugin=${e.plugin} '
        'code=${e.code} message=${e.message} '
        'bucket=$bucket path=$path sizeBytes=$fileSize\n$st',
      );
      rethrow;
    } catch (e, st) {
      debugPrint(
        '_uploadToStorage failed: $e bucket=$bucket path=$path '
        'sizeBytes=$fileSize\n$st',
      );
      rethrow;
    }
  }

  void _closeLoadingDialog() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  void _showLoadingDialog() {
    if (Get.isDialogOpen == true) return;
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
  }

  String _friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      return 'Auth [${e.code}]: ${e.message ?? e.code}';
    }
    if (e is FirebaseException) {
      final base = '${e.plugin} [${e.code}]: ${e.message ?? e.code}';
      if (e.plugin.contains('storage')) {
        final bucket = firebaseStorage.bucket;
        return '$base | bucket=$bucket. '
            'If this persists: Console → Storage rules must allow '
            'write when request.auth != null for profilePics/{uid}; '
            'disable App Check enforcement; confirm VPN reaches '
            'firebasestorage.googleapis.com.';
      }
      return base;
    }
    if (e is TimeoutException) {
      return e.message ?? 'Operation timed out';
    }
    return e.toString();
  }

  // registering the user
  Future<void> registerUser(
      String username, String email, String password, File? image) async {
    if (isLoading.value) return;
    final l10n = tryL10n();
    try {
      if (image == null) {
        Get.snackbar(
          l10n?.profilePictureTitle ?? 'Profile Picture',
          'Please pick a profile photo before registering.',
        );
        return;
      }
      if (!await image.exists()) {
        Get.snackbar(
          l10n?.profilePictureTitle ?? 'Profile Picture',
          'Selected photo is missing on disk. Please pick again.',
        );
        return;
      }
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        Get.snackbar(
          l10n?.errorCreatingAccount ?? 'Error Creating Account',
          l10n?.pleaseEnterAllFields ?? 'Please enter all the fields',
        );
        return;
      }

      isLoading.value = true;
      _completingRegistration = true;
      _showLoadingDialog();

      // 1) Auth
      UserCredential cred = await firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () => throw TimeoutException(
              'Firebase Auth createUser timed out after 120s. '
              'Cold Auth from CN can be slow; if this repeats, check Wi-Fi/VPN, '
              'emulator reachability to identitytoolkit.googleapis.com, '
              'and that Email/Password is enabled on the Firebase project.',
            ),
          );
      debugPrint(
        'registerUser Auth ok: uid=${cred.user?.uid} '
        'email=${cred.user?.email}',
      );

      // 2) Storage (common hang / rules failure point)
      String downloadUrl = await _uploadToStorage(image);

      // 3) Firestore user doc
      model.User user = model.User(
        name: username.trim(),
        email: email.trim(),
        uid: cred.user!.uid,
        profilePhoto: downloadUrl,
      );
      await firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(user.toJson())
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () => throw TimeoutException(
              'Firestore set timed out. Check Firestore rules / network.',
            ),
          );
      debugPrint('registerUser Firestore ok: uid=${cred.user!.uid}');

      _completingRegistration = false;
      _closeLoadingDialog();
      isLoading.value = false;
      Get.offAll(() => const HomeScreen());
    } catch (e, st) {
      debugPrint('registerUser failed: $e\n$st');
      _completingRegistration = false;
      _closeLoadingDialog();
      isLoading.value = false;
      // Auth user may already exist while Storage/Firestore failed — sign out
      // so the user can retry cleanly instead of sitting on a half-created session.
      try {
        if (firebaseAuth.currentUser != null) {
          await firebaseAuth.signOut();
        }
      } catch (_) {}
      Get.snackbar(
        l10n?.errorCreatingAccount ?? 'Error Creating Account',
        _friendlyError(e),
        duration: const Duration(seconds: 12),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> loginUser(String email, String password) async {
    if (isLoading.value) return;
    final l10n = tryL10n();
    try {
      if (email.isEmpty || password.isEmpty) {
        Get.snackbar(
          l10n?.errorLoggingIn ?? 'Error Logging in',
          l10n?.pleaseEnterAllFields ?? 'Please enter all the fields',
        );
        return;
      }
      isLoading.value = true;
      _showLoadingDialog();
      await firebaseAuth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () => throw TimeoutException(
              'Firebase Auth signIn timed out after 120s. '
              'Retry on a stable network/VPN; first Auth call from CN may be slow.',
            ),
          );
      _closeLoadingDialog();
      isLoading.value = false;
      // Navigation via authStateChanges / _setInitialScreen
    } catch (e, st) {
      debugPrint('loginUser failed: $e\n$st');
      _closeLoadingDialog();
      isLoading.value = false;
      Get.snackbar(
        l10n?.errorLoggingIn ?? 'Error Logging in',
        _friendlyError(e),
        duration: const Duration(seconds: 8),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void signOut() async {
    await firebaseAuth.signOut();
  }
}
