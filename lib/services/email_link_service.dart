import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Receives Firebase email sign-in links on cold start and while the app is
/// running. Firebase requires the email address again when consuming the link,
/// so it is stored locally on the device that requested it.
class EmailLinkService {
  EmailLinkService._();

  static final EmailLinkService instance = EmailLinkService._();
  static const String _pendingEmailKey = 'pending_email_link_address';

  final AppLinks _appLinks = AppLinks();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<String> _handledLinks = <String>{};
  StreamSubscription<Uri>? _subscription;

  static Future<void> savePendingEmail(String email) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_pendingEmailKey, email.trim());
  }

  static Future<void> clearPendingEmail() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pendingEmailKey);
  }

  Future<void> initialize() async {
    _subscription ??= _appLinks.uriLinkStream.listen(
      _handleLink,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Email app-link stream failed: $error');
      },
    );

    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      await _handleLink(initialLink);
    }
  }

  Future<void> _handleLink(Uri uri) async {
    final emailLink = uri.toString();
    if (_handledLinks.contains(emailLink) ||
        !_auth.isSignInWithEmailLink(emailLink)) {
      return;
    }

    _handledLinks.add(emailLink);
    final preferences = await SharedPreferences.getInstance();
    final email = preferences.getString(_pendingEmailKey);
    if (email == null || email.isEmpty) {
      debugPrint(
        'Email sign-in link opened without a pending email on this device.',
      );
      return;
    }

    try {
      final credential = await _auth.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
      final user = credential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? 'User',
          'lastSignIn': Timestamp.now(),
          if (credential.additionalUserInfo?.isNewUser ?? false)
            'createdAt': Timestamp.now(),
        }, SetOptions(merge: true));
      }
      await preferences.remove(_pendingEmailKey);
    } on FirebaseAuthException catch (error) {
      _handledLinks.remove(emailLink);
      debugPrint('Email link sign-in failed (${error.code}): ${error.message}');
    }
  }
}
