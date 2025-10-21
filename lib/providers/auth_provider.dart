import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:ui_quiz/models/user_model.dart';
import 'package:ui_quiz/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? user;
  Map<String, dynamic>? userData;
  bool isLoading = false;
  String error = '';

  AuthProvider() {
    // initialize current user from FirebaseAuth
    final firebaseUser = _authService.currentUser();
    if (firebaseUser != null) {
      user = UserModel(uid: firebaseUser.uid, email: firebaseUser.email);
      _loadUserData();
    }

    // also listen to auth state changes for updates
    FirebaseAuth.instance.authStateChanges().listen((fbUser) {
      if (fbUser == null) {
        user = null;
        userData = null;
      } else {
        user = UserModel(uid: fbUser.uid, email: fbUser.email);
        _loadUserData();
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData() async {
    if (user?.email != null) {
      userData = await _authService.getUserData(user!.email!);
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final registered = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = registered;
      await _loadUserData();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final signedIn = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = signedIn;
      await _loadUserData();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final signedIn = await _authService.signInWithGoogle();
      user = signedIn;
      await _loadUserData();
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
      await _loadUserData();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInAnonymously() async {
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final signedIn = await _authService.signInAnonymously();
      user = signedIn;
      await _loadUserData();
    } catch (e) {
      error = e.toString();
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
      await _authService.googleSignOut();
      user = null;
      userData = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Delete the current user's account
  Future<void> deleteAccount() async {
    if (user == null) return;
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      await _authService.deleteAccount();
      user = null;
      userData = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSubscriptionPlan(String plan) async {
    if (user?.email == null) return;

    try {
      await _authService.updateUserSubscriptionPlan(user!.email!, plan);
      // Reload user data to reflect the new plan
      await _loadUserData();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
