import 'package:flutter/material.dart';
import 'package:ui_quiz/screens/onboarding/paywall_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Tired of endless notes and flashcards?",
      description: "Unlock smarter, faster learning with QuizGenie.",
      image: "asset/icon/unnamed.png",
      color: Colors.purple,
      emoji: "📚",
    ),
    OnboardingPage(
      title: "Mastery through practice",
      description: "Review, retry, and conquer your knowledge gaps",
      image: "asset/icon/mobile-in-hand.png",
      color: Colors.purple,
      emoji: "🧠",
    ),
    OnboardingPage(
      title: "Input anything. AI understands",
      description:
          "Notes, articles, web links, even voice notes. Our AI processes it all",
      image: "asset/icon/ai-file.png",
      color: Colors.purple,
      emoji: "🎤",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => _goToPaywall(),
                child: Text(
                  'Skip',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated icon container with image
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1200),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            // Combine multiple effects: scale, rotate, fade, and slide
                            return Transform.translate(
                              offset: Offset(0, -30 * (1 - value)),
                              child: Transform.rotate(
                                angle: (value * 0.15), // Slight rotation
                                child: Transform.scale(
                                  scale: 0.6 + (value * 0.4),
                                  child: Opacity(opacity: value, child: child),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: page.color.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(page.image, fit: BoxFit.cover),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Title with animation
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            page.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontFamily: 'Nunito',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Description with animation
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            page.description,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.6,
                              fontFamily: 'Nunito',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.lime
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Next/Continue button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    } else {
                      _goToPaywall();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lime,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1
                        ? 'Continue'
                        : 'Get Started',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _goToPaywall() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PaywallScreen()),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  final Color color;
  final String emoji;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
    required this.emoji,
  });
}
