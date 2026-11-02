import 'package:get/get.dart';
import 'package:tiktok_tutorial/controllers/video_controller.dart';

/// Bottom-tab index for [HomeScreen]. Used so upload can jump back to Home
/// and so tab changes can refresh the feed.
class HomeNavController extends GetxController {
  final RxInt pageIdx = 0.obs;

  void selectTab(int idx) {
    pageIdx.value = idx;
    if (idx == 0) {
      refreshHomeFeed();
    }
  }

  void goHomeAndRefresh() {
    pageIdx.value = 0;
    refreshHomeFeed();
  }

  void refreshHomeFeed() {
    if (Get.isRegistered<VideoController>()) {
      Get.find<VideoController>().refreshVideos();
    }
  }
}
