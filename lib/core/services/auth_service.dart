import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madrasa_app/core/models/user_model.dart';
import 'package:madrasa_app/core/services/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final doc = await _firestore.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) return null;
      Logger.info('User signed in: ${cred.user!.uid}');
      return UserModel.fromMap(doc.data()!);
    } on FirebaseAuthException catch (e) {
      Logger.error('Sign in failed: ${e.message}');
      rethrow;
    }
  }

  Future<UserModel?> register(
      String name, String email, String password, String role) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = UserModel(
        id: cred.user!.uid,
        name: name,
        email: email,
        role: role,
      );
      await _firestore.collection('users').doc(cred.user!.uid).set(user.toMap());
      Logger.info('User registered: ${cred.user!.uid}');
      return user;
    } on FirebaseAuthException catch (e) {
      Logger.error('Registration failed: ${e.message}');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    Logger.info('User signed out');
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }
}
