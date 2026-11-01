import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:tiktok_tutorial/models/comment.dart';
import 'package:tiktok_tutorial/models/user.dart';
import 'package:tiktok_tutorial/models/video.dart';

/// Local SQLite store replacing Firestore for the offline MVP.
class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  /// Legacy seed email from v1 installs (password filled on migration).
  static const legacyDemoEmail = 'hanks@gmail.com';
  static const legacyDemoPassword = '123';
  static const legacyDemoUid = 'local-hanks';
  static const legacyDemoName = 'Hanks';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'hanks_local.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE users (
  uid TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  profilePhoto TEXT NOT NULL DEFAULT '',
  password TEXT NOT NULL DEFAULT ''
)''');
        await db.execute('''
CREATE TABLE videos (
  id TEXT PRIMARY KEY,
  username TEXT NOT NULL,
  uid TEXT NOT NULL,
  likes TEXT NOT NULL DEFAULT '[]',
  commentCount INTEGER NOT NULL DEFAULT 0,
  shareCount INTEGER NOT NULL DEFAULT 0,
  songName TEXT NOT NULL DEFAULT '',
  caption TEXT NOT NULL DEFAULT '',
  videoUrl TEXT NOT NULL,
  thumbnail TEXT NOT NULL DEFAULT '',
  profilePhoto TEXT NOT NULL DEFAULT ''
)''');
        await db.execute('''
CREATE TABLE comments (
  id TEXT PRIMARY KEY,
  videoId TEXT NOT NULL,
  username TEXT NOT NULL,
  comment TEXT NOT NULL,
  datePublished INTEGER NOT NULL,
  likes TEXT NOT NULL DEFAULT '[]',
  profilePhoto TEXT NOT NULL DEFAULT '',
  uid TEXT NOT NULL
)''');
        await db.execute('''
CREATE TABLE followers (
  userUid TEXT NOT NULL,
  followerUid TEXT NOT NULL,
  PRIMARY KEY (userUid, followerUid)
)''');
        // Fresh installs: no seeded account — register via UI.
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE users ADD COLUMN password TEXT NOT NULL DEFAULT ''",
          );
          // Preserve prior fake-login demo row so reinstall is not required.
          await db.update(
            'users',
            {'password': legacyDemoPassword},
            where: 'email = ? OR uid = ?',
            whereArgs: [legacyDemoEmail, legacyDemoUid],
          );
        }
      },
    );
  }

  Future<User?> getUserByUid(String uid) async {
    final db = await database;
    final rows = await db.query('users', where: 'uid = ?', whereArgs: [uid]);
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  /// Insert a new user. Throws [DuplicateEmailException] if email exists.
  Future<void> insertUser(User user) async {
    final db = await database;
    final existing = await getUserByEmail(user.email);
    if (existing != null) {
      throw DuplicateEmailException(user.email);
    }
    await db.insert(
      'users',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> upsertUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateUserProfilePhoto(String uid, String path) async {
    final db = await database;
    await db.update(
      'users',
      {'profilePhoto': path},
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  Future<List<User>> searchUsersByName(String typed) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'name LIKE ?',
      whereArgs: ['%${typed.trim()}%'],
    );
    return rows.map(User.fromMap).toList();
  }

  Future<List<Video>> getAllVideos() async {
    final db = await database;
    final rows = await db.query('videos', orderBy: 'rowid DESC');
    return rows.map(Video.fromMap).toList();
  }

  Future<int> videoCount() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM videos');
    return (r.first['c'] as int?) ?? 0;
  }

  Future<void> insertVideo(Video video) async {
    final db = await database;
    await db.insert(
      'videos',
      {
        ...video.toJson(),
        'likes': jsonEncode(video.likes),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Video?> getVideo(String id) async {
    final db = await database;
    final rows = await db.query('videos', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Video.fromMap(rows.first);
  }

  Future<void> updateVideoLikes(String id, List likes) async {
    final db = await database;
    await db.update(
      'videos',
      {'likes': jsonEncode(likes)},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> bumpCommentCount(String videoId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE videos SET commentCount = commentCount + 1 WHERE id = ?',
      [videoId],
    );
  }

  Future<List<Video>> getVideosByUid(String uid) async {
    final db = await database;
    final rows =
        await db.query('videos', where: 'uid = ?', whereArgs: [uid]);
    return rows.map(Video.fromMap).toList();
  }

  Future<List<Comment>> getComments(String videoId) async {
    final db = await database;
    final rows = await db.query(
      'comments',
      where: 'videoId = ?',
      whereArgs: [videoId],
      orderBy: 'datePublished ASC',
    );
    return rows.map(Comment.fromMap).toList();
  }

  Future<int> commentCountForVideo(String videoId) async {
    final db = await database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM comments WHERE videoId = ?',
      [videoId],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  Future<void> insertComment(String videoId, Comment comment) async {
    final db = await database;
    await db.insert(
      'comments',
      {
        ...comment.toJson(),
        'videoId': videoId,
        'likes': jsonEncode(comment.likes),
        'datePublished': comment.datePublished is DateTime
            ? (comment.datePublished as DateTime).millisecondsSinceEpoch
            : comment.datePublished,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Comment?> getComment(String videoId, String id) async {
    final db = await database;
    final rows = await db.query(
      'comments',
      where: 'videoId = ? AND id = ?',
      whereArgs: [videoId, id],
    );
    if (rows.isEmpty) return null;
    return Comment.fromMap(rows.first);
  }

  Future<void> updateCommentLikes(
      String videoId, String id, List likes) async {
    final db = await database;
    await db.update(
      'comments',
      {'likes': jsonEncode(likes)},
      where: 'videoId = ? AND id = ?',
      whereArgs: [videoId, id],
    );
  }

  Future<int> followerCount(String uid) async {
    final db = await database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM followers WHERE userUid = ?',
      [uid],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  Future<int> followingCount(String uid) async {
    final db = await database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM followers WHERE followerUid = ?',
      [uid],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  Future<bool> isFollowing(String userUid, String followerUid) async {
    final db = await database;
    final rows = await db.query(
      'followers',
      where: 'userUid = ? AND followerUid = ?',
      whereArgs: [userUid, followerUid],
    );
    return rows.isNotEmpty;
  }

  Future<void> follow(String userUid, String followerUid) async {
    final db = await database;
    await db.insert(
      'followers',
      {'userUid': userUid, 'followerUid': followerUid},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> unfollow(String userUid, String followerUid) async {
    final db = await database;
    await db.delete(
      'followers',
      where: 'userUid = ? AND followerUid = ?',
      whereArgs: [userUid, followerUid],
    );
  }
}

class DuplicateEmailException implements Exception {
  final String email;
  DuplicateEmailException(this.email);

  @override
  String toString() => 'Email already registered: $email';
}
