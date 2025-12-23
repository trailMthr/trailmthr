import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User> ensureSignedIn() async {
    final current = _auth.currentUser;
    if (current != null) return current;

    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  String? get currentUserId => _auth.currentUser?.uid;
}
