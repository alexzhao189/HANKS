import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/controllers/locale_controller.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool compact;
  const LanguageSwitcher({Key? key, this.compact = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeController = Get.find<LocaleController>();

    return Obx(() {
      final current = localeController.locale.value.languageCode;
      return PopupMenuButton<String>(
        tooltip: l10n.language,
        onSelected: (code) {
          localeController.setLocale(Locale(code));
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'en',
            child: Text(
              l10n.languageEnglish,
              style: TextStyle(
                fontWeight: current == 'en' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          PopupMenuItem(
            value: 'zh',
            child: Text(
              l10n.languageChinese,
              style: TextStyle(
                fontWeight: current == 'zh' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          PopupMenuItem(
            value: 'ja',
            child: Text(
              l10n.languageJapanese,
              style: TextStyle(
                fontWeight: current == 'ja' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
        child: compact
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.language, color: Colors.white),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      l10n.language,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
      );
    });
  }
}