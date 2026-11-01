import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/services/local_db.dart';

class ProfileController extends GetxController {
  final Rx<Map<String, dynamic>> _user = Rx<Map<String, dynamic>>({});
  Map<String, dynamic> get user => _user.value;

  final Rx<String> _uid = ''.obs;

  void updateUserId(String uid) {
    _uid.value = uid;
    getUserData();
  }

  Future<void> getUserData() async {
    final myVideos = await LocalDb.instance.getVideosByUid(_uid.value);
    final thumbnails =
        myVideos.map((v) => v.thumbnail).where((t) => t.isNotEmpty).toList();

    final userDoc = await LocalDb.instance.getUserByUid(_uid.value);
    if (userDoc == null) {
      _user.value = {};
      update();
      return;
    }

    int likes = 0;
    for (final item in myVideos) {
      likes += item.likes.length;
    }

    final followers = await LocalDb.instance.followerCount(_uid.value);
    final following = await LocalDb.instance.followingCount(_uid.value);
    final isFollowing = await LocalDb.instance
        .isFollowing(_uid.value, authController.user.uid);

    _user.value = {
      'followers': followers.toString(),
      'following': following.toString(),
      'isFollowing': isFollowing,
      'likes': likes.toString(),
      'profilePhoto': userDoc.profilePhoto,
      'name': userDoc.name,
      'thumbnails': thumbnails,
    };
    update();
  }

  Future<void> followUser() async {
    final me = authController.user.uid;
    final following =
        await LocalDb.instance.isFollowing(_uid.value, me);
    if (!following) {
      await LocalDb.instance.follow(_uid.value, me);
      _user.value.update(
        'followers',
        (value) => (int.parse(value) + 1).toString(),
      );
    } else {
      await LocalDb.instance.unfollow(_uid.value, me);
      _user.value.update(
        'followers',
        (value) => (int.parse(value) - 1).toString(),
      );
    }
    _user.value.update('isFollowing', (value) => !value);
    update();
  }
}
