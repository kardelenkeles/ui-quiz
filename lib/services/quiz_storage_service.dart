import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'device_service.dart';

class QuizStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Cihaz kimliğini al
  Future<String> _getDeviceId() async {
    return await DeviceService.instance.getDeviceId();
  }

  /// Quiz'i kaydet
  Future<String> saveQuiz({
    required String title,
    required List<Map<String, dynamic>> questions,
    int tokensUsed = 0,
  }) async {
    try {
      final user = _auth.currentUser;
      final quizId = _firestore.collection('quizzes').doc().id;

      Map<String, dynamic> quizData = {
        'id': quizId,
        'title': title,
        'questions': questions,
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': null,
        'score': null,
        'tokensUsed': tokensUsed,
      };

      if (user != null) {
        // Giriş yapmış kullanıcı
        quizData['userId'] = user.email;
        quizData['deviceId'] = null;
      } else {
        // Anonymous kullanıcı
        final deviceId = await _getDeviceId();
        quizData['userId'] = null;
        quizData['deviceId'] = deviceId;
      }

      await _firestore.collection('quizzes').doc(quizId).set(quizData);

      return quizId;
    } catch (e) {
      print('Error saving quiz: $e');
      rethrow;
    }
  }

  /// Quiz sonucunu güncelle
  Future<void> updateQuizResult({
    required String quizId,
    required int score,
    required List<Map<String, dynamic>> questionsWithAnswers,
  }) async {
    try {
      await _firestore.collection('quizzes').doc(quizId).update({
        'questions': questionsWithAnswers,
        'completedAt': FieldValue.serverTimestamp(),
        'score': score,
      });
    } catch (e) {
      print('Error updating quiz result: $e');
      rethrow;
    }
  }

  /// Kullanıcının quiz geçmişini al
  Future<List<Map<String, dynamic>>> getUserQuizHistory({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final user = _auth.currentUser;
      Query query;

      if (user != null) {
        // Giriş yapmış kullanıcı
        query = _firestore
            .collection('quizzes')
            .where('userId', isEqualTo: user.email)
            .orderBy('createdAt', descending: true);
      } else {
        // Anonymous kullanıcı
        final deviceId = await _getDeviceId();
        query = _firestore
            .collection('quizzes')
            .where('deviceId', isEqualTo: deviceId);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.limit(limit).get();

      // Anonymous kullanıcılar için client-side sorting
      final docs = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['docSnapshot'] = doc; // Pagination için
        return data;
      }).toList();

      if (user == null) {
        docs.sort((a, b) {
          final aTime =
              (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime =
              (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime); // Descending order
        });
      }

      return docs;
    } catch (e) {
      print('Error getting user quiz history: $e');
      return [];
    }
  }

  /// Belirli bir quiz'i al
  Future<Map<String, dynamic>?> getQuizById(String quizId) async {
    try {
      final doc = await _firestore.collection('quizzes').doc(quizId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      final user = _auth.currentUser;

      // Erişim kontrolü
      if (user != null) {
        // Giriş yapmış kullanıcı - sadece kendi quiz'lerini görebilir
        if (data['userId'] != user.email) {
          throw Exception('Bu quiz\'e erişim yetkiniz yok');
        }
      } else {
        // Anonymous kullanıcı - sadece kendi cihazının quiz'lerini görebilir
        final deviceId = await _getDeviceId();
        if (data['deviceId'] != deviceId || data['userId'] != null) {
          throw Exception('Bu quiz\'e erişim yetkiniz yok');
        }
      }

      return data;
    } catch (e) {
      print('Error getting quiz by ID: $e');
      rethrow;
    }
  }

  /// Quiz'i sil
  Future<void> deleteQuiz(String quizId) async {
    try {
      // Önce quiz'in sahibi olduğunu kontrol et
      final quiz = await getQuizById(quizId);
      if (quiz == null) {
        throw Exception('Quiz bulunamadı');
      }

      await _firestore.collection('quizzes').doc(quizId).delete();
    } catch (e) {
      print('Error deleting quiz: $e');
      rethrow;
    }
  }

  /// Kullanıcının toplam quiz istatistiklerini al
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final user = _auth.currentUser;
      Query query;

      if (user != null) {
        query = _firestore
            .collection('quizzes')
            .where('userId', isEqualTo: user.email);
      } else {
        final deviceId = await _getDeviceId();
        query = _firestore
            .collection('quizzes')
            .where('deviceId', isEqualTo: deviceId)
            .where('userId', isNull: true);
      }

      final querySnapshot = await query.get();
      final quizzes = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      int totalQuizzes = quizzes.length;
      int completedQuizzes = quizzes
          .where((quiz) => quiz['completedAt'] != null)
          .length;
      int totalScore = quizzes
          .where((quiz) => quiz['score'] != null)
          .fold(0, (sum, quiz) => sum + (quiz['score'] as int));
      int totalQuestions = quizzes.fold(
        0,
        (sum, quiz) => sum + (quiz['questions'] as List).length,
      );
      int totalTokensUsed = quizzes.fold(
        0,
        (sum, quiz) => sum + ((quiz['tokensUsed'] as int?) ?? 0),
      );

      double averageScore = completedQuizzes > 0
          ? totalScore / completedQuizzes
          : 0;

      return {
        'totalQuizzes': totalQuizzes,
        'completedQuizzes': completedQuizzes,
        'uncompletedQuizzes': totalQuizzes - completedQuizzes,
        'totalScore': totalScore,
        'averageScore': averageScore,
        'totalQuestions': totalQuestions,
        'totalTokensUsed': totalTokensUsed,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'totalQuizzes': 0,
        'completedQuizzes': 0,
        'uncompletedQuizzes': 0,
        'totalScore': 0,
        'averageScore': 0.0,
        'totalQuestions': 0,
        'totalTokensUsed': 0,
      };
    }
  }

  /// Popüler quiz konularını al (tüm kullanıcılar için)
  Future<List<Map<String, dynamic>>> getPopularTopics({int limit = 10}) async {
    try {
      // Bu özellik için app_settings'de topic istatistikleri tutulabilir
      // Şimdilik basit implement ediyoruz

      final settingsDoc = await _firestore
          .collection('app_settings')
          .doc('popular_topics')
          .get();

      if (settingsDoc.exists) {
        final data = settingsDoc.data()!;
        final topics = data['topics'] as List<dynamic>? ?? [];

        return topics
            .map(
              (topic) => {
                'name': topic['name'] as String,
                'count': topic['count'] as int,
              },
            )
            .toList();
      }

      // Fallback popüler konular
      return [
        {'name': 'Flutter', 'count': 150},
        {'name': 'Dart', 'count': 120},
        {'name': 'Matematik', 'count': 100},
        {'name': 'Tarih', 'count': 95},
        {'name': 'Coğrafya', 'count': 80},
        {'name': 'Fen Bilgisi', 'count': 75},
        {'name': 'İngilizce', 'count': 70},
        {'name': 'Programlama', 'count': 65},
      ];
    } catch (e) {
      print('Error getting popular topics: $e');
      return [];
    }
  }

  /// Quiz konusunu popüler konulara ekle/güncelle
  Future<void> updateTopicPopularity(String topic) async {
    try {
      final topicLower = topic.toLowerCase().trim();

      await _firestore.collection('app_settings').doc('popular_topics').set({
        'topics': FieldValue.arrayUnion([
          {
            'name': topicLower,
            'count': 1,
            'lastUsed': FieldValue.serverTimestamp(),
          },
        ]),
      }, SetOptions(merge: true));

      // Bu işlem Firebase Functions ile daha iyi yapılabilir
      // Şimdilik basit increment yapıyoruz
    } catch (e) {
      print('Error updating topic popularity: $e');
      // Hata olsa da quiz oluşturma devam etsin
    }
  }

  /// Quiz'leri arama
  Future<List<Map<String, dynamic>>> searchQuizzes({
    required String searchTerm,
    int limit = 20,
  }) async {
    try {
      final user = _auth.currentUser;

      // Firestore'da full-text search yoktur, basit title araması yapıyoruz
      // Daha gelişmiş arama için Algolia veya Elasticsearch kullanılabilir

      Query query;
      if (user != null) {
        query = _firestore
            .collection('quizzes')
            .where('userId', isEqualTo: user.email)
            .orderBy('createdAt', descending: true);
      } else {
        final deviceId = await _getDeviceId();
        query = _firestore
            .collection('quizzes')
            .where('deviceId', isEqualTo: deviceId)
            .where('userId', isNull: true)
            .orderBy('createdAt', descending: true);
      }

      final querySnapshot = await query
          .limit(limit * 2)
          .get(); // Daha fazla al, filtrele

      final searchTermLower = searchTerm.toLowerCase();
      final filteredQuizzes = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((quiz) {
            final title = (quiz['title'] as String).toLowerCase();
            return title.contains(searchTermLower);
          })
          .take(limit)
          .toList();

      return filteredQuizzes;
    } catch (e) {
      print('Error searching quizzes: $e');
      return [];
    }
  }
}
