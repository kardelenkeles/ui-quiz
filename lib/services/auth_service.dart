import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ui_quiz/models/user_model.dart';
import 'package:ui_quiz/config/app_config.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    forceCodeForRefreshToken: true,
  );

  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError(
      'Password registration removed. Use email link sign-in.',
    );
  }

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError(
      'Password sign-in was removed. Use email link sign-in.',
    );
  }

  /// Send a sign-in link to the provided email. The user will receive an email
  /// containing a link which can be used to sign in. The link must be opened
  /// in the same device/app (handleCodeInApp: true).
  Future<void> sendSignInLinkToEmail({required String email}) async {
    final ActionCodeSettings actionCodeSettings = ActionCodeSettings(
      url: '${AppConfig.backendUrl}/finishSignIn',
      handleCodeInApp: true,
      // If you have Android/iOS app details, add them here so link opens in app.
      androidInstallApp: true,
      androidMinimumVersion: '21',
      // androidPackageName: 'com.example.ui_quiz',
      // iOS bundle ID can be added similarly
    );

    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
    } catch (e) {
      print('Error sending sign-in link: $e');
      rethrow;
    }
  }

  /// Complete sign-in using the email link the user received.
  Future<UserModel> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
      final User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.email).set({
          'email': user.email,
          'lastSignIn': Timestamp.now(),
        }, SetOptions(merge: true));
      }

      return UserModel(uid: user!.uid, email: user.email);
    } catch (e) {
      print('Error signing in with email link: $e');
      throw Exception(e);
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception("Google ile giriş iptal edildi.");
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.email).set({
          'email': user.email,
          'createdAt': Timestamp.now(),
        });
      }

      return UserModel(uid: user!.uid, email: user.email);
    } catch (e) {
      print("Google ile giriş hatası: $e");
      throw Exception(e);
    }
  }

  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> googleSignOut() async {
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } catch (e) {
      print("Google oturumu kapatılırken hata oluştu: $e");
    }
  }

  User? currentUser() {
    return _auth.currentUser;
  }
}
