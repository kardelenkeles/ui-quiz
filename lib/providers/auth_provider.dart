import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:ui_quiz/models/user_model.dart';
import 'package:ui_quiz/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? user;
  bool isLoading = false;
  String error = '';

  AuthProvider() {
    // initialize current user from FirebaseAuth
    final firebaseUser = _authService.currentUser();
    if (firebaseUser != null) {
      user = UserModel(uid: firebaseUser.uid, email: firebaseUser.email);
    }

    // also listen to auth state changes for updates
    FirebaseAuth.instance.authStateChanges().listen((fbUser) {
      if (fbUser == null) {
        user = null;
      } else {
        user = UserModel(uid: fbUser.uid, email: fbUser.email);
      }
      notifyListeners();
    });
  }

  Future<void> register(String email, String password) async {
    throw UnimplementedError(
      'Password registration removed. Use sendEmailLink.',
    );
  }

  Future<void> signIn(String email, String password) async {
    throw UnimplementedError(
      'Password sign-in removed. Use sendEmailLink and signInWithLink.',
    );
  }

  Future<void> signInWithGoogle() async {
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final signedIn = await _authService.signInWithGoogle();
      user = signedIn;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendEmailLink(String email) async {
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      await _authService.sendSignInLinkToEmail(email: email);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithLink(String email, String link) async {
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final signedIn = await _authService.signInWithEmailLink(
        email: email,
        emailLink: link,
      );
      user = signedIn;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
      user = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
