import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Register user with email and password ---
  Future<User?> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException {
      // THE FIX:
      // Rethrow the exception so the RegisterScreen's `catch` block can
      // execute and show a specific error message to the user.
      rethrow;
    }
  }

  // --- Login user with email and password ---
  Future<User?> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException {
      // THE FIX:
      // By rethrowing the exception, the LoginScreen's `try` block will fail,
      // its `catch` block will execute, and the user will see the error
      // message instead of being incorrectly navigated to the home screen.
      rethrow;
    }
  }

  // --- Get current user ---
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // --- Sign out user ---
  // Renamed from 'logout' to 'signOut' for consistency with Firebase
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // It's good practice to handle potential errors, even for sign-out.
      print('Error during sign out: $e');
    }
  }
}
