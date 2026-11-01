/// Simple local session identity (replaces firebase_auth User).
class AppUser {
  final String uid;
  final String email;

  const AppUser({required this.uid, required this.email});
}
