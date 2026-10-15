import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_quiz/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('registers the user and stores a UID-owned profile', () async {
      final auth = MockFirebaseAuth();
      final firestore = FakeFirebaseFirestore();
      final service = AuthService(auth: auth, firestore: firestore);

      final user = await service.registerWithEmailAndPassword(
        email: 'student@example.com',
        password: 'strong-password',
      );

      expect(user.email, 'student@example.com');
      final profile = await firestore.collection('users').doc(user.uid).get();
      expect(profile.exists, isTrue);
      expect(profile.data()?['uid'], user.uid);
      expect(profile.data()?['email'], 'student@example.com');
      expect(profile.data()?.containsKey('password'), isFalse);
    });

    test(
      'signs in and updates lastSignIn without erasing displayName',
      () async {
        final mockUser = MockUser(
          uid: 'user-1',
          email: 'student@example.com',
          displayName: 'Student',
        );
        final auth = MockFirebaseAuth(mockUser: mockUser);
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('users').doc('user-1').set({
          'uid': 'user-1',
          'email': 'student@example.com',
          'displayName': 'Existing Name',
        });
        final service = AuthService(auth: auth, firestore: firestore);

        await service.signInWithEmailAndPassword(
          email: 'student@example.com',
          password: 'strong-password',
        );

        final profile = await firestore.collection('users').doc('user-1').get();
        expect(profile.data()?['displayName'], 'Student');
        expect(profile.data()?['lastSignIn'], isNotNull);
      },
    );
  });
}
