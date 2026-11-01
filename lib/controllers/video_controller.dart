import 'package:get/get.dart';
import 'package:tiktok_tutorial/models/video.dart';
import 'package:tiktok_tutorial/services/local_db.dart';
import 'package:tiktok_tutorial/constants.dart';

class VideoController extends GetxController {
  final Rx<List<Video>> _videoList = Rx<List<Video>>([]);

  List<Video> get videoList => _videoList.value;

  @override
  void onInit() {
    super.onInit();
    refreshVideos();
  }

  Future<void> refreshVideos() async {
    _videoList.value = await LocalDb.instance.getAllVideos();
  }

  Future<void> likeVideo(String id) async {
    final video = await LocalDb.instance.getVideo(id);
    if (video == null) return;
    final uid = authController.user.uid;
    final likes = List.from(video.likes);
    if (likes.contains(uid)) {
      likes.remove(uid);
    } else {
      likes.add(uid);
    }
    await LocalDb.instance.updateVideoLikes(id, likes);
    await refreshVideos();
  }
}
