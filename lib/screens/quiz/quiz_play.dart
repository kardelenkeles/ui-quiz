import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ui_quiz/widgets/custom_tab_bar.dart';
import 'package:add_to_cart_animation/add_to_cart_animation.dart';
import 'package:flutter/services.dart';
import 'package:ui_quiz/screens/quiz/quiz_result_screen.dart';

class QuizPlayScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? questions;
  final String? quizTitle;

  const QuizPlayScreen({super.key, this.questions, this.quizTitle});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen>
    with SingleTickerProviderStateMixin {
  // Add to cart animation için
  GlobalKey<CartIconKey> cartKey = GlobalKey<CartIconKey>();
  late Function(GlobalKey) runAddToCartAnimation;
  // Keys for each option widget to serve as animation sources
  late List<List<GlobalKey>> optionKeys;
  // Keys for hidden star widgets used as animation sources
  late List<List<GlobalKey>> starKeys;
  // visibility flags for the temporary star widgets
  late List<List<bool>> showStar;

  // ScrollController for options list
  late final ScrollController _scrollController;

  final List<Map<String, dynamic>> staticQuestions = [
    {
      'question':
          'Fluttergi programFFlutter hangi progi programFFlutter hangi proogramlama diliyle geliştirili diliyle geliştirili',
      'options': [
        {
          'letter': 'A.',
          'text':
              'Flutter hangi pi programlama diliyle i programlama diliyle i programlama diliyle i programlama diliyle',
        },
        {'letter': 'B.', 'text': 'Dart'},
        {'letter': 'C.', 'text': 'Kotlin'},
        {'letter': 'D.', 'text': 'Swift'},
      ],
      'correctAnswer': 'B.',
      'selectedAnswer': null,
    },
    {
      'question': 'Widget nedir?',
      'options': [
        {'letter': 'A', 'text': 'Bir programlama dili'},
        {'letter': 'B', 'text': 'Bir veritabanı'},
        {'letter': 'C', 'text': 'Flutter\'da UI bileşeni'},
        {'letter': 'D', 'text': 'Bir sunucu'},
      ],
      'correctAnswer': 'C',
      'selectedAnswer': null,
    },
    {
      'question': 'StatefulWidget ve StatelessWidget arasındaki fark nedir?',
      'options': [
        {'letter': 'A', 'text': 'Hiçbir fark yok'},
        {'letter': 'B', 'text': 'StatefulWidget durumu değişebilir'},
        {'letter': 'C', 'text': 'StatelessWidget daha hızlıdır'},
        {'letter': 'D', 'text': 'StatefulWidget sadece iOS\'ta çalışır'},
      ],
      'correctAnswer': 'B',
      'selectedAnswer': null,
    },
    {
      'question': 'Hot Reload özelliği ne işe yarar?',
      'options': [
        {'letter': 'A', 'text': 'Uygulamayı yeniden başlatır'},
        {'letter': 'B', 'text': 'Kodu anında günceller'},
        {'letter': 'C', 'text': 'Uygulamayı yayınlar'},
        {'letter': 'D', 'text': 'Hata ayıklar'},
      ],
      'correctAnswer': 'B',
      'selectedAnswer': null,
    },
    {
      'question': 'Hot Reload özelliği ne işe yarar?',
      'options': [
        {'letter': 'A', 'text': 'Uygulamayı yeniden başlatır'},
        {'letter': 'B', 'text': 'Kodu anında günceller'},
        {'letter': 'C', 'text': 'Uygulamayı yayınlar'},
        {'letter': 'D', 'text': 'Hata ayıklar'},
      ],
      'correctAnswer': 'B',
      'selectedAnswer': null,
    },
    {
      'question': 'Hot Reload özelliği ne işe yarar?',
      'options': [
        {'letter': 'A', 'text': 'Uygulamayı yeniden başlatır'},
        {'letter': 'B', 'text': 'Kodu anında günceller'},
        {'letter': 'C', 'text': 'Uygulamayı yayınlar'},
        {'letter': 'D', 'text': 'Hata ayıklar'},
      ],
      'correctAnswer': 'B',
      'selectedAnswer': null,
    },
    {
      'question': 'Hot Reload özelliği ne işe yarar?',
      'options': [
        {'letter': 'A', 'text': 'Uygulamayı yeniden başlatır'},
        {'letter': 'B', 'text': 'Kodu anında günceller'},
        {'letter': 'C', 'text': 'Uygulamayı yayınlar'},
        {'letter': 'D', 'text': 'Hata ayıklar'},
      ],
      'correctAnswer': 'B',
      'selectedAnswer': null,
    },
    {
      'question': 'Hot Reload özelliği ne işe yarar?',
      'options': [
        {'letter': 'A', 'text': 'Uygulamayı yeniden başlatır'},
        {'letter': 'B', 'text': 'Kodu anında günceller'},
        {'letter': 'C', 'text': 'Uygulamayı yayınlar'},
        {'letter': 'D', 'text': 'Hata ayıklar'},
      ],
      'correctAnswer': 'B',
      'selectedAnswer': null,
    },
    {
      'question': 'Hot Reload ne işe yarar?',
      'options': [
        {'letter': 'A', 'text': 'Uygulamayı yeniden başlatır'},
        {'letter': 'B', 'text': 'Kodu anında günceller'},
        {'letter': 'C', 'text': 'Uygulamayı yayınlar'},
        {'letter': 'D', 'text': 'Hata ayıklar'},
      ],
      'correctAnswer': 'B',
      'selectedAnswer': null,
    },
    {
      'question': 'Hot özelliği ne işe yarar?',
      'options': [
        {'letter': 'A', 'text': 'Uygulamayı yeniden başlatır'},
        {'letter': 'B', 'text': 'Kodu anında günceller'},
        {'letter': 'C', 'text': 'Uygulamayı yayınlar'},
        {'letter': 'D', 'text': 'Hata ayıklar'},
      ],
      'correctAnswer': 'B',
      'selectedAnswer': null,
    },
  ];

  int currentQuestionIndex = 0;
  bool _isBackPressed = false;
  bool _isForwardPressed = false;
  // current score shown in the nav bar
  int score = 0;

  @override
  void initState() {
    super.initState();

    // Initialize ScrollController
    _scrollController = ScrollController();

    // Use provided questions or fall back to default ones
    if (widget.questions != null) {
      // Clear existing data and update with new questions
      staticQuestions.clear();
      staticQuestions.addAll(widget.questions!);
    }

    // create a list of GlobalKeys for every option of every question
    optionKeys = staticQuestions.map<List<GlobalKey>>((q) {
      final opts = q['options'] as List;
      return List<GlobalKey>.generate(opts.length, (_) => GlobalKey());
    }).toList();
    // create star keys and visibility flags
    starKeys = staticQuestions.map<List<GlobalKey>>((q) {
      final opts = q['options'] as List;
      return List<GlobalKey>.generate(opts.length, (_) => GlobalKey());
    }).toList();

    showStar = staticQuestions.map<List<bool>>((q) {
      final opts = q['options'] as List;
      return List<bool>.generate(opts.length, (_) => false);
    }).toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AddToCartAnimation(
      cartKey: cartKey,
      height: 30,
      width: 30,
      opacity: 0.85,
      dragAnimation: const DragToCartAnimationOptions(rotation: true),
      jumpAnimation: const JumpAnimationOptions(),
      createAddToCartAnimation: (runAddToCartAnimation) {
        this.runAddToCartAnimation = runAddToCartAnimation;
      },
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          backgroundColor: CupertinoColors.systemBackground,
          border: null,
          leading: CupertinoButton(
            padding: const EdgeInsets.all(15),
            onPressed: () {
              _showExitConfirmation();
            },
            child: const Icon(
              CupertinoIcons.xmark,
              color: CupertinoColors.systemRed,
              size: 24,
            ),
          ),
          trailing: const SizedBox.shrink(),
        ),
        child: _buildStaticQuizUI(),
      ),
    );
  }

  Widget _buildStaticQuizUI() {
    final questionData = staticQuestions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / staticQuestions.length;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildLinearProgressBar(progress),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: CupertinoColors.systemGrey6.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    questionData['question'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label,
                      height: 1.4,
                      fontFamily: 'Nunito',
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  radius: const Radius.circular(8),
                  thickness: 3,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: (questionData['options'] as List).length,
                    itemBuilder: (context, index) {
                      final options =
                          questionData['options'] as List<Map<String, String>>;
                      final option = options[index];
                      final isSelected =
                          questionData['selectedAnswer'] == option['letter'];
                      final isCorrect =
                          questionData['correctAnswer'] == option['letter'];
                      final hasAnswered =
                          questionData['selectedAnswer'] != null;
                      final showCorrectAnswer =
                          hasAnswered && isCorrect && !isSelected;

                      return Container(
                        // narrow the option boxes by adding horizontal margins
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 26),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isCorrect
                                    ? CupertinoColors.systemGreen.withOpacity(
                                        0.15,
                                      )
                                    : CupertinoColors.systemRed.withOpacity(
                                        0.15,
                                      ))
                              : showCorrectAnswer
                              ? CupertinoColors.systemGreen.withOpacity(0.1)
                              : CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? (isCorrect
                                      ? CupertinoColors.systemGreen
                                      : CupertinoColors.systemRed)
                                : showCorrectAnswer
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemGrey4,
                            width: isSelected || showCorrectAnswer ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            if (!isSelected && !showCorrectAnswer)
                              BoxShadow(
                                color: CupertinoColors.systemGrey.withOpacity(
                                  0.1,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            if (isSelected || showCorrectAnswer)
                              BoxShadow(
                                color:
                                    (isCorrect
                                            ? CupertinoColors.systemGreen
                                            : CupertinoColors.systemRed)
                                        .withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            if (questionData['selectedAnswer'] == null) {
                              final isCorrectAnswer =
                                  option['letter'] ==
                                  questionData['correctAnswer'];

                              setState(() {
                                staticQuestions[currentQuestionIndex]['selectedAnswer'] =
                                    option['letter'];
                              });

                              // show the appropriate Lottie (happy or angry) briefly
                              setState(() {
                                showStar[currentQuestionIndex][index] = true;
                              });

                              // start behaviors after the widget has rendered
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (isCorrectAnswer) {
                                  // animate the happy star to the cart
                                  try {
                                    final starKey =
                                        starKeys[currentQuestionIndex][index];
                                    runAddToCartAnimation(starKey);
                                  } catch (e) {
                                    print('Add to cart animation error: $e');
                                  }

                                  // hide the lottie and update score after animation
                                  Future.delayed(
                                    const Duration(milliseconds: 600),
                                    () {
                                      if (mounted) {
                                        setState(() {
                                          showStar[currentQuestionIndex][index] =
                                              false;
                                          score += 10;
                                        });
                                      }
                                    },
                                  );
                                } else {
                                  // incorrect: show angry animation briefly then hide
                                  Future.delayed(
                                    const Duration(milliseconds: 2500),
                                    () {
                                      if (mounted) {
                                        setState(() {
                                          showStar[currentQuestionIndex][index] =
                                              false;
                                        });
                                      }
                                    },
                                  );
                                }
                              });
                            }
                          },
                          child: Container(
                            key: optionKeys[currentQuestionIndex][index],
                            width: double.infinity,
                            // slightly reduced padding for a more compact option box
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  option['letter']!,
                                  style: TextStyle(
                                    color: isSelected
                                        ? (isCorrect
                                              ? CupertinoColors.systemGreen
                                              : CupertinoColors.systemRed)
                                        : showCorrectAnswer
                                        ? CupertinoColors.systemGreen
                                        : CupertinoColors.label,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option['text']!,
                                    style: TextStyle(
                                      color: CupertinoColors.label,
                                      fontSize: 16,
                                      fontFamily: 'Nunito',
                                      fontWeight:
                                          isSelected || showCorrectAnswer
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                // Minimal custom container for feedback animation (Lottie)
                                Container(
                                  key: starKeys[currentQuestionIndex][index],
                                  margin: const EdgeInsets.only(left: 8),
                                  child: Opacity(
                                    opacity:
                                        showStar[currentQuestionIndex][index]
                                        ? 1.0
                                        : 0.0,
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.none,
                                        children: [
                                          // soft tinted circular background with subtle shadow
                                          AnimatedScale(
                                            scale:
                                                showStar[currentQuestionIndex][index]
                                                ? 1.0
                                                : 0.85,
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            curve: Curves.easeOutBack,
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: isCorrect
                                                    ? Colors.green.withOpacity(
                                                        0.12,
                                                      )
                                                    : Colors.red.withOpacity(
                                                        0.10,
                                                      ),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        (isCorrect
                                                                ? Colors.green
                                                                : Colors.red)
                                                            .withOpacity(0.12),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          // the Lottie artwork itself
                                          SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: Lottie.asset(
                                              isCorrect
                                                  ? 'asset/animations/Happy-Star.json'
                                                  : 'asset/animations/angry-star-2.json',
                                              repeat: isCorrect ? false : true,
                                              animate: true,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (isSelected || showCorrectAnswer)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color:
                                          (isCorrect
                                                  ? CupertinoColors.systemGreen
                                                  : CupertinoColors.systemRed)
                                              .withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isCorrect
                                          ? CupertinoIcons.check_mark
                                          : CupertinoIcons.xmark,
                                      color: isCorrect
                                          ? CupertinoColors.systemGreen
                                          : CupertinoColors.systemRed,
                                      size: 18,
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
              ),

              // Navigation ikonları
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50.0,
                  vertical: 50,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTapDown: currentQuestionIndex == 0
                          ? null
                          : (_) {
                              setState(() {
                                _isBackPressed = true;
                              });
                            },
                      onTapUp: currentQuestionIndex == 0
                          ? null
                          : (_) {
                              setState(() {
                                _isBackPressed = false;
                              });
                            },
                      onTapCancel: currentQuestionIndex == 0
                          ? null
                          : () {
                              setState(() {
                                _isBackPressed = false;
                              });
                            },
                      onTap: currentQuestionIndex == 0
                          ? null
                          : () {
                              setState(() {
                                currentQuestionIndex--;
                              });
                            },
                      child: AnimatedScale(
                        scale: _isBackPressed ? 0.85 : 1.0,
                        duration: const Duration(milliseconds: 50),
                        child: AnimatedOpacity(
                          opacity: _isBackPressed ? 0.6 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: Opacity(
                            opacity: currentQuestionIndex == 0 ? 0.3 : 1.0,
                            child: Image.asset(
                              'asset/icon/arrow-left.png',
                              width: 60,
                              height: 60,
                            ),
                          ),
                        ),
                      ),
                    ),
                    questionData['selectedAnswer'] == null
                        ? // Skip button when no answer is selected
                          GestureDetector(
                            onTapDown: (_) {
                              setState(() {
                                _isForwardPressed = true;
                              });
                            },
                            onTapUp: (_) {
                              setState(() {
                                _isForwardPressed = false;
                              });
                            },
                            onTapCancel: () {
                              setState(() {
                                _isForwardPressed = false;
                              });
                            },
                            onTap: () {
                              if (currentQuestionIndex ==
                                  staticQuestions.length - 1) {
                                _showStaticQuizResult();
                              } else {
                                setState(() {
                                  currentQuestionIndex++;
                                });
                              }
                            },
                            child: AnimatedScale(
                              scale: _isForwardPressed ? 0.85 : 1.0,
                              duration: const Duration(milliseconds: 100),
                              child: AnimatedOpacity(
                                opacity: _isForwardPressed ? 0.6 : 1.0,
                                duration: const Duration(milliseconds: 100),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey5,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: CupertinoColors.systemGrey4,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'Skip',
                                    style: TextStyle(
                                      decoration: TextDecoration.none,
                                      color: CupertinoColors.label,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : // Right arrow when answer is selected
                          GestureDetector(
                            onTapDown: (_) {
                              setState(() {
                                _isForwardPressed = true;
                              });
                            },
                            onTapUp: (_) {
                              setState(() {
                                _isForwardPressed = false;
                              });
                            },
                            onTapCancel: () {
                              setState(() {
                                _isForwardPressed = false;
                              });
                            },
                            onTap: () {
                              if (currentQuestionIndex ==
                                  staticQuestions.length - 1) {
                                _showStaticQuizResult();
                              } else {
                                setState(() {
                                  currentQuestionIndex++;
                                });
                              }
                            },
                            child: AnimatedScale(
                              scale: _isForwardPressed ? 0.85 : 1.0,
                              duration: const Duration(milliseconds: 100),
                              child: AnimatedOpacity(
                                opacity: _isForwardPressed ? 0.6 : 1.0,
                                duration: const Duration(milliseconds: 100),
                                child: Image.asset(
                                  currentQuestionIndex ==
                                          staticQuestions.length - 1
                                      ? 'asset/icon/complete.png'
                                      : 'asset/icon/arrow-right.png',
                                  width: 60,
                                  height: 60,
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
        // Question counter positioned at top-right
        Positioned(
          top: 10,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${currentQuestionIndex + 1} / ${staticQuestions.length}',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ),

        // AddToCartIcon target at bottom-right (invisible container target)
        Positioned(
          bottom: 20,
          right: 20,
          child: AddToCartIcon(
            key: cartKey,
            icon: Container(width: 1, height: 1, color: Colors.transparent),
            badgeOptions: const BadgeOptions(active: false),
          ),
        ),
      ],
    );
  }

  Widget _buildLinearProgressBar(double progress) {
    final totalWidth = MediaQuery.of(context).size.width - 90;

    return SizedBox(
      width: totalWidth,
      height: 80,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            width: totalWidth,
            height: 8,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 1),
                  width: totalWidth * progress,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF72F2F), Color(0xFFFF6F6F)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: (totalWidth * progress).clamp(0, totalWidth - 40),
            top: 15,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'asset/icon/pomegranate.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Quiz\'den Çık'),
        content: const Text(
          'Quiz\'den çıkmak istediğinizden emin misiniz? İlerlemeniz kaybolacak.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('İptal'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Çık'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(
                  builder: (context) => const CustomTabBarWidget(
                    initialIndex: 1,
                  ), // Quiz List tab'ı aç
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showStaticQuizResult() {
    int correctAnswers = 0;
    for (var question in staticQuestions) {
      if (question['selectedAnswer'] == question['correctAnswer']) {
        correctAnswers++;
      }
    }

    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (context) => QuizResultScreen(
          correctAnswers: correctAnswers,
          totalQuestions: staticQuestions.length,
          questions: staticQuestions,
          quizName: widget.quizTitle,
        ),
      ),
    );
  }
}
