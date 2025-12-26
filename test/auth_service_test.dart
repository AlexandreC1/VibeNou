import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:vibenou/services/auth_service.dart';

void main() {
  group('AuthService', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late MockGoogleSignIn mockGoogleSignIn;
    late AuthService authService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = FakeFirebaseFirestore();
      mockGoogleSignIn = MockGoogleSignIn();
      authService = AuthService(
        auth: mockAuth,
        firestore: mockFirestore,
        googleSignIn: mockGoogleSignIn,
      );
    });

    test('signIn creates user profile if missing (Self-healing)', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';

      // Create user in Auth but NOT in Firestore
      final user = await mockAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ensure Firestore is empty for this user
      final userDoc =
          await mockFirestore.collection('users').doc(user.user!.uid).get();
      expect(userDoc.exists, false);

      // Act
      final userModel = await authService.signIn(
        email: email,
        password: password,
      );

      // Assert
      expect(userModel, isNotNull);
      expect(userModel!.email, email);

      // Verify profile was created in Firestore
      final createdDoc =
          await mockFirestore.collection('users').doc(user.user!.uid).get();
      expect(createdDoc.exists, true);
      expect(createdDoc.data()!['email'], email);
      expect(createdDoc.data()!['bio'], 'Welcome to VibeNou!');
    });
  });
}
