import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends GetxController {
  static const String _prefsKey = 'app_locale';

  final Rx<Locale> locale = const Locale('en').obs;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('zh'),
    Locale('ja'),
  ];

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey) ?? 'en';
    final matched = supportedLocales.firstWhere(
      (l) => l.languageCode == code,
      orElse: () => const Locale('en'),
    );
    locale.value = matched;
    Get.updateLocale(matched);
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!supportedLocales.any((l) => l.languageCode == newLocale.languageCode)) {
      return;
    }
    locale.value = newLocale;
    Get.updateLocale(newLocale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newLocale.languageCode);
  }
}