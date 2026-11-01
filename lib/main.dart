import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/auth_controller.dart';
import 'package:tiktok_tutorial/controllers/locale_controller.dart';
import 'package:tiktok_tutorial/views/screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp().then((value) {
    Get.put(AuthController());
  });
  final localeController = Get.put(LocaleController());
  await localeController.loadSavedLocale();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeController = Get.find<LocaleController>();
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TikTok Clone',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: backgroundColor,
        ),
        locale: localeController.locale.value,
        fallbackLocale: const Locale('en'),
        supportedLocales: LocaleController.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: LoginScreen(),
      ),
    );
  }
}