import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  // SIGN UP
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      print("REPO: Starting Sign Up..."); // Debug log

      // 1. Create User in Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("REPO: Auth User Created: ${userCredential.user?.uid}");

      // 2. Save to Firestore
      if (userCredential.user != null) {
        final defaultName = email.split('@')[0];
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          name: defaultName,
        );

        await _firestore
            .collection('users')
            .doc(newUser.uid)
            .set(newUser.toMap());
        print("REPO: Firestore Document Saved.");

        // 3. Sign Out immediately so they are forced to Login
        await _auth.signOut();
        print("REPO: Signed Out. Ready for Login.");
      }
    } on FirebaseAuthException catch (e) {
      // Pass the specific Firebase error to the UI
      print("REPO ERROR (Firebase): ${e.message}");
      throw Exception(e.message);
    } catch (e) {
      // Pass the real system error to the UI
      print("REPO ERROR (System): $e");
      throw Exception(e.toString());
    }
  }

  // LOGIN
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}

// ---------------- PROVIDERS ----------------

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  return AuthRepository(auth, firestore);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});