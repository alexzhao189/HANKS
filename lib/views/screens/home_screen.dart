import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/home_nav_controller.dart';
import 'package:tiktok_tutorial/views/widgets/custom_icon.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeNavController _nav;
  List<Widget>? _pages;

  @override
  void initState() {
    super.initState();
    _nav = Get.isRegistered<HomeNavController>()
        ? Get.find<HomeNavController>()
        : Get.put(HomeNavController());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _pages ??= buildPages(context);
    return Obx(() {
      final pageIdx = _nav.pageIdx.value;
      return Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          onTap: (idx) => _nav.selectTab(idx),
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
        // Keep tab bodies alive so Home Obx sees feed updates after upload.
        body: IndexedStack(
          index: pageIdx,
          children: _pages!,
        ),
      );
    });
  }
}
