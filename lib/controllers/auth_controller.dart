import 'dart:async';
import 'dart:io';
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
      final pickedImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);
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
        final l10n = tryL10n();
        Get.snackbar(
          l10n?.profilePictureTitle ?? 'Profile Picture',
          l10n?.profilePictureSuccess ??
              'You have successfully selected your profile picture!',
        );
      }
    } catch (e) {
      Get.snackbar('Profile Picture', 'Failed to pick image: $e');
    }
  }

  // upload to firebase storage
  Future<String> _uploadToStorage(File image) async {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Not signed in; cannot upload profile photo.');
    }
    Reference ref =
        firebaseStorage.ref().child('profilePics').child(uid);

    UploadTask uploadTask = ref.putFile(image);
    TaskSnapshot snap = await uploadTask.timeout(
      const Duration(seconds: 90),
      onTimeout: () {
        uploadTask.cancel();
        throw TimeoutException(
          'Storage upload timed out after 90s. Check Storage rules / network.',
        );
      },
    );
    String downloadUrl = await snap.ref.getDownloadURL().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('getDownloadURL timed out.'),
    );
    return downloadUrl;
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
      return '${e.plugin} [${e.code}]: ${e.message ?? e.code}';
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
            const Duration(seconds: 60),
            onTimeout: () => throw TimeoutException(
              'Firebase Auth createUser timed out. Check network / Auth config.',
            ),
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

      _completingRegistration = false;
      _closeLoadingDialog();
      isLoading.value = false;
      Get.offAll(() => const HomeScreen());
    } catch (e) {
      debugPrint('registerUser failed: $e');
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
        duration: const Duration(seconds: 6),
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
            const Duration(seconds: 60),
            onTimeout: () => throw TimeoutException(
              'Firebase Auth signIn timed out. Check network.',
            ),
          );
      _closeLoadingDialog();
      isLoading.value = false;
      // Navigation via authStateChanges / _setInitialScreen
    } catch (e) {
      debugPrint('loginUser failed: $e');
      _closeLoadingDialog();
      isLoading.value = false;
      Get.snackbar(
        l10n?.errorLoggingIn ?? 'Error Logging in',
        _friendlyError(e),
        duration: const Duration(seconds: 6),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void signOut() async {
    await firebaseAuth.signOut();
  }
}
