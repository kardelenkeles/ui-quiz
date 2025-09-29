import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/screens/quiz_play.dart';
import '../providers/quiz_provider.dart';

@RoutePage()
class QuizGeneratorScreen extends StatefulWidget {
  const QuizGeneratorScreen({super.key});

  @override
  State<QuizGeneratorScreen> createState() => _QuizGeneratorScreenState();
}

class _QuizGeneratorScreenState extends State<QuizGeneratorScreen> {
  final _textController = TextEditingController();
  String _selectedLanguage = 'auto';
  String _detectedLanguage = 'Detecting...';
  bool _isDetectingLanguage = false;

  void _detectLanguage() async {
    if (_textController.text.length < 10) return;

    setState(() {
      _isDetectingLanguage = true;
    });

    // Bu kısım API servisine bağlanacak
    await Future.delayed(const Duration(seconds: 1)); // Simülasyon
    setState(() {
      _detectedLanguage = 'Turkish';
      _isDetectingLanguage = false;
    });
  }

  void _generateQuiz() async {
    if (_textController.text.length < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az 30 karakter girin')),
      );
      return;
    }

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    await quizProvider.generateQuiz(
      _textController.text,
      language: _selectedLanguage,
    );

    if (quizProvider.error.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: ${quizProvider.error}')));
    } else if (quizProvider.currentQuiz != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QuizPlayScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Oluştur'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Consumer<QuizProvider>(
          builder: (context, quizProvider, child) {
            return Column(
              children: [
                // Dil seçimi
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dil Ayarları',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedLanguage,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'auto',
                                    child: Text('Otomatik Tespit'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'tr',
                                    child: Text('Türkçe'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'en',
                                    child: Text('İngilizce'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'es',
                                    child: Text('İspanyolca'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'fr',
                                    child: Text('Fransızca'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'de',
                                    child: Text('Almanca'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedLanguage = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Tespit edilen dil: '),
                            _isDetectingLanguage
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _detectedLanguage,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Metin girişi
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Metin Girin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLines: null,
                              expands: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              onChanged: (value) {
                                if (value.length > 10) {
                                  _detectLanguage();
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text('Karakter: ${_textController.text.length}'),
                              const Spacer(),
                              if (_textController.text.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    _textController.clear();
                                    setState(() {
                                      _detectedLanguage = 'Detecting...';
                                    });
                                  },
                                  child: const Text('Temizle'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Generate butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: quizProvider.isLoading ? null : _generateQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: quizProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Quiz Oluştur',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
