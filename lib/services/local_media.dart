import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Saves profile photos / videos / thumbnails under app documents.
class LocalMedia {
  LocalMedia._();
  static final LocalMedia instance = LocalMedia._();

  Future<Directory> _root() async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(docs.path, 'hanks_media'));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  Future<String> saveProfilePhoto(String uid, File source) async {
    final root = await _root();
    final dir = Directory(p.join(root.path, 'profilePics'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final dest = File(p.join(dir.path, '$uid.jpg'));
    await source.copy(dest.path);
    return dest.path;
  }

  Future<String> saveVideo(String id, File source) async {
    final root = await _root();
    final dir = Directory(p.join(root.path, 'videos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final ext = p.extension(source.path);
    final dest = File(p.join(dir.path, '$id${ext.isEmpty ? '.mp4' : ext}'));
    await source.copy(dest.path);
    return dest.path;
  }

  Future<String> saveThumbnail(String id, File source) async {
    final root = await _root();
    final dir = Directory(p.join(root.path, 'thumbnails'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final dest = File(p.join(dir.path, '$id.jpg'));
    await source.copy(dest.path);
    return dest.path;
  }
}
