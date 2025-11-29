import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/new_quiz_provider.dart';
import 'package:ui_quiz/widgets/custom_tab_bar.dart';
import 'package:ui_quiz/screens/quiz/quiz_play.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class QuizResultScreen extends StatefulWidget {
  final int correctAnswers;
  final int totalQuestions;
  final List<Map<String, dynamic>> questions;
  final String? quizName;
  final bool isFromHistory;

  const QuizResultScreen({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.questions,
    this.quizName,
    this.isFromHistory = false,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late final ScrollController _scrollController;
  bool _hasBeenSaved = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Quiz sonucunu kaydet (sadece yeni quiz'ler için, history'den gelenler için değil)
    if (!widget.isFromHistory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _saveQuizResult();
      });
    }
  }

  Future<void> _saveQuizResult() async {
    if (_hasBeenSaved) return; // Zaten kaydedildiyse tekrar kaydetme

    try {
      _hasBeenSaved = true; // Flag'i set et
      final provider = Provider.of<NewQuizProvider>(context, listen: false);

      // Quiz sonucunu kaydet
      await provider.saveQuizResult(
        quizTitle: widget.quizName ?? 'Quiz',
        questions: widget.questions,
        correctAnswers: widget.correctAnswers,
        totalQuestions: widget.totalQuestions,
      );

      print('Quiz result saved successfully');
    } catch (e) {
      _hasBeenSaved = false; // Hata durumunda flag'i reset et
      print('Error saving quiz result: $e');
    }
  }

  /// Quiz ismini kısalt
  String _getShortQuizName() {
    if (widget.quizName == null) return 'PomeAI Quiz';

    final words = widget.quizName!.trim().split(' ');

    // İlk 2-3 kelimeyi al
    if (words.length <= 5) {
      return widget.quizName!;
    }

    return words.take(3).join(' ');
  }

  Future<void> _printQuizResult() async {
    final pdf = pw.Document();

    final successRate = (widget.correctAnswers / widget.totalQuestions * 100)
        .toStringAsFixed(0);
    // Load embedded font to support Turkish characters
    final regularFontData = await rootBundle.load(
      'asset/fonts/Nunito-Regular.ttf',
    );
    final boldFontData = await rootBundle.load('asset/fonts/Nunito-Bold.ttf');
    final ttf = pw.Font.ttf(regularFontData);
    final ttfBold = pw.Font.ttf(boldFontData);

    // Load small icons for PDF (avoid relying on glyph availability)
    final trueIconData = await rootBundle.load('asset/icon/true.png');
    final wrongIconData = await rootBundle.load('asset/icon/wrong.png');
    final circleIconData = await rootBundle.load('asset/icon/circle.png');
    final trueIcon = pw.MemoryImage(trueIconData.buffer.asUint8List());
    final wrongIcon = pw.MemoryImage(wrongIconData.buffer.asUint8List());
    final circleIcon = pw.MemoryImage(circleIconData.buffer.asUint8List());

    final titleStyle = pw.TextStyle(font: ttfBold, fontSize: 18);
    final metaStyle = pw.TextStyle(
      font: ttf,
      fontSize: 12,
      color: PdfColors.grey700,
    );
    final questionStyle = pw.TextStyle(font: ttfBold, fontSize: 12);
    final optionStyle = pw.TextStyle(
      font: ttf,
      fontSize: 11,
      color: PdfColors.grey800,
    );
    final correctStyle = pw.TextStyle(
      font: ttf,
      fontSize: 11,
      color: PdfColors.green700,
    );
    final wrongStyle = pw.TextStyle(
      font: ttf,
      fontSize: 11,
      color: PdfColors.red700,
    );

    // Use provider title if available
    final provider = Provider.of<NewQuizProvider>(context, listen: false);
    final titleForPdf = (provider.currentQuizTitle.isNotEmpty)
        ? provider.currentQuizTitle
        : _getShortQuizName();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Center(child: pw.Text(titleForPdf, style: titleStyle)),
          pw.SizedBox(height: 8),
          pw.Text(
            'Skor: $successRate% (${widget.correctAnswers}/${widget.totalQuestions})',
            style: metaStyle,
          ),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 8),

          // Questions list with options
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: List.generate(widget.questions.length, (index) {
              final q = widget.questions[index];
              final questionText = (q['question'] ?? '').toString();
              final selected = (q['selectedAnswer'] ?? '').toString();
              final correct = (q['correctAnswer'] ?? '').toString();
              final options = (q['options'] as List?) ?? <dynamic>[];

              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${index + 1}. $questionText',
                      style: questionStyle,
                    ),
                    pw.SizedBox(height: 6),

                    // Options
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: List.generate(options.length, (optIndex) {
                        final opt = options[optIndex] as Map<String, dynamic>;
                        final letter = (opt['letter'] ?? '').toString();
                        final text = (opt['text'] ?? '').toString();
                        final isSelected = letter == selected;
                        final isCorrect = letter == correct;

                        // choose icon and style
                        pw.Widget iconWidget = pw.Image(
                          circleIcon,
                          width: 10,
                          height: 10,
                        );
                        pw.TextStyle useStyle = optionStyle;
                        if (isCorrect) {
                          iconWidget = pw.Image(
                            trueIcon,
                            width: 12,
                            height: 12,
                          );
                          useStyle = correctStyle;
                        } else if (isSelected && !isCorrect) {
                          iconWidget = pw.Image(
                            wrongIcon,
                            width: 12,
                            height: 12,
                          );
                          useStyle = wrongStyle;
                        }

                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                width: 22,
                                child: pw.Text('$letter.', style: optionStyle),
                              ),
                              pw.SizedBox(width: 6),
                              pw.Expanded(
                                child: pw.Row(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Container(
                                      width: 18,
                                      alignment: pw.Alignment.topLeft,
                                      child: iconWidget,
                                    ),
                                    pw.SizedBox(width: 6),
                                    pw.Expanded(
                                      child: pw.Text(text, style: useStyle),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),

                    // small divider between questions
                    pw.SizedBox(height: 6),
                    pw.Divider(),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );

    final pdfBytes = await pdf.save();

    // Create a filesystem-safe filename from quiz name
    String _safeFileName(String name) {
      return name
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
    }

    final fileName = '${_safeFileName(titleForPdf)}.pdf';

    try {
      // Save PDF to application documents directory
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Optionally inform the user (print to console for now)
      print('Saved PDF to: ${file.path}');

      // Open the platform print dialog using the same bytes
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      // Fallback to share if saving or printing failed
      print('Error saving or printing PDF: $e');
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final successRate = (widget.correctAnswers / widget.totalQuestions * 100);
    final isSuccess = successRate >= 70;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          if (isSuccess)
            Positioned.fill(
              child: Lottie.asset(
                'asset/animations/Confetti.json',
                repeat: true,
                animate: true,
                fit: BoxFit.cover,
              ),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Quiz adı
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      _getShortQuizName(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                        decoration: TextDecoration.none,
                        fontFamily: 'Nunito',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Skor kartı
                  Container(
                    width: 320,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? CupertinoColors.systemGreen.withOpacity(0.1)
                          : CupertinoColors.systemOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSuccess
                            ? CupertinoColors.systemGreen
                            : CupertinoColors.systemOrange,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSuccess
                                    ? 'Tebrikler! 🎉'
                                    : 'Daha İyi Olabilir! 💪',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.label,
                                  decoration: TextDecoration.none,
                                  fontFamily: 'Nunito',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.correctAnswers} / ${widget.totalQuestions} doğru',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: CupertinoColors.secondaryLabel,
                                  decoration: TextDecoration.none,
                                  fontFamily: 'Nunito',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSuccess
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemOrange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${successRate.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.white,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cevaplar listesi - Expanded ile kalan alanı kapla
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      radius: const Radius.circular(8),
                      thickness: 2,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: widget.questions.length,
                        itemBuilder: (context, index) {
                          final question = widget.questions[index];
                          final isCorrect =
                              question['selectedAnswer'] ==
                              question['correctAnswer'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 30,
                                      ),
                                      height: 40,
                                      alignment: Alignment.center,
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Text(
                                        '${index + 1}',
                                        style: CupertinoTheme.of(context)
                                            .textTheme
                                            .textStyle
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              fontFamily: 'Nunito',
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                Flexible(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: 2,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            question['question'],
                                            style: CupertinoTheme.of(context)
                                                .textTheme
                                                .textStyle
                                                .copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.3,
                                                  color: Colors.grey[800],
                                                  fontFamily: 'Nunito',
                                                ),
                                          ),
                                          const SizedBox(height: 5),
                                          ...((question['options'] as List).map<
                                            Widget
                                          >((option) {
                                            final isSelected =
                                                option['letter'] ==
                                                question['selectedAnswer'];
                                            final isCorrectOption =
                                                option['letter'] ==
                                                question['correctAnswer'];

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    isCorrectOption
                                                        ? 'asset/icon/true.png'
                                                        : isSelected
                                                        ? 'asset/icon/wrong.png'
                                                        : 'asset/icon/circle.png',
                                                    width: 20,
                                                    height: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      '${option['letter']} ${option['text']}',
                                                      style: TextStyle(
                                                        fontFamily: 'Nunito',
                                                        decoration:
                                                            TextDecoration.none,
                                                        fontSize: 15,
                                                        color: isCorrectOption
                                                            ? Colors.green
                                                            : isSelected
                                                            ? CupertinoColors
                                                                  .systemRed
                                                            : Colors.grey[800],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList()),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Image.asset(
                                        isCorrect
                                            ? 'asset/icon/true.png'
                                            : 'asset/icon/wrong.png',
                                        width: 35,
                                        height: 35,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Compact action row: Retry / Home / Print
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Retry
                        SizedBox(
                          width: 120,
                          height: 44,
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              // Retry: start the same quiz again with a fresh copy
                              final provider = Provider.of<NewQuizProvider>(
                                context,
                                listen: false,
                              );

                              final freshQuestions = widget.questions
                                  .map<Map<String, dynamic>>((q) {
                                    final copied = Map<String, dynamic>.from(q);
                                    copied['selectedAnswer'] = null;
                                    if (copied['options'] is List) {
                                      copied['options'] =
                                          (copied['options'] as List)
                                              .map<Map<String, dynamic>>(
                                                (opt) =>
                                                    Map<String, dynamic>.from(
                                                      opt,
                                                    ),
                                              )
                                              .toList();
                                    }
                                    return copied;
                                  })
                                  .toList();

                              Navigator.of(context).pushReplacement(
                                CupertinoPageRoute(
                                  builder: (context) => QuizPlayScreen(
                                    questions: freshQuestions,
                                    quizTitle:
                                        provider.currentQuizTitle.isNotEmpty
                                        ? provider.currentQuizTitle
                                        : widget.quizName,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Tekrar',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Nunito',
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Home (only show when not opened from history)
                        if (!widget.isFromHistory) ...[
                          SizedBox(
                            width: 120,
                            height: 44,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        const CustomTabBarWidget(
                                          initialIndex: 0,
                                        ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Ana Sayfa',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Nunito',
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],

                        // Print icon button (asset)
                        GestureDetector(
                          onTap: _printQuizResult,
                          child: Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: CupertinoColors.activeBlue,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Image.asset(
                                'asset/icon/printer.png',
                                color: Colors.white,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
