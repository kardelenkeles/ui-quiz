import 'package:flutter/material.dart';
import 'package:ui_quiz/screens/onboarding/paywall_screen.dart';

class OnboardingPurposeScreen extends StatefulWidget {
  const OnboardingPurposeScreen({super.key});

  @override
  State<OnboardingPurposeScreen> createState() =>
      _OnboardingPurposeScreenState();
}

class _OnboardingPurposeScreenState extends State<OnboardingPurposeScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedPurpose;
  late AnimationController _glitterController;
  late Animation<double> _glitterAnimation;

  final List<Map<String, dynamic>> _purposes = [
    {
      'id': 'study',
      'emoji': '📚',
      'title': 'Study & Learn',
      'description': 'Prepare for exams and tests',
    },
    {
      'id': 'teaching',
      'emoji': '👨‍🏫',
      'title': 'Teaching',
      'description': 'Create quizzes for students',
    },
    {
      'id': 'work',
      'emoji': '💼',
      'title': 'Work & Training',
      'description': 'Professional development',
    },
    {
      'id': 'fun',
      'emoji': '🎮',
      'title': 'Just for Fun',
      'description': 'Test your knowledge',
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
                      width: index == 3 ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == 3
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
                  'What will you use\nQuestion AI for?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Purpose options
                Expanded(
                  child: ListView.builder(
                    itemCount: _purposes.length,
                    itemBuilder: (context, index) {
                      final purpose = _purposes[index];
                      final isSelected = _selectedPurpose == purpose['id'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPurpose = purpose['id'];
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.lime[400]!
                                  : Colors.grey[200]!,
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? Colors.lime.withOpacity(0.15)
                                    : Colors.black.withOpacity(0.08),
                                blurRadius: isSelected ? 15 : 20,
                                offset: Offset(0, isSelected ? 4 : 8),
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
                                  color: isSelected
                                      ? Colors.lime[100]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    purpose['emoji'],
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      purpose['title'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      purpose['description'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.lime[400],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                ),
                            ],
                          ),
                        ),
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
                          boxShadow: _selectedPurpose != null
                              ? [
                                  BoxShadow(
                                    color: Colors.lime.withOpacity(0.6),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: Stack(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: _selectedPurpose == null
                                    ? null
                                    : () {
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
                                                      animation.drive(tween);
                                                  return SlideTransition(
                                                    position: offsetAnimation,
                                                    child: child,
                                                  );
                                                },
                                          ),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedPurpose != null
                                      ? Colors.lime[400]
                                      : Colors.grey[300],
                                  foregroundColor: Colors.black,
                                  elevation: _selectedPurpose != null ? 8 : 0,
                                  shadowColor: Colors.lime.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
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
                            if (_selectedPurpose != null)
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

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
