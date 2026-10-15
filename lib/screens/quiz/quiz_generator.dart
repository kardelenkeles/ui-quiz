import 'package:animated_button/animated_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_quiz/services/file_text_extractor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/auth_provider.dart';
import 'package:ui_quiz/providers/new_quiz_provider.dart';
import 'package:ui_quiz/screens/profile/auth_screen.dart';
import 'package:ui_quiz/screens/quiz/page_picker_screen.dart';
import 'package:ui_quiz/screens/quiz/quiz_questions_review.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';
import 'package:ui_quiz/core/app_logger.dart';

part 'quiz_generator_view.dart';

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
  const _QuizGeneratorView();

  @override
  _QuizGeneratorViewState createState() => _QuizGeneratorViewState();
}

class _QuizGeneratorViewState extends State<_QuizGeneratorView> {
  void _refresh(VoidCallback update) => setState(update);

  // State fields used across the widget
  final TextEditingController _textController = TextEditingController();
  bool _textHasContent = false;
  XFile? _selectedFile;
  String? _selectedFileText;
  int? _selectedFilePageCount;
  List<int> _selectedPages = [];
  int _selectedQuestionCount = 10;
  String _selectedDifficulty = 'mid';
  bool _isProcessingFile = false;
  bool _isUploadingFile = false;
  final int maxSelectable = 8;

  // Multiple camera photos support
  List<XFile> _capturedPhotos = [];
  List<String> _capturedPhotosText = [];

  // Progress tracking for quiz generation
  bool _isGeneratingQuiz = false;
  int _currentStep = 0;
  final List<String> _loadingTexts = [
    'Analyzing text...',
    'Creating questions...',
    'Preparing answer choices...',
    'Determining correct answers...',
    'Finalizing quiz...',
  ];

  Future<Map<String, dynamic>?> _openPagePickerModal() async {
    if (_selectedFile == null) return null;

    int pageCount = _selectedFilePageCount ?? 0;
    if (pageCount == 0) pageCount = 1;

    final maxSelectable = 30;

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
        withData: true,
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
        final selectedFile = file.bytes != null
            ? XFile.fromData(file.bytes!, name: file.name)
            : XFile(file.path!, name: file.name);
        setState(() {
          _selectedFile = selectedFile;
          _selectedFileText = null; // will fill after extraction
          _selectedFilePageCount = null;
          _selectedPages = [];
          _isProcessingFile = true;
        });

        // Extract text asynchronously and store it
        try {
          final extracted = await FileTextExtractor.extractText(selectedFile);
          setState(() {
            _selectedFileText = extracted;
          });
          // Try to get page count (PDF/PPTX)
          try {
            final count = await FileTextExtractor.getPageCount(selectedFile);
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
              if (!mounted) return;
              final settings = await _showQuestionSettingsModal();
              if (!mounted) return;
              if (settings == null) {
                // user cancelled; keep file selected but do not generate
                return;
              }
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
              if (!mounted) return;
              final pickerResult = await _openPagePickerModal();
              if (!mounted) return;
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
                if (!mounted) return;
                final settings = await _showQuestionSettingsModal();
                if (!mounted) return;
                if (settings == null) {
                  // user cancelled; keep selection but abort generation
                  return;
                }
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
          AppLogger.debug('MissingPluginException during file extraction: $e');
          _showExtractionErrorDialog();
        } catch (e) {
          // non-blocking: keep file but leave text null
          AppLogger.debug('XFile extraction failed: $e');
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
            child: const Text('OK'),
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
  Widget build(BuildContext context) => buildQuizGeneratorView(context);

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
      List<XFile> sessionPhotos = [];
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

        final tempFile = photo;
        sessionPhotos.add(tempFile);

        setState(() {
          _isProcessingFile = true;
        });

        // Extract text from this photo
        try {
          final extracted = await FileTextExtractor.extractText(tempFile);
          sessionTexts.add(extracted);
        } catch (e) {
          AppLogger.debug('Text extraction failed for photo: $e');
          sessionTexts.add(''); // Add empty string if extraction fails
        }

        if (!mounted) return;
        setState(() {
          _isProcessingFile = false;
        });

        // Automatically stop after first photo
        continueCaptoring = false;
      }

      if (sessionPhotos.isEmpty) return;

      // All photos captured, now process them
      if (!mounted) return;
      setState(() {
        _capturedPhotos = sessionPhotos;
        _capturedPhotosText = sessionTexts;
        _selectedFile = null; // Clear single file selection
        _selectedFileText = null;
        _selectedFilePageCount = null;
        _selectedPages = [];
      });

      // Don't ask for settings automatically, just show the photos
    } catch (e) {
      _showAlert('Hata', 'Kamera açılırken bir hata oluştu: $e');
    }
  }

  Future<void> _addMorePhotos() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (photo == null) return;

      final tempFile = photo;

      setState(() {
        _isProcessingFile = true;
      });

      // Extract text from this photo
      String extractedText = '';
      try {
        extractedText = await FileTextExtractor.extractText(tempFile);
      } catch (e) {
        AppLogger.debug('Text extraction failed for photo: $e');
      }

