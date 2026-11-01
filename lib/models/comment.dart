import 'dart:convert';

class Comment {
  String username;
  String comment;
  DateTime datePublished;
  List likes;
  String profilePhoto;
  String uid;
  String id;

  Comment({
    required this.username,
    required this.comment,
    required this.datePublished,
    required this.likes,
    required this.profilePhoto,
    required this.uid,
    required this.id,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'comment': comment,
        'datePublished': datePublished.millisecondsSinceEpoch,
        'likes': likes,
        'profilePhoto': profilePhoto,
        'uid': uid,
        'id': id,
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

  static DateTime _parseDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    return DateTime.now();
  }

  static Comment fromMap(Map<String, dynamic> snapshot) {
    return Comment(
      username: snapshot['username'] as String? ?? '',
      comment: snapshot['comment'] as String? ?? '',
      datePublished: _parseDate(snapshot['datePublished']),
      likes: _decodeLikes(snapshot['likes']),
      profilePhoto: snapshot['profilePhoto'] as String? ?? '',
      uid: snapshot['uid'] as String? ?? '',
      id: snapshot['id'] as String? ?? '',
    );
  }
}
