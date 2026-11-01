import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/views/widgets/custom_icon.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int pageIdx = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = buildPages(context);
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        onTap: (idx) {
          setState(() {
            pageIdx = idx;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: backgroundColor,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.white,
        currentIndex: pageIdx,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home, size: 30),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search, size: 30),
            label: l10n.search,
          ),
          const BottomNavigationBarItem(
            icon: CustomIcon(),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.message, size: 30),
            label: l10n.messages,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person, size: 30),
            label: l10n.profile,
          ),
        ],
      ),
      body: pages[pageIdx],
    );
  }
}