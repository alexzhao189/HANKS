class User {
  String name;
  String profilePhoto;
  String email;
  String uid;
  /// Plaintext for local MVP demo only — see FORGE_BUILD_NOTES.md.
  String password;

  User({
    required this.name,
    required this.email,
    required this.uid,
    required this.profilePhoto,
    this.password = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'profilePhoto': profilePhoto,
        'email': email,
        'uid': uid,
        'password': password,
      };

  static User fromMap(Map<String, dynamic> snapshot) {
    return User(
      email: snapshot['email'] as String? ?? '',
      profilePhoto: snapshot['profilePhoto'] as String? ?? '',
      uid: snapshot['uid'] as String? ?? '',
      name: snapshot['name'] as String? ?? '',
      password: snapshot['password'] as String? ?? '',
    );
  }
}
