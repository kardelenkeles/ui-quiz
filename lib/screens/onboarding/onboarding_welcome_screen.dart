import 'package:flutter/material.dart';
import '../profile/auth_screen.dart';
import 'onboarding_feature_screen.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glitterController;
  late Animation<double> _glitterAnimation;

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
  }

  @override
  void dispose() {
    _glitterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          Container(
            color: Colors.transparent,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Progress indicator (dark on plain background)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == 0 ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? Colors.black
                              : Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 70),

                  // Text strip container - full width edge to edge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),

                    child: Column(
                      children: const [
                        // Small "Welcome to" text
                        Text(
                          'Welcome to',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w300,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        // Large app name
                        Text(
                          'Question AI',
                          style: TextStyle(
                            fontSize: 42,
                            color: Colors.black,
                            fontFamily: 'Montserrat',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        // Large app name
                        Text(
                          'The easiest way to ace your exams and master every subject.',
                          style: TextStyle(fontSize: 20, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App icon
                  Image.asset(
                    'asset/icon/appicon4.png',
                    width: 200,
                    height: 200,
                  ),

                  // Rest of content with horizontal padding
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const Spacer(),

                          // Primary action
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
                                                    ) =>
                                                        const OnboardingFeatureScreen(),
                                                transitionsBuilder:
                                                    (
                                                      context,
                                                      animation,
                                                      secondaryAnimation,
                                                      child,
                                                    ) {
                                                      const begin = Offset(
                                                        1.0,
                                                        0.0,
                                                      );
                                                      const end = Offset.zero;
                                                      const curve =
                                                          Curves.easeInOut;
                                                      var tween =
                                                          Tween(
                                                            begin: begin,
                                                            end: end,
                                                          ).chain(
                                                            CurveTween(
                                                              curve: curve,
                                                            ),
                                                          );
                                                      var offsetAnimation =
                                                          animation.drive(
                                                            tween,
                                                          );
                                                      return SlideTransition(
                                                        position:
                                                            offsetAnimation,
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
                                            shadowColor: Colors.lime
                                                .withOpacity(0.5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(26),
                                            ),
                                          ),
                                          child: const Text(
                                            'Let\'s Get Started!',
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
                                          borderRadius: BorderRadius.circular(
                                            26,
                                          ),
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
                                                    Colors.white.withOpacity(
                                                      0.3,
                                                    ),
                                                    Colors.white.withOpacity(
                                                      0.5,
                                                    ),
                                                    Colors.white.withOpacity(
                                                      0.3,
                                                    ),
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

                          const SizedBox(height: 16),

                          // Secondary: sign in if already have account
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AuthScreen(),
                                ),
                              );
                            },
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Already have an account? ',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                  TextSpan(
                                    text: 'Sign in',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
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
