import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
    required String bio,
    required List<String> interests,
    String preferredLanguage = 'en',
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Create user profile in Firestore
        UserModel userModel = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          age: age,
          bio: bio,
          interests: interests,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          preferredLanguage: preferredLanguage,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());

        return userModel;
      }
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
    return null;
  }

  // Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Update last active
        await _firestore.collection('users').doc(user.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });

        // Get user data
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, user.uid);
      }
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
    return null;
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        throw Exception('Sign-in cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // Check if user document exists
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // Create new user profile for first-time Google sign-in
          UserModel userModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? 'User',
            age: 18, // Default age, user can update later
            bio: 'Hey there! I\'m using VibeNou.',
            interests: [],
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
            preferredLanguage: 'en',
            photoUrl: user.photoURL,
          );

          await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
          return userModel;
        } else {
          // Update last active for existing user
          await _firestore.collection('users').doc(user.uid).update({
            'lastActive': FieldValue.serverTimestamp(),
          });

          // Get and return existing user data
          return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, user.uid);
        }
      }
    } catch (e) {
      print('Google sign in error: $e');
      rethrow;
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
    } catch (e) {
      print('Get user data error: $e');
    }
    return null;
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      print('Update profile error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }
}
