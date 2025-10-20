import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/auth_provider.dart';
import 'package:ui_quiz/widgets/custom_tab_bar.dart';
import 'package:ui_quiz/screens/onboarding/payment_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;
  bool _showCloseButton = false;

  String _selectedPlan = 'yearly'; // 'weekly' or 'yearly'
  final double _weeklyPrice = 249.99; // TRY
  final double _yearlyPrice = 2849.99; // TRY

  final List<PremiumFeature> _features = [
    PremiumFeature(
      icon: Icons.auto_awesome,
      title: "Unlimited Quizzes",
      description: "Create as many as you want",
      emoji: "∞",
      color: Colors.blue,
    ),
    PremiumFeature(
      icon: Icons.photo_camera,
      title: "Camera & Files",
      description: "Photos, PDF, Word, Excel",
      emoji: "�",
      color: Colors.green,
    ),
    PremiumFeature(
      icon: Icons.workspace_premium,
      title: "Premium Plus",
      description: "All features unlocked",
      emoji: "⭐",
      color: Colors.amber,
    ),
    PremiumFeature(
      icon: Icons.block,
      title: "No Ads",
      description: "Ad-free experience",
      emoji: "🚫",
      color: Colors.red,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Show close button after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showCloseButton = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  AnimatedOpacity(
                    opacity: _showCloseButton ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: AnimatedScale(
                      scale: _showCloseButton ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      child: IconButton(
                        onPressed: _showCloseButton
                            ? () {
                                // Navigate to home tab instead of popping to avoid black screen
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CustomTabBarWidget(),
                                  ),
                                );
                              }
                            : null,
                        icon: Icon(
                          Icons.close,
                          color: _showCloseButton
                              ? const Color.fromARGB(255, 146, 115, 115)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.lime.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "PREMIUM",
                      style: TextStyle(
                        color: Colors.lime,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const SizedBox(height: 8),

                      // Premium icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.lime, Colors.lime.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.lime.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        "Choose Your Plan",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Nunito',
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        "Subscribe to unlock all features",
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.grey[700],
                          height: 1.3,
                          fontFamily: 'Nunito',
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Features list (compact 2-column)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = (constraints.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _features
                                .map(
                                  (f) => SizedBox(
                                    width: itemWidth,
                                    child: _buildCompactFeatureItem(f),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.lime,
                                        Colors.lime.shade700,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "⭐ SELECT PLAN",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Nunito',
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
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
                                  borderRadius: BorderRadius.circular(16),
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
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_today,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Haftalık',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Nunito',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₺${_weeklyPrice.toStringAsFixed(2)} / hafta',
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
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Yearly option - MOST POPULAR
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
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _selectedPlan == 'yearly'
                                            ? Colors.lime
                                            : Colors.orange,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.trending_up,
                                            color: Colors.orange,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Yearly',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Nunito',
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '₺${_yearlyPrice.toStringAsFixed(2)} / year',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey[700],
                                                  fontFamily: 'Nunito',
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  'SAVE 70%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    fontFamily: 'Nunito',
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
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
                                          size: 28,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -8,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.orange,
                                          Colors.deepOrange,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'MOST POPULAR',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Nunito',
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Cancel anytime',
                                  style: TextStyle(
                                    fontSize: 13,
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

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom action area (compact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Purchase button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handlePurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lime,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
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
                          : Text(
                              _selectedPlan == 'weekly'
                                  ? "Subscribe - ₺${_weeklyPrice.toStringAsFixed(2)}/week"
                                  : "Subscribe - ₺${_yearlyPrice.toStringAsFixed(2)}/year",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Terms and conditions
                  Text(
                    "By subscribing, you agree to Terms & Privacy Policy",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactFeatureItem(PremiumFeature feature) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: feature.color, width: 2),
        boxShadow: [
          BoxShadow(
            color: feature.color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(feature.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            feature.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            feature.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'Nunito',
            ),
            textAlign: TextAlign.center,
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
                  // Icon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.lime, Colors.lime.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.lime.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.login,
                      color: Colors.white,
                      size: 35,
                    ),
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
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Loading indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Colors.lime,
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
          MaterialPageRoute(
            builder: (c) => const CustomTabBarWidget(initialIndex: 2),
          ),
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

class PremiumFeature {
  final IconData icon;
  final String title;
  final String description;
  final String emoji;
  final Color color;

  PremiumFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
  });
}
