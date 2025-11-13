import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/auth_provider.dart';
import 'package:ui_quiz/screens/profile/auth_screen.dart';
import 'package:ui_quiz/screens/onboarding/payment_screen.dart';
import 'package:ui_quiz/widgets/custom_tab_bar.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;
  bool _showCloseButton = false;
  bool _showXButton = false; // For close button when logged in

  String _selectedPlan = 'yearly'; // 'weekly' or 'yearly'
  final double _weeklyPrice = 249.99; // TRY
  final double _yearlyPrice = 5000.00; // TRY
  final double _originalYearlyPrice =
      9000.00; // Original price for discount calculation

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showCloseButton = true;
          _showXButton = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.user != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Sign in button (only show if not logged in) OR close button (if logged in)
                  if (!isLoggedIn)
                    TextButton(
                      onPressed: _showCloseButton
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AuthScreen(),
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        'SIGN IN',
                        style: TextStyle(
                          color: _showCloseButton
                              ? Colors.black87
                              : Colors.transparent,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    )
                  else if (_showXButton)
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const CustomTabBarWidget(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.close),
                      color: Colors.black87,
                      iconSize: 24,
                    ),
                  const Spacer(),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const SizedBox(height: 8),

                      // Title
                      const Text(
                        "Unlock Premium Features",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Nunito',
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      // Premium features in compact cards
                      _buildPremiumFeatureCard(
                        gradient: [
                          Colors.purple.shade400,
                          Colors.purple.shade700,
                        ],
                        icon: Icons.auto_awesome,
                        emoji: '✨',
                        title: "Unlimited Quizzes",
                        description: "Create endless AI-powered quizzes",
                      ),
                      const SizedBox(height: 8),
                      _buildPremiumFeatureCard(
                        gradient: [Colors.blue.shade400, Colors.blue.shade700],
                        icon: Icons.camera_alt,
                        emoji: '📸',
                        title: "Multi-Format Upload",
                        description: "Photos, PDFs, Word, Excel & more",
                      ),
                      const SizedBox(height: 8),
                      _buildPremiumFeatureCard(
                        gradient: [
                          Colors.orange.shade400,
                          Colors.orange.shade700,
                        ],
                        icon: Icons.refresh,
                        emoji: '🔄',
                        title: "Retake & Share",
                        description: "Retry quizzes & export as QCM/PDF",
                      ),
                      const SizedBox(height: 8),
                      _buildPremiumFeatureCard(
                        gradient: [
                          Colors.green.shade400,
                          Colors.green.shade700,
                        ],
                        icon: Icons.block,
                        emoji: '🚀',
                        title: "Ad-Free Experience",
                        description: "Pure learning, zero distractions",
                      ),

                      const SizedBox(height: 16),
                      // Pricing selection
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey.shade50, Colors.white],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'asset/icon/diamond.png',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "SELECT YOUR PLAN",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Nunito',
                                    color: Colors.black87,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Weekly option
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedPlan = 'weekly'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  gradient: _selectedPlan == 'weekly'
                                      ? LinearGradient(
                                          colors: [
                                            Colors.lime.withOpacity(0.15),
                                            Colors.lime.withOpacity(0.05),
                                          ],
                                        )
                                      : null,
                                  color: _selectedPlan == 'weekly'
                                      ? null
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedPlan == 'weekly'
                                        ? Colors.lime
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  boxShadow: _selectedPlan == 'weekly'
                                      ? [
                                          BoxShadow(
                                            color: Colors.lime.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_today,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Weekly',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Nunito',
                                            ),
                                          ),
                                          Text(
                                            '₺${_weeklyPrice.toStringAsFixed(2)}/week',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                              fontFamily: 'Nunito',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _selectedPlan == 'weekly'
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: _selectedPlan == 'weekly'
                                          ? Colors.lime.shade700
                                          : Colors.grey,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Yearly option
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedPlan = 'yearly'),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: _selectedPlan == 'yearly'
                                          ? LinearGradient(
                                              colors: [
                                                Colors.lime.withOpacity(0.15),
                                                Colors.lime.withOpacity(0.05),
                                              ],
                                            )
                                          : null,
                                      color: _selectedPlan == 'yearly'
                                          ? null
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedPlan == 'yearly'
                                            ? Colors.lime
                                            : Colors.orange,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.trending_up,
                                            color: Colors.orange,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Text(
                                                    'Annual',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'Nunito',
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '₺${_yearlyPrice.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[600],
                                                      fontFamily: 'Nunito',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    '₺${(_yearlyPrice / 52).toStringAsFixed(2)}/week',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[700],
                                                      fontFamily: 'Nunito',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '₺${(_originalYearlyPrice / 52).toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[500],
                                                      fontFamily: 'Nunito',
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          _selectedPlan == 'yearly'
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: _selectedPlan == 'yearly'
                                              ? Colors.lime.shade700
                                              : Colors.grey,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.orange,
                                          Colors.deepOrange,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${(((_originalYearlyPrice - _yearlyPrice) / _originalYearlyPrice) * 100).round()}% OFF',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Nunito',
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 13,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Cancel anytime',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom action area (compact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Purchase button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handlePurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lime,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Subscribe Now",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Nunito',
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Cancel anytime",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeatureCard({
    required List<Color> gradient,
    required IconData icon,
    required String emoji,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji & Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Text(emoji, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Require authenticated user before attempting purchase.
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        // Show message dialog with same design
        if (!mounted) return;

        // Set loading state
        setState(() {
          _isLoading = true;
        });

        // Show dialog (without await)
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon (gray theme)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(Icons.login, color: Colors.grey[800], size: 35),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Sign In Required',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Message
                  Text(
                    'Redirecting you to sign in...',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Nunito',
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Loading indicator (gray)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Colors.grey[700],
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Wait a moment then navigate
        await Future.delayed(const Duration(milliseconds: 1000));

        if (!mounted) return;

        // Close dialog
        Navigator.of(context).pop();

        // Reset loading
        setState(() {
          _isLoading = false;
        });

        // Navigate to profile/sign-in screen
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const AuthScreen()),
        );

        // After returning from auth, check if user is now signed in
        if (!mounted) return;
        final updatedAuth = Provider.of<AuthProvider>(context, listen: false);
        if (updatedAuth.user != null) {
          // User signed in successfully, now show payment screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => PaymentScreen(
                selectedPlan: _selectedPlan,
                price: _selectedPlan == 'yearly' ? _yearlyPrice : _weeklyPrice,
              ),
            ),
          );
        }
        return;
      }

      // User already signed in, go directly to payment
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              selectedPlan: _selectedPlan,
              price: _selectedPlan == 'yearly' ? _yearlyPrice : _weeklyPrice,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
