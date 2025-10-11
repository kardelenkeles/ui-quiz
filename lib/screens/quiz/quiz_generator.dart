import 'dart:io';
import 'dart:typed_data';

import 'package:animated_button/animated_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_quiz/services/file_text_extractor.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:ui_quiz/screens/progress-indicator/quiz_generator_progress.dart';
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
  File? _selectedFile;
  String? _selectedFileText;
  int? _selectedFilePageCount;
  List<int> _selectedPages = [];
  final Map<int, Uint8List?> _previewCache = {};
  final int maxSelectable = 8;
  bool _isPreparingPreview = false;

  Future<void> _openPagePickerModal() async {
    if (_selectedFile == null) return;

    int pageCount = _selectedFilePageCount ?? 0;
    if (pageCount == 0) pageCount = 1;

    final maxSelectable = 8;

    final startController = TextEditingController(
      text: (_selectedPages.isNotEmpty ? _selectedPages.first : 1).toString(),
    );
    final endController = TextEditingController(
      text: (_selectedPages.isNotEmpty ? _selectedPages.last : pageCount)
          .toString(),
    );

    // Local modal copies to avoid mutating parent state while the picker is active
    List<int> modalSelectedPages = List<int>.from(_selectedPages);
    final modalPreviewCache = Map<int, Uint8List?>.from(_previewCache);

    try {
      final resultMap = await Navigator.of(context).push<Map<String, dynamic>>(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (_) => PagePickerScreen(
            selectedFile: _selectedFile!,
            pageCount: pageCount,
            initialSelectedPages: modalSelectedPages,
            initialPreviewCache: modalPreviewCache,
            maxSelectable: maxSelectable,
          ),
        ),
      );

      if (resultMap != null && resultMap['selectedPages'] != null) {
        final returnedPages = List<int>.from(
          resultMap['selectedPages'] as List,
        );
        final returnedCache = Map<int, Uint8List?>.from(
          resultMap['previewCache'] ?? {},
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectedPages = returnedPages;
            // merge returned cache into parent cache
            returnedCache.forEach((k, v) {
              if (v != null) _previewCache[k] = v;
            });
          });
        });
      }
    } finally {
      startController.dispose();
      endController.dispose();
    }
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
          _previewCache.clear();
        });

        // Show preview preparation indicator
        _showPreviewPreparingDialog();

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
            // Hide the preparing dialog before opening the modal
            _hidePreviewPreparingDialog();
            await _openPagePickerModal();
          } catch (_) {}
        } on MissingPluginException catch (e) {
          // Plugin not registered (common after hot-reload). Show retry/continue dialog.
          print('MissingPluginException during file extraction: $e');
          _hidePreviewPreparingDialog();
          _showExtractionErrorDialog();
        } catch (e) {
          // non-blocking: keep file but leave text null
          print('File extraction failed: $e');
          _hidePreviewPreparingDialog();
        }
      } else {
        // User cancelled file selection — silently ignore (no dialog)
      }
    } catch (e) {
      _hidePreviewPreparingDialog();
      _showAlert('Hata', 'Dosya seçimi sırasında bir hata oluştu: $e');
    }
  }

  void _showPreviewPreparingDialog() {
    if (!mounted) return;
    setState(() {
      _isPreparingPreview = true;
    });
  }

  void _hidePreviewPreparingDialog() {
    if (!mounted) return;
    setState(() {
      _isPreparingPreview = false;
    });
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

            // Overlay when preparing preview
            if (_isPreparingPreview)
              Positioned.fill(
                child: Container(
                  color: Colors.black38,
                  child: Center(
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 8),
                          ],
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.lime,
                            ),
                          ),
                        ),
                      ),
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
    _textController.dispose();
    super.dispose();
  }

  void _generateQuiz() {
    // Navigate to progress screen and pass selected pages/file
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => QuizGeneratorProgressScreen(
          inputText: _textController.text,
          fileContent: _selectedFileText,
          selectedPages: _selectedPages.isEmpty ? null : _selectedPages,
          filePath: _selectedFile?.path,
        ),
      ),
    );
  }
}
