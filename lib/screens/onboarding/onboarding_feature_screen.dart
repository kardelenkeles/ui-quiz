import 'package:flutter/material.dart';
import 'package:ui_quiz/screens/onboarding/paywall_screen.dart';

class OnboardingFeatureScreen extends StatefulWidget {
  const OnboardingFeatureScreen({super.key});

  @override
  State<OnboardingFeatureScreen> createState() =>
      _OnboardingFeatureScreenState();
}

class _OnboardingFeatureScreenState extends State<OnboardingFeatureScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _stackAnimation;
  late Animation<double> _processAnimation;
  late Animation<double> _quizAnimation;

  late AnimationController _glitterController;
  late Animation<double> _glitterAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );

    _stackAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.33, curve: Curves.easeOut),
      ),
    );

    _processAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.33, 0.66, curve: Curves.easeOut),
      ),
    );

    _quizAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    _glitterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _glitterAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _glitterController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _glitterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    // Progress indicator (dark on plain background)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        4,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == 1 ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == 1
                                ? Colors.black
                                : Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'How It Works',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Animated images container
                    Expanded(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Stack image (comes first)
                                Flexible(
                                  child: Transform.scale(
                                    scale: _stackAnimation.value,
                                    child: Opacity(
                                      opacity: _stackAnimation.value,
                                      child: Image.asset(
                                        'asset/icon/stack.png',
                                        width: 100,
                                        height: 100,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Process image (comes second)
                                Flexible(
                                  child: Transform.scale(
                                    scale: _processAnimation.value,
                                    child: Opacity(
                                      opacity: _processAnimation.value,
                                      child: Image.asset(
                                        'asset/icon/process.png',
                                        width: 100,
                                        height: 100,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Quiz image (comes third)
                                Flexible(
                                  child: Transform.scale(
                                    scale: _quizAnimation.value,
                                    child: Opacity(
                                      opacity: _quizAnimation.value,
                                      child: Image.asset(
                                        'asset/icon/quiz.png',
                                        width: 100,
                                        height: 100,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Turn Any File Into Smart Quizzes',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 42),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: AnimatedBuilder(
                        animation: _glitterAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
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
                                // Base button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
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
                                              ) => const PaywallScreen(),
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
                                                var tween =
                                                    Tween(
                                                      begin: begin,
                                                      end: end,
                                                    ).chain(
                                                      CurveTween(curve: curve),
                                                    );
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
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                    ),
                                    child: const Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                // Glitter effect overlay
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(26),
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
              // Back button positioned at top-left
              Positioned(
                top: 42,
                left: 6,
                child: Opacity(
                  opacity: 0.55,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.black,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(6),
                    splashRadius: 18,
                    splashColor: Colors.transparent,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
