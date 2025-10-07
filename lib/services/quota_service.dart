import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'device_service.dart';

class QuotaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int FREE_DAILY_LIMIT = 30;
  static const int ANONYMOUS_DAILY_LIMIT = 30;

  /// Kalıcı cihaz kimliğini al (app silinse bile aynı kalır)
  Future<String> _getDeviceId() async {
    return await DeviceService.instance.getDeviceId();
  }

  /// Bugünün tarihini string formatında al
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Kullanıcının quiz oluşturup oluşturamayacağını kontrol et
  Future<bool> canCreateQuiz() async {
    final user = _auth.currentUser;

    if (user != null) {
      // Giriş yapmış kullanıcı için kontrol
      return await _canCreateQuizForUser(user.email!);
    } else {
      // Anonymous kullanıcı için kontrol
      return await _canCreateQuizForAnonymous();
    }
  }

  /// Giriş yapmış kullanıcı için quiz oluşturma kontrolü
  Future<bool> _canCreateQuizForUser(String email) async {
    try {
      // Premium kontrolü
      final userDoc = await _firestore.collection('users').doc(email).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final plan = userData['plan'] as String? ?? 'free';

        if (plan == 'premium') {
          // Premium kullanıcı - token kontrolü yapılacak
          return await _checkPremiumTokenLimit(email);
        }
      }

      // Free kullanıcı için günlük limit kontrolü
      final today = _getTodayString();
      final usageDocId = '${today}_$email';

      final usageDoc = await _firestore
          .collection('daily_usage')
          .doc(usageDocId)
          .get();

      if (!usageDoc.exists) {
        return true; // İlk kullanım
      }

      final currentCount = usageDoc.data()!['quizCount'] as int? ?? 0;
      return currentCount < FREE_DAILY_LIMIT;
    } catch (e) {
      print('Error checking user quota: $e');
      return false;
    }
  }

  /// Anonymous kullanıcı için quiz oluşturma kontrolü
  Future<bool> _canCreateQuizForAnonymous() async {
    try {
      final deviceId = await _getDeviceId();
      final today = _getTodayString();
      final usageDocId = '${deviceId}_$today';

      final usageDoc = await _firestore
          .collection('anonymous_usage')
          .doc(usageDocId)
          .get();

      if (!usageDoc.exists) {
        return true; // İlk kullanım
      }

      final currentCount = usageDoc.data()!['quizCount'] as int? ?? 0;
      return currentCount < ANONYMOUS_DAILY_LIMIT;
    } catch (e) {
      print('Error checking anonymous quota: $e');
      // Hata durumunda cömert ol, izin ver
      return true;
    }
  }

  /// Premium kullanıcı için token limit kontrolü
  Future<bool> _checkPremiumTokenLimit(String email) async {
    try {
      // App settings'den monthly token limit al
      final settingsDoc = await _firestore
          .collection('app_settings')
          .doc('limits')
          .get();

      int monthlyLimit = 100000; // Default değer
      if (settingsDoc.exists) {
        monthlyLimit =
            settingsDoc.data()!['premiumMonthlyTokenLimit'] as int? ?? 100000;
      }

      // Kullanıcının bu ayki token kullanımını kontrol et
      final userDoc = await _firestore.collection('users').doc(email).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final totalTokensUsed = userData['totalTokensUsed'] as int? ?? 0;

        return totalTokensUsed < monthlyLimit;
      }

      return true;
    } catch (e) {
      print('Error checking premium token limit: $e');
      return false;
    }
  }

  /// Quiz oluşturulduktan sonra kullanım sayacını artır
  Future<void> incrementUsage({int tokensUsed = 0}) async {
    final user = _auth.currentUser;

    if (user != null) {
      await _incrementUserUsage(user.email!, tokensUsed);
    } else {
      await _incrementAnonymousUsage();
    }
  }

  /// Giriş yapmış kullanıcı için kullanım artırma
  Future<void> _incrementUserUsage(String email, int tokensUsed) async {
    try {
      final today = _getTodayString();
      final usageDocId = '${today}_$email';

      // Daily usage güncelle
      await _firestore.collection('daily_usage').doc(usageDocId).set({
        'email': email,
        'date': today,
        'quizCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // İlk oluşturulma zamanını ayarla
      await _firestore.collection('daily_usage').doc(usageDocId).update({
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Premium kullanıcı ise token kullanımını güncelle
      final userDoc = await _firestore.collection('users').doc(email).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final plan = userData['plan'] as String? ?? 'free';

        if (plan == 'premium' && tokensUsed > 0) {
          await _firestore.collection('users').doc(email).update({
            'totalTokensUsed': FieldValue.increment(tokensUsed),
          });
        }
      }
    } catch (e) {
      print('Error incrementing user usage: $e');
      rethrow;
    }
  }

  /// Anonymous kullanıcı için kullanım artırma
  Future<void> _incrementAnonymousUsage() async {
    try {
      final deviceId = await _getDeviceId();
      final today = _getTodayString();
      final usageDocId = '${deviceId}_$today';

      await _firestore.collection('anonymous_usage').doc(usageDocId).set({
        'deviceId': deviceId,
        'date': today,
        'quizCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // İlk oluşturulma zamanını ayarla
      await _firestore.collection('anonymous_usage').doc(usageDocId).update({
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error incrementing anonymous usage: $e');
      rethrow;
    }
  }

  /// Kullanıcının kalan quota'sını al
  Future<Map<String, dynamic>> getRemainingQuota() async {
    final user = _auth.currentUser;

    if (user != null) {
      return await _getUserRemainingQuota(user.email!);
    } else {
      return await _getAnonymousRemainingQuota();
    }
  }

  /// Giriş yapmış kullanıcı için kalan quota
  Future<Map<String, dynamic>> _getUserRemainingQuota(String email) async {
    try {
      final userDoc = await _firestore.collection('users').doc(email).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final plan = userData['plan'] as String? ?? 'free';

        if (plan == 'premium') {
          // Premium kullanıcı - token bilgisi döndür
          final totalTokensUsed = userData['totalTokensUsed'] as int? ?? 0;

          final settingsDoc = await _firestore
              .collection('app_settings')
              .doc('limits')
              .get();

          int monthlyLimit = 100000;
          if (settingsDoc.exists) {
            monthlyLimit =
                settingsDoc.data()!['premiumMonthlyTokenLimit'] as int? ??
                100000;
          }

          return {
            'plan': 'premium',
            'tokensUsed': totalTokensUsed,
            'tokensRemaining': monthlyLimit - totalTokensUsed,
            'monthlyLimit': monthlyLimit,
          };
        }
      }

      // Free kullanıcı
      final today = _getTodayString();
      final usageDocId = '${today}_$email';

      final usageDoc = await _firestore
          .collection('daily_usage')
          .doc(usageDocId)
          .get();

      int currentCount = 0;
      if (usageDoc.exists) {
        currentCount = usageDoc.data()!['quizCount'] as int? ?? 0;
      }

      return {
        'plan': 'free',
        'dailyUsed': currentCount,
        'dailyRemaining': FREE_DAILY_LIMIT - currentCount,
        'dailyLimit': FREE_DAILY_LIMIT,
      };
    } catch (e) {
      print('Error getting user remaining quota: $e');
      return {
        'plan': 'free',
        'dailyUsed': FREE_DAILY_LIMIT,
        'dailyRemaining': 0,
        'dailyLimit': FREE_DAILY_LIMIT,
      };
    }
  }

  /// Anonymous kullanıcı için kalan quota
  Future<Map<String, dynamic>> _getAnonymousRemainingQuota() async {
    try {
      final deviceId = await _getDeviceId();
      final today = _getTodayString();
      final usageDocId = '${deviceId}_$today';

      final usageDoc = await _firestore
          .collection('anonymous_usage')
          .doc(usageDocId)
          .get();

      int currentCount = 0;
      if (usageDoc.exists) {
        currentCount = usageDoc.data()!['quizCount'] as int? ?? 0;
      }

      return {
        'plan': 'anonymous',
        'dailyUsed': currentCount,
        'dailyRemaining': ANONYMOUS_DAILY_LIMIT - currentCount,
        'dailyLimit': ANONYMOUS_DAILY_LIMIT,
      };
    } catch (e) {
      print('Error getting anonymous remaining quota: $e');
      return {
        'plan': 'anonymous',
        'dailyUsed': ANONYMOUS_DAILY_LIMIT,
        'dailyRemaining': 0,
        'dailyLimit': ANONYMOUS_DAILY_LIMIT,
      };
    }
  }

  /// Kullanıcının premium olup olmadığını kontrol et
  Future<bool> isPremiumUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(user.email!)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final plan = userData['plan'] as String? ?? 'free';
        return plan == 'premium';
      }
      return false;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }
}
