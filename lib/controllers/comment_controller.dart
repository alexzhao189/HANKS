import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/models/comment.dart';
import 'package:tiktok_tutorial/services/local_db.dart';
import 'package:tiktok_tutorial/controllers/video_controller.dart';

class CommentController extends GetxController {
  final Rx<List<Comment>> _comments = Rx<List<Comment>>([]);
  List<Comment> get comments => _comments.value;

  String _postId = '';

  void updatePostId(String id) {
    _postId = id;
    getComment();
  }

  Future<void> getComment() async {
    _comments.value = await LocalDb.instance.getComments(_postId);
  }

  Future<void> postComment(String commentText) async {
    try {
      if (commentText.isEmpty) return;
      final userDoc =
          await LocalDb.instance.getUserByUid(authController.user.uid);
      if (userDoc == null) return;

      final len = await LocalDb.instance.commentCountForVideo(_postId);
      final comment = Comment(
        username: userDoc.name,
        comment: commentText.trim(),
        datePublished: DateTime.now(),
        likes: [],
        profilePhoto: userDoc.profilePhoto,
        uid: authController.user.uid,
        id: 'Comment $len',
      );
      await LocalDb.instance.insertComment(_postId, comment);
      await LocalDb.instance.bumpCommentCount(_postId);
      await getComment();
      if (Get.isRegistered<VideoController>()) {
        await Get.find<VideoController>().refreshVideos();
      }
    } catch (e) {
      Get.snackbar('Error While Commenting', e.toString());
    }
  }

  Future<void> likeComment(String id) async {
    final uid = authController.user.uid;
    final doc = await LocalDb.instance.getComment(_postId, id);
    if (doc == null) return;
    final likes = List.from(doc.likes);
    if (likes.contains(uid)) {
      likes.remove(uid);
    } else {
      likes.add(uid);
    }
    await LocalDb.instance.updateCommentLikes(_postId, id, likes);
    await getComment();
  }
}
