import 'dart:convert';

class Video {
  String username;
  String uid;
  String id;
  List likes;
  int commentCount;
  int shareCount;
  String songName;
  String caption;
  String videoUrl;
  String thumbnail;
  String profilePhoto;

  Video({
    required this.username,
    required this.uid,
    required this.id,
    required this.likes,
    required this.commentCount,
    required this.shareCount,
    required this.songName,
    required this.caption,
    required this.videoUrl,
    required this.profilePhoto,
    required this.thumbnail,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'uid': uid,
        'profilePhoto': profilePhoto,
        'id': id,
        'likes': likes,
        'commentCount': commentCount,
        'shareCount': shareCount,
        'songName': songName,
        'caption': caption,
        'videoUrl': videoUrl,
        'thumbnail': thumbnail,
      };

  static List _decodeLikes(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return List.from(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return List.from(decoded);
      } catch (_) {}
    }
    return [];
  }

  static Video fromMap(Map<String, dynamic> snapshot) {
    return Video(
      username: snapshot['username'] as String? ?? '',
      uid: snapshot['uid'] as String? ?? '',
      id: snapshot['id'] as String? ?? '',
      likes: _decodeLikes(snapshot['likes']),
      commentCount: (snapshot['commentCount'] as num?)?.toInt() ?? 0,
      shareCount: (snapshot['shareCount'] as num?)?.toInt() ?? 0,
      songName: snapshot['songName'] as String? ?? '',
      caption: snapshot['caption'] as String? ?? '',
      videoUrl: snapshot['videoUrl'] as String? ?? '',
      profilePhoto: snapshot['profilePhoto'] as String? ?? '',
      thumbnail: snapshot['thumbnail'] as String? ?? '',
    );
  }
}
