import 'dart:io';

import 'package:animated_button/animated_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_quiz/services/file_text_extractor.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/auth_provider.dart';
import 'package:ui_quiz/screens/progress-indicator/quiz_generator_progress.dart';
import 'package:ui_quiz/screens/profile/auth_screen.dart';
import 'package:ui_quiz/screens/quiz/page_picker_screen.dart';

// Ana QuizGeneratorScreen artık sadece CustomTabBarWidget'ı çağırıyor
class QuizGeneratorScreen extends StatelessWidget {
  const QuizGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _QuizGeneratorView();
  }
}

// Private stateful view to contain the widget's state. Keeping state
// in an inner StatefulWidget lets the outer screen be stateless while
// preserving existing behavior and API.
class _QuizGeneratorView extends StatefulWidget {
  const _QuizGeneratorView({Key? key}) : super(key: key);

  @override
  _QuizGeneratorViewState createState() => _QuizGeneratorViewState();
}

class _QuizGeneratorViewState extends State<_QuizGeneratorView> {
  // State fields used across the widget
  final TextEditingController _textController = TextEditingController();
  bool _textHasContent = false;
  File? _selectedFile;
  String? _selectedFileText;
  int? _selectedFilePageCount;
  List<int> _selectedPages = [];
  int _selectedQuestionCount = 10;
  String _selectedDifficulty = 'mid';
  bool _isProcessingFile = false;
  final int maxSelectable = 8;

