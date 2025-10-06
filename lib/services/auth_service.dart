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
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;

      if (user != null) {
        // Create user document in Firestore
        await _firestore.collection('users').doc(user.email).set({
          'email': user.email,
          'displayName': 'Kullanıcı',
          'createdAt': Timestamp.now(),
          'lastSignIn': Timestamp.now(),
        });
      }

      return UserModel(uid: user!.uid, email: user.email);
    } catch (e) {
      print('Error registering with email and password: $e');

      // Handle Firebase auth errors with user-friendly messages
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            throw Exception('Şifre çok zayıf. En az 6 karakter olmalıdır.');
          case 'email-already-in-use':
            throw Exception('Bu email adresi zaten kullanımda.');
          case 'invalid-email':
            throw Exception('Geçersiz email adresi.');
          case 'operation-not-allowed':
            throw Exception('Email/şifre ile kayıt devre dışı.');
          default:
            throw Exception('Kayıt hatası: ${e.message}');
        }
      }

      throw Exception('Kayıt hatası: $e');
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
        // Get existing user data from Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(user.email)
            .get();

        await _firestore.collection('users').doc(user.email).set({
          'email': user.email,
          'displayName':
              user.displayName ?? userDoc.data()?['displayName'] ?? 'Kullanıcı',
          'lastSignIn': Timestamp.now(),
        }, SetOptions(merge: true));
      }

      return UserModel(uid: user!.uid, email: user.email);
    } catch (e) {
      print('Error signing in with email and password: $e');

      // Handle Firebase auth errors with user-friendly messages
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw Exception(
              'Bu email adresi ile kayıtlı kullanıcı bulunamadı.',
            );
          case 'wrong-password':
            throw Exception('Hatalı şifre.');
          case 'invalid-email':
            throw Exception('Geçersiz email adresi.');
          case 'user-disabled':
            throw Exception('Bu kullanıcı hesabı devre dışı bırakılmış.');
          case 'too-many-requests':
            throw Exception(
              'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.',
            );
          default:
            throw Exception('Giriş hatası: ${e.message}');
        }
      }

      throw Exception('Giriş hatası: $e');
    }
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
      // androidPackageName: 'com.kk.ui_quiz',
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
        // Get existing user data from Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(user.email)
            .get();

        await _firestore.collection('users').doc(user.email).set({
          'email': user.email,
          'displayName':
              user.displayName ?? userDoc.data()?['displayName'] ?? 'Kullanıcı',
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
      // First check if Google Play Services are available
      await _googleSignIn.signOut(); // Clear any cached account

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception("Google ile giriş iptal edildi.");
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception("Google kimlik doğrulama bilgileri alınamadı.");
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // Get existing user data from Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(user.email)
            .get();

        await _firestore.collection('users').doc(user.email).set({
          'email': user.email,
          'displayName':
              user.displayName ?? userDoc.data()?['displayName'] ?? 'Kullanıcı',
          'photoURL': user.photoURL,
          'subscriptionPlan': userDoc.data()?['subscriptionPlan'] ?? 'free',
          'createdAt': userDoc.data()?['createdAt'] ?? Timestamp.now(),
          'lastSignIn': Timestamp.now(),
        }, SetOptions(merge: true));
      }

      return UserModel(uid: user!.uid, email: user.email);
    } catch (e) {
      print("Google ile giriş hatası: $e");

      // Provide more specific error messages
      if (e.toString().contains('ApiException: 10')) {
        throw Exception(
          "Google Play Services yapılandırma hatası. Lütfen uygulamayı yeniden başlatın.",
        );
      } else if (e.toString().contains('sign_in_failed')) {
        throw Exception("Google ile giriş başarısız. Lütfen tekrar deneyin.");
      } else if (e.toString().contains('network_error')) {
        throw Exception("İnternet bağlantınızı kontrol edin.");
      } else {
        throw Exception("Google ile giriş hatası: ${e.toString()}");
      }
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

  Future<Map<String, dynamic>?> getUserData(String email) async {
    try {
      final doc = await _firestore.collection('users').doc(email).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
}
