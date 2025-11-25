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

  // Multiple camera photos support
  List<File> _capturedPhotos = [];
  List<String> _capturedPhotosText = [];

  Future<Map<String, dynamic>?> _openPagePickerModal() async {
    if (_selectedFile == null) return null;

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
      if (!mounted) return resultMap;
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
      return resultMap;
    }
    // if user cancelled, do nothing
    return null;
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

              // Ask user for question settings before generating
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
              // open picker and await user selection
              final pickerResult = await _openPagePickerModal();
              if (mounted) setState(() => _isProcessingFile = false);
              // if user selected pages, automatically generate
              if (_selectedPages.isNotEmpty) {
                // If the picker already provided question settings, use them
                if (pickerResult != null &&
                    (pickerResult['questionCount'] != null ||
                        pickerResult['difficulty'] != null)) {
                  if (!mounted) return;
                  setState(() {
                    try {
                      if (pickerResult['questionCount'] != null) {
                        _selectedQuestionCount =
                            (pickerResult['questionCount'] as num).toInt();
                      }
                    } catch (_) {}
                    _selectedDifficulty =
                        pickerResult['difficulty']?.toString() ??
                        _selectedDifficulty;
                  });
                  await _generateQuiz();
                  return;
                }

                // Ask user for question settings before generating
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
    // If there's any input (pasted text, a selected file, or captured photos),
    // other input options should be disabled (including camera).
    final bool hasInput =
        _textHasContent || _selectedFile != null || _capturedPhotos.isNotEmpty;

    return Material(
      child: CupertinoPageScaffold(
        resizeToAvoidBottomInset: true,
        child: Stack(
          children: [
            // Main column content
            Column(
              children: [
                // Ana içerik - Scrollable
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),

                          Image.asset(
                            'asset/icon/b.png',
                            width: 300,
                            height: 260,
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Stack(
                              children: [
                                CupertinoTextField(
                                  controller: _textController,
                                  readOnly: _selectedFile != null,
                                  placeholder: 'Tap to paste from clipboard...',
                                  placeholderStyle: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 10,
                                  expands: false,
                                  minLines: 6,
                                  padding: const EdgeInsets.all(16),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: CupertinoColors.black,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _textHasContent
                                        ? Colors.white
                                        : CupertinoColors.systemGrey6,
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
                                      color: _textHasContent
                                          ? Colors.lime.withOpacity(0.5)
                                          : CupertinoColors.systemGrey4,
                                      width: 2.0,
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
                                  child: AnimatedOpacity(
                                    opacity: _textHasContent ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      CupertinoIcons.doc_on_clipboard,
                                      color: CupertinoColors.systemGrey,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                if (_textHasContent)
                                  Positioned(
                                    right: 10,
                                    top: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.lime.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_textController.text.length} chars',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: CupertinoColors.systemGrey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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

                          // Import butonu ve Kamera ikonu yan yana
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Import butonu
                                DecoratedBox(
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
                                    onPressed: hasInput ? null : _importFile,
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
                                const SizedBox(width: 16),
                                // Kamera ikonu
                                GestureDetector(
                                  onTap: hasInput ? null : _captureFromCamera,
                                  child: Opacity(
                                    opacity: hasInput ? 0.45 : 1.0,
                                    child: Container(
                                      padding: const EdgeInsets.all(28),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemGrey6,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      child: Image.asset(
                                        'asset/icon/camera.png',
                                        width: 30,
                                        height: 30,
                                        color: CupertinoColors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                                          final pickerResult =
                                              await _openPagePickerModal();
                                          // If picker returned pages and also provided settings,
                                          // apply them and auto-generate.
                                          if (_selectedPages.isNotEmpty) {
                                            if (pickerResult != null &&
                                                (pickerResult['questionCount'] !=
                                                        null ||
                                                    pickerResult['difficulty'] !=
                                                        null)) {
                                              if (!mounted) return;
                                              setState(() {
                                                try {
                                                  if (pickerResult['questionCount'] !=
                                                      null) {
                                                    _selectedQuestionCount =
                                                        (pickerResult['questionCount']
                                                                as num)
                                                            .toInt();
                                                  }
                                                } catch (_) {}
                                                _selectedDifficulty =
                                                    pickerResult['difficulty']
                                                        ?.toString() ??
                                                    _selectedDifficulty;
                                              });
                                              await _generateQuiz();
                                              return;
                                            }

                                            // otherwise, ask for question settings then generate
                                            final settings =
                                                await _showQuestionSettingsModal();
                                            if (settings == null) return;
                                            if (!mounted) return;
                                            setState(() {
                                              try {
                                                _selectedQuestionCount =
                                                    (settings['questionCount']
                                                            as num)
                                                        .toInt();
                                              } catch (_) {}
                                              _selectedDifficulty =
                                                  settings['difficulty']
                                                      ?.toString() ??
                                                  _selectedDifficulty;
                                            });
                                            await _generateQuiz();
                                          }
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
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),

                          // Show captured photos
                          if (_capturedPhotos.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.photo_camera_solid,
                                        size: 16,
                                        color: CupertinoColors.systemGreen,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_capturedPhotos.length} fotoğraf çekildi',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: CupertinoColors.systemGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => setState(() {
                                          _capturedPhotos.clear();
                                          _capturedPhotosText.clear();
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.systemGrey6,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  CupertinoColors.systemGrey4,
                                            ),
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.clear_circled_solid,
                                            color: CupertinoColors.systemGrey,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Show thumbnails
                                  SizedBox(
                                    height: 80,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _capturedPhotos.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8.0,
                                          ),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.file(
                                                  _capturedPhotos[index],
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              // Delete button overlay
                                              Positioned(
                                                top: 2,
                                                right: 2,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _capturedPhotos.removeAt(
                                                        index,
                                                      );
                                                      if (index <
                                                          _capturedPhotosText
                                                              .length) {
                                                        _capturedPhotosText
                                                            .removeAt(index);
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black54,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      CupertinoIcons.clear,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 40),

                          // Generate butonu
                          Center(
                            child: AnimatedButton(
                              onPressed: _generateQuiz,
                              color: Colors.lime,
                              enabled: true,
                              disabledColor: Colors.grey,
                              shadowDegree: ShadowDegree.light,
                              borderRadius: 20,
                              duration: 0,
                              height: 60,
                              width: 280,
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
        // Also clear captured photos
        if (_textHasContent && _capturedPhotos.isNotEmpty) {
          _capturedPhotos.clear();
          _capturedPhotosText.clear();
        }
      });
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final picker = ImagePicker();

      // Start capturing loop
      bool continueCaptoring = true;
      List<File> sessionPhotos = [];
      List<String> sessionTexts = [];

      while (continueCaptoring) {
        final XFile? photo = await picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          imageQuality: 85,
        );

        if (photo == null) {
          // User cancelled camera
          if (sessionPhotos.isEmpty) {
            return; // First photo was cancelled, abort
          } else {
            break; // Already have photos, proceed with them
          }
        }

        final tempFile = File(photo.path);
        sessionPhotos.add(tempFile);

        setState(() {
          _isProcessingFile = true;
        });

        // Extract text from this photo
        try {
          final extracted = await FileTextExtractor.extractText(tempFile);
          sessionTexts.add(extracted);
        } catch (e) {
          print('Text extraction failed for photo: $e');
          sessionTexts.add(''); // Add empty string if extraction fails
        }

        if (!mounted) return;
        setState(() {
          _isProcessingFile = false;
        });

        // Ask if user wants to capture more photos
        final shouldContinue = await _showCaptureMoreDialog(
          sessionPhotos.length,
        );
        if (shouldContinue == null || !shouldContinue) {
          continueCaptoring = false;
        }
      }

      if (sessionPhotos.isEmpty) return;

      // All photos captured, now process them
      setState(() {
        _capturedPhotos = sessionPhotos;
        _capturedPhotosText = sessionTexts;
        _selectedFile = null; // Clear single file selection
        _selectedFileText = null;
        _selectedFilePageCount = null;
        _selectedPages = [];
      });

      // Ask user for question settings
      final settings = await _showQuestionSettingsModal();
      if (settings == null) {
        // user cancelled; keep photos but do not generate
        return;
      }

      if (!mounted) return;
      setState(() {
        try {
          _selectedQuestionCount = (settings['questionCount'] as num).toInt();
        } catch (_) {}
        _selectedDifficulty =
            settings['difficulty']?.toString() ?? _selectedDifficulty;
      });

      await _generateQuizFromMultiplePhotos();
    } catch (e) {
      _showAlert('Hata', 'Kamera açılırken bir hata oluştu: $e');
    }
  }

  Future<bool?> _showCaptureMoreDialog(int currentCount) async {
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('${currentCount} fotoğraf çekildi'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text('Başka bir fotoğraf çekmek ister misiniz?'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Devam Et'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Başka Fotoğraf Çek'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateQuizFromMultiplePhotos() async {
    // Check authentication
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) {
      await Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => const AuthScreen(initialSignUp: true),
        ),
      );

      if (!mounted) return;
      final updatedAuth = Provider.of<AuthProvider>(context, listen: false);
      if (updatedAuth.user == null) {
        return;
      }
    }

    if (!mounted) return;

    // Combine all extracted text
    final combinedText = _capturedPhotosText
        .where((t) => t.trim().isNotEmpty)
        .join('\n\n');

    // For now, we'll send the first photo's path to use vision API
    // In a more advanced implementation, you could send all photos
    final firstPhotoPath = _capturedPhotos.isNotEmpty
        ? _capturedPhotos.first.path
        : null;

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => QuizGeneratorProgressScreen(
          inputText: combinedText.isEmpty
              ? 'Görsellerden soru oluştur'
              : combinedText,
          fileContent: combinedText.isEmpty ? null : combinedText,
          selectedPages: null,
          filePath: firstPhotoPath,
          originalFileName: firstPhotoPath != null
              ? 'camera_capture_${_capturedPhotos.length}_photos.jpg'
              : null,
          questionCount: _selectedQuestionCount,
          difficulty: _selectedDifficulty,
        ),
      ),
    );
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