  Future<void> _openPagePickerModal() async {
    if (_selectedFile == null) return;

    int pageCount = _selectedFilePageCount ?? 0;
    if (pageCount == 0) pageCount = 1;

    final maxSelectable = 8;

    // Local modal copies to avoid mutating parent state while the picker is active
    List<int> modalSelectedPages = List<int>.from(_selectedPages);

    final resultMap = await Navigator.of(context).push<Map<String, dynamic>>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => PagePickerScreen(
          selectedFile: _selectedFile!,
          pageCount: pageCount,
          initialSelectedPages: modalSelectedPages,
          maxSelectable: maxSelectable,
        ),
      ),
    );

    if (resultMap != null && resultMap['selectedPages'] != null) {
      final returnedPages = List<int>.from(resultMap['selectedPages'] as List);
      if (!mounted) return;
      setState(() {
        _selectedPages = returnedPages;
        if (resultMap['questionCount'] != null) {
          try {
            _selectedQuestionCount = (resultMap['questionCount'] as num)
                .toInt();
          } catch (_) {}
        }
        if (resultMap['difficulty'] != null) {
          _selectedDifficulty = resultMap['difficulty'].toString();
        }
      });
      return;
    }
    // if user cancelled, do nothing
  }

  void _importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'jpe',
          'jfif',
          'pjpeg',
          'pjp',
          'png',
          'pdf',
          'docx',
          'xlsx',
          'pptx',
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        setState(() {
          _selectedFile = File(file.path!);
          _selectedFileText = null; // will fill after extraction
          _selectedFilePageCount = null;
          _selectedPages = [];
          _isProcessingFile = true;
        });

        // Extract text asynchronously and store it
        try {
          final extracted = await FileTextExtractor.extractText(
            File(file.path!),
          );
          setState(() {
            _selectedFileText = extracted;
          });
          // Try to get page count (PDF/PPTX)
          try {
            final count = await FileTextExtractor.getPageCount(
              File(file.path!),
            );
            setState(() {
              _selectedFilePageCount = count;
            });
            // Auto-open preview modal after page count is known
            await Future.delayed(const Duration(milliseconds: 150));

            // If single-page or no need to pick pages, select all and generate
            if (count == null || count <= 1) {
              setState(() {
                _selectedPages = [1];
              });
              // hide spinner before navigating
              if (mounted) setState(() => _isProcessingFile = false);
              await _generateQuiz();
            } else {
              // open picker and await user selection
              await _openPagePickerModal();
              if (mounted) setState(() => _isProcessingFile = false);
              // if user selected pages, automatically generate
              if (_selectedPages.isNotEmpty) {
                await _generateQuiz();
              }
            }
          } catch (_) {}
        } on MissingPluginException catch (e) {
          // Plugin not registered (common after hot-reload). Show retry/continue dialog.
          print('MissingPluginException during file extraction: $e');
          _showExtractionErrorDialog();
        } catch (e) {
          // non-blocking: keep file but leave text null
          print('File extraction failed: $e');
        }
        // Ensure spinner is hidden if extraction failed or user cancelled
        if (mounted) {
          setState(() {
            _isProcessingFile = false;
          });
        }
      } else {
        // User cancelled file selection — silently ignore (no dialog)
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
    return Material(
      child: CupertinoPageScaffold(
        resizeToAvoidBottomInset: true,
        child: Stack(
          children: [
            // Main column content
            Column(
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
                            decoration: TextDecoration.none,
                            fontFamily: 'Bobby Jones',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.label,
                          ),
                        ),
                        const Spacer(),
                        // Camera icon top-right
                        GestureDetector(
                          onTap: _captureFromCamera,
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              CupertinoIcons.camera,
                              size: 22,
                              color: CupertinoColors.black,
                            ),
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
                                  readOnly: _selectedFile != null,
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
                                    if (_selectedFile != null) return;
                                    ClipboardData? clipboardData =
                                        await Clipboard.getData('text/plain');
                                    if (clipboardData != null &&
                                        clipboardData.text != null) {
                                      setState(() {
                                        _textController.text =
                                            clipboardData.text!;
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

                            // "or import your files" yazısı
                            const Text(
                              'or import your files',
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: 14,
                                color: CupertinoColors.secondaryLabel,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'Nunito',
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Dosya türü ikonları
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemRed
                                        .withOpacity(0.1),
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
                                    color: CupertinoColors.systemBlue
                                        .withOpacity(0.1),
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
                                    color: CupertinoColors.systemOrange
                                        .withOpacity(0.1),
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
                                    color: CupertinoColors.systemGreen
                                        .withOpacity(0.1),
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
                                    color: CupertinoColors.systemPurple
                                        .withOpacity(0.1),
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
                                  onPressed: _textHasContent
                                      ? null
                                      : _importFile,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 54,
                                    vertical: 28,
                                  ),
                                  color: CupertinoColors.systemGrey6,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        _selectedFile != null
                                            ? 'asset/icon/folderfilled.png'
                                            : 'asset/icon/folder.png',
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          foregroundColor:
                                              CupertinoColors.activeBlue,
                                        ),
                                        onPressed: () async {
                                          if (_selectedFile != null) {
                                            await _openPagePickerModal();
                                          }
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                _selectedFile!.path
                                                    .split('/')
                                                    .last,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                    const SizedBox(width: 8),
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
                                    decoration: TextDecoration.none,
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Nunito',
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
            // Overlay spinner while processing file selection
            if (_isProcessingFile)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.lime),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = _textController.text.trim().isNotEmpty;
    if (has != _textHasContent) {
      setState(() {
        _textHasContent = has;
        // If user pasted text, clear any selected file to avoid conflict
        if (_textHasContent && _selectedFile != null) {
          _selectedFile = null;
          _selectedFileText = null;
          _selectedFilePageCount = null;
          _selectedPages = [];
        }
      });
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (photo == null) return; // user cancelled

      final tempFile = File(photo.path);
      setState(() {
        _selectedFile = tempFile;
        _selectedFileText = null;
        _selectedFilePageCount = null;
        _selectedPages = [];
        _isProcessingFile = true;
      });

      try {
        final extracted = await FileTextExtractor.extractText(tempFile);
        if (!mounted) return;
        setState(() {
          _selectedFileText = extracted;
        });

        try {
          final count = await FileTextExtractor.getPageCount(tempFile);
          if (!mounted) return;
          setState(() {
            _selectedFilePageCount = count;
          });

          await Future.delayed(const Duration(milliseconds: 150));

          if (count == null || count <= 1) {
            setState(() => _selectedPages = [1]);
            if (mounted) setState(() => _isProcessingFile = false);

            // Ask user for question settings after capturing photo
            final settings = await _showQuestionSettingsModal();
            if (settings == null) {
              // user cancelled; keep file selected but do not generate
              return;
            }
            if (!mounted) return;
            setState(() {
              try {
                _selectedQuestionCount = (settings['questionCount'] as num)
                    .toInt();
              } catch (_) {}
              _selectedDifficulty =
                  settings['difficulty']?.toString() ?? _selectedDifficulty;
            });

            await _generateQuiz();
          } else {
            await _openPagePickerModal();
            if (mounted) setState(() => _isProcessingFile = false);
            if (_selectedPages.isNotEmpty) {
              // After user selects pages, ask for question settings
              final settings = await _showQuestionSettingsModal();
              if (settings == null) {
                // user cancelled; keep selection but abort generation
                return;
              }
              if (!mounted) return;
              setState(() {
                try {
                  _selectedQuestionCount = (settings['questionCount'] as num)
                      .toInt();
                } catch (_) {}
                _selectedDifficulty =
                    settings['difficulty']?.toString() ?? _selectedDifficulty;
              });

              await _generateQuiz();
            }
          }
        } catch (_) {
          if (mounted) setState(() => _isProcessingFile = false);
        }
      } on MissingPluginException catch (e) {
        print('MissingPluginException during camera extraction: $e');
        _showExtractionErrorDialog();
      } catch (e) {
        print('Camera file extraction failed: $e');
      }

      if (mounted) setState(() => _isProcessingFile = false);
    } catch (e) {
      _showAlert('Hata', 'Kamera açılırken bir hata oluştu: $e');
    }
  }

  Future<Map<String, dynamic>?> _showQuestionSettingsModal() async {
    // Returns {'questionCount': int, 'difficulty': String} or null if cancelled
    return await showModalBottomSheet<Map<String, dynamic>>(
      backgroundColor: CupertinoColors.systemBackground,
      context: context,
      isScrollControlled: true,
      builder: (context) {
        int localCount = _selectedQuestionCount;
        String localDiff = _selectedDifficulty;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final brandColor = const Color(0xFF2FB3A6);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 12,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Question settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Question count selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Number of questions',
                          style: TextStyle(fontSize: 16),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (localCount > 1)
                                  setModalState(() => localCount--);
                              },
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: brandColor,
                              ),
                            ),
                            Text(
                              localCount.toString(),
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              onPressed: () {
                                if (localCount < 20)
                                  setModalState(() => localCount++);
                              },
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: brandColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Difficulty selector
                    const Text('Difficulty', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: localDiff == 'easy'
                                ? brandColor
                                : Colors.grey[200],
                            foregroundColor: localDiff == 'easy'
                                ? Colors.white
                                : Colors.black,
                          ),
                          onPressed: () =>
                              setModalState(() => localDiff = 'easy'),
                          child: const Text('Easy'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: localDiff == 'mid'
                                ? brandColor
                                : Colors.grey[200],
                            foregroundColor: localDiff == 'mid'
                                ? Colors.white
                                : Colors.black,
                          ),
                          onPressed: () =>
                              setModalState(() => localDiff = 'mid'),
                          child: const Text('Mid'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: localDiff == 'hard'
                                ? brandColor
                                : Colors.grey[200],
                            foregroundColor: localDiff == 'hard'
                                ? Colors.white
                                : Colors.black,
                          ),
                          onPressed: () =>
                              setModalState(() => localDiff = 'hard'),
                          child: const Text('Hard'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(null),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop({
                              'questionCount': localCount,
                              'difficulty': localDiff,
                            });
                          },
                          child: const Text('Generate'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _generateQuiz() async {
    // If user is not signed in, redirect to registration screen and wait for result
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) {
      await Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => const AuthScreen(initialSignUp: true),
        ),
      );

      // After the auth screen closes, re-check authentication state
      if (!mounted) return;
      final updatedAuth = Provider.of<AuthProvider>(context, listen: false);
      if (updatedAuth.user == null) {
        // User didn't sign in — don't proceed
        return;
      }
    }

    // User signed in - Navigate to progress screen and pass selected pages/file
    if (!mounted) return;
    // If user pasted text (no file), ask for question settings first
    if (_selectedFile == null && _textController.text.trim().isNotEmpty) {
      final settings = await _showQuestionSettingsModal();
      if (settings == null) return; // user cancelled
      setState(() {
        try {
          _selectedQuestionCount = (settings['questionCount'] as num).toInt();
        } catch (_) {}
        _selectedDifficulty =
            settings['difficulty']?.toString() ?? _selectedDifficulty;
      });
    }

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => QuizGeneratorProgressScreen(
          inputText: _textController.text,
          fileContent: _selectedFileText,
          selectedPages: _selectedPages.isEmpty ? null : _selectedPages,
          filePath: _selectedFile?.path,
          // pass original filename (without path) if available
          originalFileName: _selectedFile != null
              ? _selectedFile!.uri.pathSegments.isNotEmpty
                    ? _selectedFile!.uri.pathSegments.last
                    : null
              : null,
          questionCount: _selectedQuestionCount,
          difficulty: _selectedDifficulty,
        ),
      ),
    );
  }
}
