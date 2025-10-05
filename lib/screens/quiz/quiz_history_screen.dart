import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ui_quiz/screens/quiz/quiz_result_screen.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  final List<Map<String, dynamic>> files = [
    {
      "name": "Flutter Temelleri Quiz",
      "createdAt": "2025-10-01",
      "correctAnswers": 3,
      "totalQuestions": 4,
      "questions": [
        {
          'question': 'Flutter hangi programlama diliyle geliştirilir?',
          'options': [
            {'letter': 'A', 'text': 'Java'},
            {'letter': 'B', 'text': 'Dart'},
            {'letter': 'C', 'text': 'Kotlin'},
            {'letter': 'D', 'text': 'Swift'},
          ],
          'correctAnswer': 'B',
          'selectedAnswer': 'B',
        },
        {
          'question': 'Widget nedir?',
          'options': [
            {'letter': 'A', 'text': 'Bir programlama dili'},
            {'letter': 'B', 'text': 'Bir veritabanı'},
            {'letter': 'C', 'text': 'UI bileşeni'},
            {'letter': 'D', 'text': 'Bir sunucu'},
          ],
          'correctAnswer': 'C',
          'selectedAnswer': 'C',
        },
        {
          'question': 'StatefulWidget ne işe yarar?',
          'options': [
            {'letter': 'A', 'text': 'Hiçbir şey'},
            {'letter': 'B', 'text': 'Durumu değişebilir'},
            {'letter': 'C', 'text': 'Sadece görünüm'},
            {'letter': 'D', 'text': 'Hata ayıklama'},
          ],
          'correctAnswer': 'B',
          'selectedAnswer': 'A',
        },
        {
          'question': 'Hot Reload ne işe yarar?',
          'options': [
            {'letter': 'A', 'text': 'Uygulamayı yeniden başlatır'},
            {'letter': 'B', 'text': 'Kodu anında günceller'},
            {'letter': 'C', 'text': 'Uygulamayı yayınlar'},
            {'letter': 'D', 'text': 'Hata ayıklar'},
          ],
          'correctAnswer': 'B',
          'selectedAnswer': 'B',
        },
      ],
    },
    {
      "name": "Dart Programlama Quiz",
      "createdAt": "2025-10-02",
      "correctAnswers": 2,
      "totalQuestions": 3,
      "questions": [
        {
          'question': 'Dart hangi şirket tarafından geliştirildi?',
          'options': [
            {'letter': 'A', 'text': 'Google'},
            {'letter': 'B', 'text': 'Microsoft'},
            {'letter': 'C', 'text': 'Apple'},
            {'letter': 'D', 'text': 'Facebook'},
          ],
          'correctAnswer': 'A',
          'selectedAnswer': 'A',
        },
        {
          'question': 'Dart dilinde değişken tanımlama?',
          'options': [
            {'letter': 'A', 'text': 'var'},
            {'letter': 'B', 'text': 'let'},
            {'letter': 'C', 'text': 'const'},
            {'letter': 'D', 'text': 'final'},
          ],
          'correctAnswer': 'A',
          'selectedAnswer': 'B',
        },
        {
          'question': 'Dart null safety ne zaman eklendi?',
          'options': [
            {'letter': 'A', 'text': '2019'},
            {'letter': 'B', 'text': '2020'},
            {'letter': 'C', 'text': '2021'},
            {'letter': 'D', 'text': '2022'},
          ],
          'correctAnswer': 'C',
          'selectedAnswer': 'C',
        },
      ],
    },
    {
      "name": "Mobile Development Quiz",
      "createdAt": "2025-10-03",
      "correctAnswers": 1,
      "totalQuestions": 2,
      "questions": [
        {
          'question': 'iOS uygulamaları hangi dilde yazılır?',
          'options': [
            {'letter': 'A', 'text': 'Java'},
            {'letter': 'B', 'text': 'Swift'},
            {'letter': 'C', 'text': 'Kotlin'},
            {'letter': 'D', 'text': 'C#'},
          ],
          'correctAnswer': 'B',
          'selectedAnswer': 'A',
        },
        {
          'question': 'Android Studio hangi IDE tabanlıdır?',
          'options': [
            {'letter': 'A', 'text': 'Eclipse'},
            {'letter': 'B', 'text': 'IntelliJ IDEA'},
            {'letter': 'C', 'text': 'Visual Studio'},
            {'letter': 'D', 'text': 'NetBeans'},
          ],
          'correctAnswer': 'B',
          'selectedAnswer': 'B',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
        automaticallyImplyLeading: false, // Disable the back button
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Geçmiş Quizler başlığı
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, right: 150),
              child: Text(
                'Geçmiş Quizler',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Geçmiş Quizler listesi
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                radius: const Radius.circular(8),
                thickness: 4,
                child: ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => QuizResultScreen(
                              correctAnswers: file["correctAnswers"] as int,
                              totalQuestions: file["totalQuestions"] as int,
                              questions:
                                  file["questions"]
                                      as List<Map<String, dynamic>>,
                              quizName: file["name"] as String,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file["name"] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Skor: ${file["correctAnswers"]}/${file["totalQuestions"]} - ${((file["correctAnswers"] as int) / (file["totalQuestions"] as int) * 100).toStringAsFixed(0)}%",
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      (file["correctAnswers"] as int) /
                                              (file["totalQuestions"] as int) >=
                                          0.7
                                      ? CupertinoColors.systemGreen
                                      : CupertinoColors.systemOrange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Tarih: ${file["createdAt"]}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
