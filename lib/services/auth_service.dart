import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ui_quiz/models/user_model.dart';
import 'package:ui_quiz/config/app_config.dart';
import 'package:ui_quiz/core/app_logger.dart';
import 'package:ui_quiz/services/email_link_service.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(scopes: ['email'], forceCodeForRefreshToken: true);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': 'User',
          'createdAt': Timestamp.now(),
          'lastSignIn': Timestamp.now(),
        });
      }

      return UserModel(uid: user!.uid, email: user.email);
    } catch (e) {
      AppLogger.debug('Error registering with email and password: $e');

      // Handle Firebase auth errors with user-friendly messages
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            throw Exception(
              'Password is too weak. Must be at least 6 characters.',
            );
          case 'email-already-in-use':
            throw Exception('This email address is already in use.');
          case 'invalid-email':
            throw Exception('Invalid email address.');
          case 'operation-not-allowed':
            throw Exception('Email/password registration is disabled.');
          default:
            throw Exception('Registration error: ${e.message}');
        }
      }

      throw Exception('Registration error: $e');
    }
  }

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;

      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName':
              user.displayName ?? userDoc.data()?['displayName'] ?? 'Kullanıcı',
          'lastSignIn': Timestamp.now(),
        }, SetOptions(merge: true));
      }

      return UserModel(uid: user!.uid, email: user.email);
    } catch (e) {
      AppLogger.debug('Error signing in with email and password: $e');

      // Handle Firebase auth errors with user-friendly messages
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw Exception('No user found with this email address.');
          case 'wrong-password':
            throw Exception('Incorrect password.');
          case 'invalid-email':
            throw Exception('Invalid email address.');
          case 'user-disabled':
            throw Exception('This user account has been disabled.');
          case 'too-many-requests':
            throw Exception('Too many attempts. Please try again later.');
          default:
            throw Exception('Sign in error: ${e.message}');
        }
      }

      throw Exception('Sign in error: $e');
    }
  }

  /// Send a sign-in link to the provided email. The user will receive an email
  /// containing a link which can be used to sign in. The link must be opened
  /// in the same device/app (handleCodeInApp: true).
  Future<void> sendSignInLinkToEmail({required String email}) async {
    final ActionCodeSettings actionCodeSettings = ActionCodeSettings(
      url: AppConfig.authContinueUrl,
      handleCodeInApp: true,
      androidPackageName: AppConfig.androidPackageName,
      androidInstallApp: true,
      androidMinimumVersion: '21',
      iOSBundleId: AppConfig.iosBundleId,
      linkDomain: AppConfig.authLinkDomain.isEmpty
          ? null
          : AppConfig.authLinkDomain,
    );

    try {
      await EmailLinkService.savePendingEmail(email);
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
    } catch (e) {
      await EmailLinkService.clearPendingEmail();
      AppLogger.debug('Error sending sign-in link: $e');
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
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName':
              user.displayName ?? userDoc.data()?['displayName'] ?? 'User',
          'lastSignIn': Timestamp.now(),
        }, SetOptions(merge: true));
      }

      return UserModel(uid: user!.uid, email: user.email);
    } catch (e) {
      AppLogger.debug('Error signing in with email link: $e');
      throw Exception(e);
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      // First check if Google Play Services are available
      await _googleSignIn.signOut(); // Clear any cached account

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception("Google sign in was cancelled.");
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception(
          "Could not retrieve Google authentication credentials.",
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // Use UID as the Firestore document id to comply with common security rules
        // and avoid permission errors when request.auth.uid is enforced by rules.
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName':
              user.displayName ?? userDoc.data()?['displayName'] ?? 'User',
          'photoURL': user.photoURL,
          'createdAt': userDoc.data()?['createdAt'] ?? Timestamp.now(),
          'lastSignIn': Timestamp.now(),
        }, SetOptions(merge: true));
      }

      return UserModel(uid: user!.uid, email: user.email);
    } catch (e) {
      AppLogger.debug("Google sign in error: $e");

      // Provide more specific error messages
      if (e.toString().contains('ApiException: 10')) {
        throw Exception(
          "Google Play Services configuration error. Please restart the app.",
        );
      } else if (e.toString().contains('sign_in_failed')) {
        throw Exception("Google sign in failed. Please try again.");
      } else if (e.toString().contains('network_error')) {
        throw Exception("Please check your internet connection.");
      } else {
        throw Exception("Google sign in error: ${e.toString()}");
      }
    }
  }

  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      AppLogger.debug(e.toString());
      return;
    }
  }

  /// Reauthenticate the current user using Google sign-in.
  /// This is useful for sensitive operations that require a recent login.
  Future<void> reauthenticateWithGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Start a fresh Google sign-in to obtain a new credential
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign-in cancelled');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Reauthenticate the Firebase user with the fresh credential
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      AppLogger.debug('Error reauthenticating with Google: $e');
      rethrow;
    }
  }

  Future<void> googleSignOut() async {
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } catch (e) {
      AppLogger.debug("Error signing out of Google: $e");
    }
  }

  /// Send password reset email to the user
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      AppLogger.debug('Error sending password reset email: $e');

      // Handle Firebase auth errors with user-friendly messages
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw Exception('No user found with this email address.');
          case 'invalid-email':
            throw Exception('Invalid email address.');
          case 'too-many-requests':
            throw Exception('Too many requests. Please try again later.');
          default:
            throw Exception('Error sending reset email: ${e.message}');
        }
      }

      throw Exception('Error sending reset email: $e');
    }
  }

  Future<UserModel> signInAnonymously() async {
    try {
      final UserCredential result = await _auth.signInAnonymously();
      final User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'displayName': 'Guest User',
          'createdAt': Timestamp.now(),
          'lastSignIn': Timestamp.now(),
        });
      }

      return UserModel(uid: user!.uid, email: null);
    } catch (e) {
      AppLogger.debug('Error signing in anonymously: $e');
      throw Exception('Anonymous sign in failed.');
    }
  }

  /// Delete the currently signed-in user (also removes Firestore doc)
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not found.');

      // Delete user document from Firestore if possible
      try {
        await _firestore.collection('users').doc(user.uid).delete();
      } catch (e) {
        // ignore deletion errors for now, still attempt to delete auth user
        AppLogger.debug('Could not delete user document: $e');
      }

      // Delete Firebase Auth user
      await user.delete();
    } catch (e) {
      AppLogger.debug('Error deleting account: $e');
      // Do not surface a special "recent login required" warning here.
      // Return a generic error so the UI does not show the special re-auth prompt.
      throw Exception('Error deleting account: $e');
    }
  }

  User? currentUser() {
    return _auth.currentUser;
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      AppLogger.debug('Error getting user data: $e');
      return null;
    }
  }
}
