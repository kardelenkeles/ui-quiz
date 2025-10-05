import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final List<Map<String, String>> files = [
    {"name": "File1.txt", "createdAt": "2025-10-01"},
    {"name": "File2.txt", "createdAt": "2025-10-02"},
    {"name": "File3.txt", "createdAt": "2025-10-03"},
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
              child: ListView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) =>
                              QuizHistoryScreen(fileName: file["name"]!),
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
                              file["name"]!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Created At: ${file["createdAt"]}",
                              style: const TextStyle(
                                fontSize: 14,
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
          ],
        ),
      ),
    );
  }
}

class QuizHistoryScreen extends StatelessWidget {
  final String fileName;

  const QuizHistoryScreen({super.key, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('History: $fileName')),
      child: Center(
        child: Text(
          'Quiz history for $fileName',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
