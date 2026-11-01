import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiktok_tutorial/controllers/auth_controller.dart';
import 'package:tiktok_tutorial/views/screens/add_video_screen.dart';
import 'package:tiktok_tutorial/views/screens/profile_screen.dart';
import 'package:tiktok_tutorial/views/screens/search_screen.dart';
import 'package:tiktok_tutorial/views/screens/video_screen.dart';

List<Widget> buildPages(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return [
    VideoScreen(),
    SearchScreen(),
    const AddVideoScreen(),
    Center(child: Text(l10n.messagesScreen)),
    ProfileScreen(uid: authController.user.uid),
  ];
}

// COLORS
const backgroundColor = Colors.black;
var buttonColor = Colors.red[400];
const borderColor = Colors.grey;

// CONTROLLER
var authController = AuthController.instance;
