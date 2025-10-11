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

// Ana QuizGeneratorScreen artık sadece CustomTabBarWidget'ı çağırıyor
class QuizGeneratorScreen extends StatefulWidget {
  const QuizGeneratorScreen({super.key});

  @override
  _QuizGeneratorScreenState createState() => _QuizGeneratorScreenState();
}

class _QuizGeneratorScreenState extends State<QuizGeneratorScreen> {
  // State fields used across the widget
  final TextEditingController _textController = TextEditingController();
  File? _selectedFile;
  String? _selectedFileText;
  int? _selectedFilePageCount;
  List<int> _selectedPages = [];
  final Map<int, Uint8List?> _previewCache = {};
  final int maxSelectable = 8;

  Future<void> _openPagePickerModal() async {
    if (_selectedFile == null) return;

    int pageCount = _selectedFilePageCount ?? 0;
    if (pageCount == 0) pageCount = 1;

    final maxSelectable = 8;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text('Sayfaları seçin (maks $maxSelectable)'),
                  const SizedBox(height: 8),

                  // Range slider for selecting a contiguous page interval. Applies immediately.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      children: [
                        StatefulBuilder(
                          builder: (context, setRangeState) {
                            final int safePageCount = pageCount < 1
                                ? 1
                                : pageCount;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Manual numeric inputs for start/end page selection
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue:
                                            (_selectedPages.isNotEmpty
                                                    ? _selectedPages.first
                                                    : 1)
                                                .toString(),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        decoration: const InputDecoration(
                                          labelText: 'Başlangıç',
                                        ),
                                        onChanged: (val) {
                                          setRangeState(() {
                                            final int parsed =
                                                int.tryParse(val) ?? 1;
                                            int start = parsed.clamp(
                                              1,
                                              safePageCount,
                                            );
                                            // ensure end not less than start
                                            int end = _selectedPages.isNotEmpty
                                                ? _selectedPages.last
                                                : start;
                                            if (end < start) end = start;
                                            final selCount = end - start + 1;
                                            if (selCount > maxSelectable) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Lütfen en fazla $maxSelectable sayfa seçin.',
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            }
                                            final rangeList =
                                                List<int>.generate(
                                                  end - start + 1,
                                                  (i) => start + i,
                                                );
                                            _selectedPages = rangeList
                                                .take(maxSelectable)
                                                .toList();
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue:
                                            (_selectedPages.isNotEmpty
                                                    ? _selectedPages.last
                                                    : safePageCount)
                                                .toString(),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        decoration: const InputDecoration(
                                          labelText: 'Bitiş',
                                        ),
                                        onChanged: (val) {
                                          setRangeState(() {
                                            final int parsed =
                                                int.tryParse(val) ??
                                                safePageCount;
                                            int end = parsed.clamp(
                                              1,
                                              safePageCount,
                                            );
                                            int start =
                                                _selectedPages.isNotEmpty
                                                ? _selectedPages.first
                                                : end;
                                            if (end < start) start = end;
                                            final selCount = end - start + 1;
                                            if (selCount > maxSelectable) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Lütfen en fazla $maxSelectable sayfa seçin.',
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            }
                                            final rangeList =
                                                List<int>.generate(
                                                  end - start + 1,
                                                  (i) => start + i,
                                                );
                                            _selectedPages = rangeList
                                                .take(maxSelectable)
                                                .toList();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Text(
                                    'Seçili aralık: ${_selectedPages.isEmpty ? 'Yok' : '${_selectedPages.first}-${_selectedPages.last} (${_selectedPages.length})'}',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.7,
                          ),
                      itemCount: pageCount,
                      itemBuilder: (context, index) {
                        final pageIndex = index + 1;
                        final bytes = _previewCache[pageIndex];

                        if (bytes == null) {
                          FileTextExtractor.getFilePreviewImage(
                            _selectedFile!,
                            page: pageIndex,
                            width: 300,
                          ).then((b) {
                            setModalState(() {
                              _previewCache[pageIndex] = b;
                            });
                          });
                        }

                        final selected = _selectedPages.contains(pageIndex);

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (selected) {
                                _selectedPages.remove(pageIndex);
                              } else {
                                if (_selectedPages.length < maxSelectable) {
                                  _selectedPages.add(pageIndex);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Maksimum sayfa seçimi aşıldı.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            });
                          },
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: selected
                                        ? Colors.blueAccent
                                        : Colors.grey.shade300,
                                    width: selected ? 3 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: bytes != null
                                    ? Image.memory(bytes, fit: BoxFit.cover)
                                    : const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: selected
                                      ? Colors.blue
                                      : Colors.white70,
                                  child: Text(
                                    '$pageIndex',
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 12,
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

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedPages = [];
                            });
                            Navigator.of(context).pop();
                          },
                          child: const Text('İptal'),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  _selectedPages = [];
                                });
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                              label: const Text('Hiçbiri'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  _selectedPages = List.generate(
                                    pageCount,
                                    (i) => i + 1,
                                  ).take(maxSelectable).toList();
                                });
                              },
                              icon: const Icon(Icons.select_all),
                              label: const Text('Hepsi'),
                            ),
                          ],
                        ),
                        // Close button (commit happens automatically)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.of(context).pop();
                          },
                          child: const Text('Kapat'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
        _showAlert('Bilgi', 'Dosya seçimi iptal edildi.');
      }
    } catch (e) {
      _hidePreviewPreparingDialog();
      _showAlert('Hata', 'Dosya seçimi sırasında bir hata oluştu: $e');
    }
  }

  void _showPreviewPreparingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Row(
            children: const [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(),
              ),
              SizedBox(width: 16),
              Expanded(child: Text('Önizleme hazırlanıyor...')),
            ],
          ),
        ),
      ),
    );
  }

  void _hidePreviewPreparingDialog() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
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
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: GestureDetector(
                                  onTap: () async {
                                    // Open preview picker if a file is selected
                                    if (_selectedFile != null) {
                                      await _openPagePickerModal();
                                    }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
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
                                      const SizedBox(width: 6),
                                      Image.asset(
                                        'asset/icon/folderfilled.png',
                                        width: 18,
                                        height: 18,
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
