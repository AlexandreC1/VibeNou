import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Emergency function to create missing Firestore profile for authenticated users
/// This fixes the "profile data not found" issue
Future<void> fixMissingUserProfile({
  required String uid,
  required String email,
  String name = 'User',
  int age = 25,
  String bio = 'Hello from Haiti! 🇭🇹',
  List<String> interests = const ['Music', 'Travel'],
  String? gender, // 'male' or 'female'
}) async {
  final firestore = FirebaseFirestore.instance;

  try {
    // Check if profile already exists
    final docSnapshot = await firestore.collection('users').doc(uid).get();

    if (docSnapshot.exists) {
      print('✅ Profile already exists for $uid');
      return;
    }

    // Create missing profile
    final userModel = UserModel(
      uid: uid,
      email: email,
      name: name,
      age: age,
      bio: bio,
      interests: interests,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
      preferredLanguage: 'en',
      gender: gender,
    );

    await firestore.collection('users').doc(uid).set(userModel.toMap());

    print('✅ Successfully created profile for $uid');
    print('   Name: $name');
    print('   Gender: ${gender ?? "not specified"}');
    print('   Age: $age');
  } catch (e) {
    print('❌ Error fixing user profile: $e');
    rethrow;
  }
}

/// Call this from your app to fix the current logged-in user
///
/// **IMPORTANT**: Change the gender parameter below:
/// - 'male' for BLUE theme (recommended for Haiti male users)
/// - 'female' for PINK theme
Future<void> fixCurrentUserProfile() async {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    print('❌ No user is currently logged in');
    return;
  }

  // ⚙️ CUSTOMIZE YOUR PROFILE HERE:
  await fixMissingUserProfile(
    uid: currentUser.uid,
    email: currentUser.email ?? 'user@example.com',
    name: currentUser.displayName ?? 'Jean',  // ← Change your name here
    age: 25,  // ← Change your age here
    bio: 'Hello from Haiti! 🇭🇹 Looking to connect',  // ← Change your bio
    interests: ['Music', 'Dance', 'Food', 'Travel'],  // ← Add your interests
    gender: 'male',  // ← 'male' = BLUE theme, 'female' = PINK theme
  );
}
