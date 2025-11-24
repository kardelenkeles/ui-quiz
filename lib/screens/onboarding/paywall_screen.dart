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
  bool _showXButton = false;

  late AnimationController _glitterController;
  late Animation<double> _glitterAnimation;

  String _selectedPlan = 'annual';
  final double _weeklyPrice = 249.99;
  final double _annualPrice = 5000.00;
  final double _originalAnnualPrice = 11904.76;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showCloseButton = true;
        });
      }
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Paywall Image - full width with header overlay
                  Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Image.asset(
                          'asset/icon/paywall-img.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Header overlay
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              if (!isLoggedIn && _showCloseButton)
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AuthScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.close),
                                  color: Colors.white,
                                  iconSize: 24,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                              else if (_showXButton)
                                IconButton(
                                  onPressed: () {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CustomTabBarWidget(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  icon: const Icon(Icons.close),
                                  color: Colors.white,
                                  iconSize: 24,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Title
                        const Text(
                          "Unlock Your Smartest Quiz Experience",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'Nunito',
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Features list
                        _buildFeature("Unlimited AI-powered quizzes"),
                        const SizedBox(height: 10),
                        _buildFeature("Multi-format upload support"),
                        const SizedBox(height: 10),
                        _buildFeature("Retake & share quizzes"),
                        const SizedBox(height: 10),
                        _buildFeature("Ad-free experience"),

                        const SizedBox(height: 30),

                        // Annual Plan with Discount
                        GestureDetector(
                          onTap: () => setState(() => _selectedPlan = 'annual'),
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  gradient: _selectedPlan == 'annual'
                                      ? LinearGradient(
                                          colors: [
                                            const Color(
                                              0xFF4A90E2,
                                            ).withOpacity(0.05),
                                            const Color(
                                              0xFF50E3A1,
                                            ).withOpacity(0.05),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: _selectedPlan == 'annual'
                                      ? null
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _selectedPlan == 'annual'
                                        ? const Color(0xFF4A90E2)
                                        : Colors.grey.shade300,
                                    width: 2.5,
                                  ),
                                  boxShadow: _selectedPlan == 'annual'
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF4A90E2,
                                            ).withOpacity(0.18),
                                            blurRadius: 24,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 8),
                                          ),
                                          BoxShadow(
                                            color: const Color(
                                              0xFF50E3A1,
                                            ).withOpacity(0.14),
                                            blurRadius: 40,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 8),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _selectedPlan == 'annual'
                                              ? const Color(0xFF4A90E2)
                                              : Colors.grey.shade400,
                                          width: 2,
                                        ),
                                        color: _selectedPlan == 'annual'
                                            ? const Color(0xFF4A90E2)
                                            : Colors.transparent,
                                      ),
                                      child: _selectedPlan == 'annual'
                                          ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Image.asset(
                                                'asset/icon/diamond.png',
                                                width: 20,
                                                height: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Annual Plan',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Nunito',
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                '₺${_annualPrice.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Nunito',
                                                  color: Color(0xFF4A90E2),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '₺${_originalAnnualPrice.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: 'Nunito',
                                                  color: Colors.grey[500],
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '₺${(_annualPrice / 52).toStringAsFixed(2)}/week',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'Nunito',
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4A90E2),
                                        Color(0xFF50E3A1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF4A90E2),
                                        blurRadius: 15,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    '58% OFF',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Nunito',
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Weekly Plan
                        GestureDetector(
                          onTap: () => setState(() => _selectedPlan = 'weekly'),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: _selectedPlan == 'weekly'
                                  ? LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFF4A90E2,
                                        ).withOpacity(0.04),
                                        const Color(
                                          0xFF50E3A1,
                                        ).withOpacity(0.04),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: _selectedPlan == 'weekly'
                                  ? null
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedPlan == 'weekly'
                                    ? const Color(0xFF4A90E2)
                                    : Colors.grey.shade300,
                                width: 2.5,
                              ),
                              boxShadow: _selectedPlan == 'weekly'
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF4A90E2,
                                        ).withOpacity(0.25),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                      BoxShadow(
                                        color: const Color(
                                          0xFF50E3A1,
                                        ).withOpacity(0.20),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _selectedPlan == 'weekly'
                                          ? const Color(0xFF4A90E2)
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    color: _selectedPlan == 'weekly'
                                        ? const Color(0xFF4A90E2)
                                        : Colors.transparent,
                                  ),
                                  child: _selectedPlan == 'weekly'
                                      ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Weekly Plan',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Nunito',
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₺${_weeklyPrice.toStringAsFixed(2)}/week',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Nunito',
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Payment info text
                        Text(
                          'Cancel anytime • Unlimited access',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Nunito',
                            color: Colors.grey[700],
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handlePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lime[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedPlan == 'annual'
                                ? "Subscribe Annual Plan"
                                : "Subscribe Weekly Plan",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.lime[400],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontFamily: 'Nunito',
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePurchase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        if (!mounted) return;

        setState(() {
          _isLoading = true;
        });

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

        await Future.delayed(const Duration(milliseconds: 1000));

        if (!mounted) return;

        Navigator.of(context).pop();

        setState(() {
          _isLoading = false;
        });

        await Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const AuthScreen()),
        );

        if (!mounted) return;
        final updatedAuth = Provider.of<AuthProvider>(context, listen: false);
        if (updatedAuth.user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => PaymentScreen(
                selectedPlan: _selectedPlan,
                price: _selectedPlan == 'annual' ? _annualPrice : _weeklyPrice,
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              selectedPlan: _selectedPlan,
              price: _selectedPlan == 'annual' ? _annualPrice : _weeklyPrice,
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
