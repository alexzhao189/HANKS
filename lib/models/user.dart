class User {
  String name;
  String profilePhoto;
  String email;
  String uid;

  User({
    required this.name,
    required this.email,
    required this.uid,
    required this.profilePhoto,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'profilePhoto': profilePhoto,
        'email': email,
        'uid': uid,
      };

  static User fromMap(Map<String, dynamic> snapshot) {
    return User(
      email: snapshot['email'] as String? ?? '',
      profilePhoto: snapshot['profilePhoto'] as String? ?? '',
      uid: snapshot['uid'] as String? ?? '',
      name: snapshot['name'] as String? ?? '',
    );
  }
}
