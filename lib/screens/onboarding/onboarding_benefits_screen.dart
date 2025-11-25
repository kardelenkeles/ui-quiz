import 'package:flutter/material.dart';
import 'package:ui_quiz/screens/onboarding/onboarding_purpose_screen.dart';

class OnboardingBenefitsScreen extends StatefulWidget {
  const OnboardingBenefitsScreen({super.key});

  @override
  State<OnboardingBenefitsScreen> createState() =>
      _OnboardingBenefitsScreenState();
}

class _OnboardingBenefitsScreenState extends State<OnboardingBenefitsScreen>
    with TickerProviderStateMixin {
  late AnimationController _glitterController;
  late Animation<double> _glitterAnimation;

  late AnimationController _fadeController;
  late List<Animation<double>> _fadeAnimations;

  final List<Map<String, dynamic>> _benefits = [
    {
      'emoji': '✨',
      'title': 'AI-Powered',
      'description': 'Smart question generation',
    },
    {
      'emoji': '⚡',
      'title': 'Instant Results',
      'description': 'Get quizzes in seconds',
    },
    {
      'emoji': '📄',
      'title': 'Any Format',
      'description': 'PDF, Word, Excel, Photos',
    },
    {
      'emoji': '📤',
      'title': 'Easy Sharing',
      'description': 'Export as QCM or PDF',
    },
  ];

  @override
  void initState() {
    super.initState();

    _glitterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _glitterAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _glitterController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _fadeAnimations = List.generate(
      4,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(
            index * 0.15,
            (index * 0.15 + 0.4).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _glitterController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              children: [
                // Progress indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == 2 ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == 2
                            ? Colors.black
                            : Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 34),

                // Title
                const Text(
                  'Why Choose Question AI?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // Benefits list
                Expanded(
                  child: AnimatedBuilder(
                    animation: _fadeController,
                    builder: (context, child) {
                      return ListView.builder(
                        itemCount: _benefits.length,
                        itemBuilder: (context, index) {
                          return Opacity(
                            opacity: _fadeAnimations[index].value,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                (1 - _fadeAnimations[index].value) * 50,
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.lime[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _benefits[index]['emoji'],
                                          style: const TextStyle(fontSize: 32),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _benefits[index]['title'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _benefits[index]['description'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: AnimatedBuilder(
                    animation: _glitterAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.lime.withOpacity(0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) => const OnboardingPurposeScreen(),
                                      transitionsBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            const begin = Offset(1.0, 0.0);
                                            const end = Offset.zero;
                                            const curve = Curves.easeInOut;
                                            var tween = Tween(
                                              begin: begin,
                                              end: end,
                                            ).chain(CurveTween(curve: curve));
                                            var offsetAnimation = animation
                                                .drive(tween);
                                            return SlideTransition(
                                              position: offsetAnimation,
                                              child: child,
                                            );
                                          },
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lime[400],
                                  foregroundColor: Colors.black,
                                  elevation: 8,
                                  shadowColor: Colors.lime.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Transform.translate(
                                  offset: Offset(
                                    _glitterAnimation.value * 200,
                                    0,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withOpacity(0.3),
                                          Colors.white.withOpacity(0.5),
                                          Colors.white.withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                        stops: const [
                                          0.0,
                                          0.35,
                                          0.5,
                                          0.65,
                                          1.0,
                                        ],
                                      ),
                                    ),
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

                const SizedBox(height: 72),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
