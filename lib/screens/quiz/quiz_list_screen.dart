import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final List<String> files = ["File1.txt", "File2.txt", "File3.txt"];

  void _createNewFile() {
    setState(() {
      files.add("NewFile${files.length + 1}.txt");
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
        middle: Text(
          'Dosyalar',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        automaticallyImplyLeading: false, // Disable the back button
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Dosya oluşturma butonu
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoButton.filled(
                onPressed: _createNewFile,
                child: const Text("Dosya Oluştur"),
              ),
            ),

            // Dosya listesi
            Expanded(
              child: ListView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        files[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
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
