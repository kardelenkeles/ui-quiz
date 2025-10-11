import 'dart:io';

import 'package:animated_button/animated_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_quiz/services/file_text_extractor.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:ui_quiz/screens/progress-indicator/quiz_generator_progress.dart';
import 'package:ui_quiz/widgets/custom_tab_bar.dart';

// Ana QuizGeneratorScreen artık sadece CustomTabBarWidget'ı çağırıyor
class QuizGeneratorScreen extends StatelessWidget {
  const QuizGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomTabBarWidget();
  }
}

class QuizGeneratorContent extends StatefulWidget {
  const QuizGeneratorContent({super.key});

  @override
  State<QuizGeneratorContent> createState() => _QuizGeneratorContentState();
}

class _QuizGeneratorContentState extends State<QuizGeneratorContent> {
  final _textController = TextEditingController();
  File? _selectedFile; // Updated to use File from dart:io
  String? _selectedFileText;

  void _generateQuiz() {
    if ((_textController.text.isEmpty || _textController.text.trim().isEmpty) &&
        _selectedFile == null) {
      _showAlert('Hata', 'Lütfen bir metin girin veya bir dosya yükleyin.');
      return;
    }

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => QuizGeneratorProgressScreen(
          inputText: _textController.text.trim(),
          fileContent: _selectedFileText,
        ),
      ),
    );
  }

  void _importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf', 'docx', 'xlsx', 'pptx'],
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        setState(() {
          _selectedFile = File(file.path!);
          _selectedFileText = null; // will fill after extraction
        });

        // Extract text asynchronously and store it
        try {
          final extracted = await FileTextExtractor.extractText(
            File(file.path!),
          );
          setState(() {
            _selectedFileText = extracted;
          });
        } on MissingPluginException catch (e) {
          // Plugin not registered (common after hot-reload). Show retry/continue dialog.
          print('MissingPluginException during file extraction: $e');
          _showExtractionErrorDialog();
        } catch (e) {
          // non-blocking: keep file but leave text null
          print('File extraction failed: $e');
        }
      } else {
        _showAlert('Bilgi', 'Dosya seçimi iptal edildi.');
      }
    } catch (e) {
      _showAlert('Hata', 'Dosya seçimi sırasında bir hata oluştu: $e');
    }
  }

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showExtractionErrorDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('PDF Okuma Hatası'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'PDF metni çıkarılırken eklenti bulunamadı. Lütfen uygulamayı tamamen kapatıp yeniden başlatın veya tekrar deneyin.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Tekrar Dene'),
            onPressed: () {
              Navigator.of(context).pop();
              _importFile(); // tekrar dene
            },
          ),
          CupertinoDialogAction(
            child: const Text('Devam Et (Dosya olmadan)'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            child: const Text('Kapatıp Yeniden Başlat'),
            onPressed: () {
              Navigator.of(context).pop();
              // no programmatic restart; instruct user to manually restart
              _showAlert('Bilgi', 'Lütfen uygulamayı kapatıp tekrar açın.');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: true, // Klavye için otomatik ayarlama
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 30, left: 30),
            decoration: const BoxDecoration(
              color: CupertinoColors.systemBackground,
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'asset/icon/appicon.png',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'PomeAI',
                    style: TextStyle(
                      fontFamily: 'Bobby Jones',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ana içerik - Scrollable
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 15), // Üstten boşluk
                      Image.asset(
                        'asset/icon/pastehere.png',
                        width: 160,
                        height: 160,
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          CupertinoTextField(
                            controller: _textController,
                            maxLines: 10,
                            expands: false,
                            minLines: 6,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(4, 4),
                                ),
                                BoxShadow(
                                  color: Colors.white,
                                  blurRadius: 10,
                                  offset: Offset(-4, -4),
                                ),
                              ],
                              border: Border.all(
                                color: CupertinoColors.systemGrey4,
                                width: 1.5,
                              ),
                            ),
                            scrollController: ScrollController(),
                            onTap: () async {
                              ClipboardData? clipboardData =
                                  await Clipboard.getData('text/plain');
                              if (clipboardData != null &&
                                  clipboardData.text != null) {
                                setState(() {
                                  _textController.text = clipboardData.text!;
                                });
                              }
                            },
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: Icon(
                              CupertinoIcons.doc_on_clipboard,
                              color: CupertinoColors.inactiveGray,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Dosya türü ikonları
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'asset/icon/pdf.png',
                              width: 25,
                              height: 25,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemBlue.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'asset/icon/word.png',
                              width: 25,
                              height: 25,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemOrange.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'asset/icon/ppt.png',
                              width: 25,
                              height: 25,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGreen.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'asset/icon/excel.png',
                              width: 25,
                              height: 25,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemPurple.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'asset/icon/img.png',
                              width: 25,
                              height: 25,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // "or import your files" yazısı
                      const Text(
                        'or import your files',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Import butonu - daraltılmış ve ortalanmış
                      Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CupertinoButton(
                            onPressed: _importFile,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 64,
                              vertical: 32,
                            ),
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'asset/icon/file-import.png',
                                  width: 30,
                                  height: 30,
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (_selectedFile != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'Seçilen Dosya: ${_selectedFile!.path.split('/').last}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.label,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedFile = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey6,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: CupertinoColors.systemGrey4,
                                    ),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.clear_circled_solid,
                                    color: CupertinoColors.systemGrey,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Generate butonu
                      Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedButton(
                          onPressed: _generateQuiz,
                          color: Colors.lime,
                          enabled: true,
                          disabledColor: Colors.grey,
                          shadowDegree: ShadowDegree.light,
                          borderRadius: 20,
                          duration: 0,
                          height: 50,
                          width: 150,
                          child: const Text(
                            'Generate',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40), // Alttan boşluk
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