      if (!mounted) return;
      setState(() {
        _capturedPhotos.add(tempFile);
        _capturedPhotosText.add(extractedText);
        _isProcessingFile = false;
      });
    } catch (e) {
      _showAlert('Hata', 'Kamera açılırken bir hata oluştu: $e');
    }
  }

  void _updateStep(int step) {
    if (mounted && step != _currentStep) {
      setState(() {
        // Allow step values from 0 up to _loadingTexts.length (final step)
        _currentStep = step.clamp(0, _loadingTexts.length);
      });
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
            final brandColor = Colors.lime;
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
                                if (localCount > 1) {
                                  setModalState(() => localCount--);
                                }
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
                                if (localCount < 20) {
                                  setModalState(() => localCount++);
                                }
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

    // User signed in
    if (!mounted) return;

    // If user pasted text (no file), ask for question settings first
    if (_selectedFile == null && _textController.text.trim().isNotEmpty) {
      if (!mounted) return;
      final settings = await _showQuestionSettingsModal();
      if (!mounted) return;
      if (settings == null) return; // user cancelled
      setState(() {
        try {
          _selectedQuestionCount = (settings['questionCount'] as num).toInt();
        } catch (_) {}
        _selectedDifficulty =
            settings['difficulty']?.toString() ?? _selectedDifficulty;
      });
    }

    // If user has captured photos, ask for settings
    if (_capturedPhotos.isNotEmpty) {
      if (!mounted) return;
      final settings = await _showQuestionSettingsModal();
      if (!mounted) return;
      if (settings == null) return; // user cancelled
      setState(() {
        try {
          _selectedQuestionCount = (settings['questionCount'] as num).toInt();
        } catch (_) {}
        _selectedDifficulty =
            settings['difficulty']?.toString() ?? _selectedDifficulty;
      });

      // Generate quiz from multiple photos
      final combinedText = _capturedPhotosText
          .where((t) => t.trim().isNotEmpty)
          .join('\n\n');

      await _generateQuizWithOverlay(
        inputText: combinedText.isEmpty
            ? 'Görsellerden soru oluştur'
            : combinedText,
        fileContent: combinedText.isEmpty ? null : combinedText,
        selectedPages: null,
        filePath: _capturedPhotos.isNotEmpty
            ? _capturedPhotos.first.path
            : null,
        originalFileName: _capturedPhotos.isNotEmpty
            ? 'camera_capture_${_capturedPhotos.length}_photos.jpg'
            : null,
      );
      return;
    }

    await _generateQuizWithOverlay(
      inputText: _textController.text,
      fileContent: _selectedFileText,
      selectedPages: _selectedPages.isEmpty ? null : _selectedPages,
      filePath: _selectedFile?.path,
      originalFileName: _selectedFile?.name,
    );
  }

  Future<void> _generateQuizWithOverlay({
    required String inputText,
    String? fileContent,
    List<int>? selectedPages,
    String? filePath,
    String? originalFileName,
  }) async {
    try {
      // Show progress overlay
      setState(() {
        _isGeneratingQuiz = true;
        _currentStep = 1; // Start at step 1: Analyzing
      });

      // Short initial pause so UI updates visibly
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      final provider = Provider.of<NewQuizProvider>(context, listen: false);

      String? processedFileContent = fileContent;

      // Step 2: Creating questions (if extracting from pages)
      if ((selectedPages?.isNotEmpty ?? false) && filePath != null) {
        try {
          _updateStep(2); // Creating questions
          final f = XFile(filePath);
          processedFileContent = await FileTextExtractor.extractText(
            f,
            pages: selectedPages,
          );
        } catch (e) {
          // fallback to provided fileContent
        }
      }

      bool success = false;
      try {
        if (mounted) setState(() => _isUploadingFile = true);
        success = await provider.generateQuiz(
          topic: inputText,
          questionCount: _selectedQuestionCount,
          difficulty: _selectedDifficulty,
          fileContent: processedFileContent,
          originalFileName: originalFileName,
          filePath: filePath,
          onProgress: (accumulated, total) {
            if (!mounted) return;
            // Map accumulated/total questions to progress steps
            // Steps: 1=Analyzing, 2=Creating, 3=Preparing, 4=Determining, 5=Finalizing
            // Map progress smoothly from steps 2-4 during generation
            if (total > 0) {
              final progress = accumulated / total;
              // Progress mapping:
              // 0% (start) -> step 2 (Creating)
              // 1-50% -> step 3 (Preparing)
              // 51-99% -> step 4 (Determining)
              // 100% will be set to step 5 manually after completion
              int newStep;
              if (progress >= 0.5) {
                newStep = 4; // Determining correct answers
              } else if (accumulated > 0) {
                newStep = 3; // Preparing answer choices
              } else {
                newStep = 2; // Creating questions
              }
              _updateStep(newStep);
            }
          },
        );
      } finally {
        if (mounted) setState(() => _isUploadingFile = false);
      }

      if (mounted) {
        // Step 5: Finalizing quiz
        _updateStep(5);

        // Brief pause so user perceives completion
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;

        setState(() {
          _isGeneratingQuiz = false;
          _currentStep = 0;
        });

        if (!success || provider.error.isNotEmpty) {
          _showAlert(
            'Error',
            provider.error.isEmpty
                ? 'An unknown error occurred'
                : provider.error,
          );
        } else {
          // Navigate to review screen
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => QuizQuestionsReviewScreen(
                questions: provider.currentQuestions,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingQuiz = false;
          _currentStep = 0;
        });
        _showAlert('Error', 'An error occurred while creating quiz: $e');
      }
    }
  }
}
