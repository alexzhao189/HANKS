import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktok_tutorial/l10n/l10n_helper.dart';
import 'package:tiktok_tutorial/models/app_user.dart';
import 'package:tiktok_tutorial/models/user.dart' as model;
import 'package:tiktok_tutorial/services/local_db.dart';
import 'package:tiktok_tutorial/services/local_media.dart';
import 'package:tiktok_tutorial/views/screens/auth/login_screen.dart';
import 'package:tiktok_tutorial/views/screens/home_screen.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  final Rx<AppUser?> _user = Rx<AppUser?>(null);
  final Rx<File?> _pickedImage = Rx<File?>(null);
  final RxBool isLoading = false.obs;

  static const _sessionKey = 'local_session_uid';

  File? get profilePhoto => _pickedImage.value;
  AppUser get user => _user.value!;
  bool get isLoggedIn => _user.value != null;

  @override
  void onReady() {
    super.onReady();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_sessionKey);
    if (uid == null || uid.isEmpty) {
      _user.value = null;
      Get.offAll(() => LoginScreen());
      return;
    }
    final row = await LocalDb.instance.getUserByUid(uid);
    if (row == null) {
      await prefs.remove(_sessionKey);
      _user.value = null;
      Get.offAll(() => LoginScreen());
      return;
    }
    _user.value = AppUser(uid: row.uid, email: row.email);
    Get.offAll(() => const HomeScreen());
  }

  Future<void> _persistSession(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, uid);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  void pickImage() async {
    try {
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

  /// Signup kept for UI: only demo email/password accepted; saves local profile.
  Future<void> registerUser(
      String username, String email, String password, File? image) async {
    if (isLoading.value) return;
    final l10n = tryL10n();
    final em = email.trim().toLowerCase();
    if (em != LocalDb.demoEmail || password != LocalDb.demoPassword) {
      Get.snackbar(
        l10n?.errorCreatingAccount ?? 'Error Creating Account',
        'Demo only: use ${LocalDb.demoEmail} / ${LocalDb.demoPassword}',
        duration: const Duration(seconds: 6),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (username.isEmpty) {
      Get.snackbar(
        l10n?.errorCreatingAccount ?? 'Error Creating Account',
        l10n?.pleaseEnterAllFields ?? 'Please enter all the fields',
      );
      return;
    }

    try {
      isLoading.value = true;
      _showLoadingDialog();

      String photoPath = '';
      if (image != null && await image.exists()) {
        photoPath =
            await LocalMedia.instance.saveProfilePhoto(LocalDb.demoUid, image);
      }

      final existing = await LocalDb.instance.getUserByUid(LocalDb.demoUid);
      final user = model.User(
        name: username.trim(),
        email: LocalDb.demoEmail,
        uid: LocalDb.demoUid,
        profilePhoto: photoPath.isNotEmpty
            ? photoPath
            : (existing?.profilePhoto ?? ''),
      );
      await LocalDb.instance.upsertUser(user);
      _user.value = AppUser(uid: user.uid, email: user.email);
      await _persistSession(user.uid);

      _closeLoadingDialog();
      isLoading.value = false;
      Get.offAll(() => const HomeScreen());
    } catch (e, st) {
      debugPrint('registerUser failed: $e\n$st');
      _closeLoadingDialog();
      isLoading.value = false;
      Get.snackbar(
        l10n?.errorCreatingAccount ?? 'Error Creating Account',
        e.toString(),
        duration: const Duration(seconds: 8),
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
      final em = email.trim().toLowerCase();
      if (em != LocalDb.demoEmail || password != LocalDb.demoPassword) {
        Get.snackbar(
          l10n?.errorLoggingIn ?? 'Error Logging in',
          'Invalid credentials. Use ${LocalDb.demoEmail} / ${LocalDb.demoPassword}',
          duration: const Duration(seconds: 6),
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      isLoading.value = true;
      _showLoadingDialog();

      var row = await LocalDb.instance.getUserByUid(LocalDb.demoUid);
      if (row == null) {
        row = model.User(
          name: LocalDb.demoName,
          email: LocalDb.demoEmail,
          uid: LocalDb.demoUid,
          profilePhoto: '',
        );
        await LocalDb.instance.upsertUser(row);
      }

      _user.value = AppUser(uid: row.uid, email: row.email);
      await _persistSession(row.uid);

      _closeLoadingDialog();
      isLoading.value = false;
      Get.offAll(() => const HomeScreen());
    } catch (e, st) {
      debugPrint('loginUser failed: $e\n$st');
      _closeLoadingDialog();
      isLoading.value = false;
      Get.snackbar(
        l10n?.errorLoggingIn ?? 'Error Logging in',
        e.toString(),
        duration: const Duration(seconds: 8),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void signOut() async {
    await _clearSession();
    _user.value = null;
    Get.offAll(() => LoginScreen());
  }
}
