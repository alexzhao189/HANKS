import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

/// Resolve localizations from GetX context (for controllers / snackbars).
AppLocalizations? tryL10n([BuildContext? context]) {
  final ctx = context ?? Get.context;
  if (ctx == null) return null;
  return AppLocalizations.of(ctx);
}