import 'dart:io';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/l10n/l10n_helper.dart';
import 'package:tiktok_tutorial/models/video.dart';
import 'package:tiktok_tutorial/services/local_db.dart';
import 'package:tiktok_tutorial/services/local_media.dart';
import 'package:tiktok_tutorial/controllers/video_controller.dart';
import 'package:video_compress/video_compress.dart';

class UploadVideoController extends GetxController {
  Future<File> _compressVideo(String videoPath) async {
    final compressedVideo = await VideoCompress.compressVideo(
      videoPath,
      quality: VideoQuality.MediumQuality,
    );
    return compressedVideo!.file!;
  }

  Future<File> _getThumbnail(String videoPath) async {
    return VideoCompress.getFileThumbnail(videoPath);
  }

  Future<void> uploadVideo(
      String songName, String caption, String videoPath) async {
    try {
      final uid = authController.user.uid;
      final userDoc = await LocalDb.instance.getUserByUid(uid);
      if (userDoc == null) {
        throw StateError('User not found in local DB');
      }

      final len = await LocalDb.instance.videoCount();
      final id = 'Video $len';

      File compressed;
      try {
        compressed = await _compressVideo(videoPath);
      } catch (_) {
        compressed = File(videoPath);
      }

      final videoLocalPath =
          await LocalMedia.instance.saveVideo(id, compressed);

      String thumbPath = '';
      try {
        final thumbFile = await _getThumbnail(videoPath);
        thumbPath = await LocalMedia.instance.saveThumbnail(id, thumbFile);
      } catch (_) {
        thumbPath = '';
      }

      final video = Video(
        username: userDoc.name,
        uid: uid,
        id: id,
        likes: [],
        commentCount: 0,
        shareCount: 0,
        songName: songName,
        caption: caption,
        videoUrl: videoLocalPath,
        profilePhoto: userDoc.profilePhoto,
        thumbnail: thumbPath,
      );

      await LocalDb.instance.insertVideo(video);

      if (Get.isRegistered<VideoController>()) {
        await Get.find<VideoController>().refreshVideos();
      }

      Get.back();
    } catch (e) {
      final l10n = tryL10n();
      Get.snackbar(
        l10n?.errorUploadingVideo ?? 'Error Uploading Video',
        e.toString(),
      );
    }
  }
}
