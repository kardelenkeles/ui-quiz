import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/auth_provider.dart';
import 'package:ui_quiz/widgets/custom_tab_bar.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
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

    _glitterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _glitterAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _glitterController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showCloseButton = true;
        });
      }
    });
    // X butonu hemen gösterilsin
    _showXButton = true;
  }

  @override
  void dispose() {
    _glitterController.dispose();
    super.dispose();
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
                        height: MediaQuery.of(context).size.height * 0.28,
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
                                            ).withOpacity(0.3),
                                            const Color(
                                              0xFF50E3A1,
                                            ).withOpacity(0.3),
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
                                              const Text(
                                                'Annual Plan',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Nunito',
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              if (_selectedPlan == 'annual')
                                                const SizedBox(width: 8),
                                              if (_selectedPlan == 'annual')
                                                Image.asset(
                                                  'asset/icon/diamond.png',
                                                  width: 20,
                                                  height: 20,
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
                                        ).withOpacity(0.3),
                                        const Color(
                                          0xFF50E3A1,
                                        ).withOpacity(0.3),
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
                                      Row(
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
                                          if (_selectedPlan == 'weekly')
                                            const SizedBox(width: 8),
                                          if (_selectedPlan == 'weekly')
                                            Image.asset(
                                              'asset/icon/diamond.png',
                                              width: 20,
                                              height: 20,
                                            ),
                                        ],
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
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
                                onPressed: _isLoading ? null : _handlePurchase,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lime[400],
                                  foregroundColor: Colors.black,
                                  elevation: 8,
                                  shadowColor: Colors.lime.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                          const Icon(
                                            Icons.arrow_forward,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            if (!_isLoading)
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
                const SizedBox(height: 18),
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
                const SizedBox(height: 32),
              ],
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
      // RevenueCat ile ödeme işlemi
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        throw Exception('No offerings available');
      }

      // Seçili plana göre package'ı al
      Package? package;
      if (_selectedPlan == 'annual') {
        package = offerings.current!.annual;
      } else {
        package = offerings.current!.weekly;
      }

      if (package == null) {
        throw Exception('Selected plan not available');
      }

      // Satın alma işlemini başlat
      final purchaseResult = await Purchases.purchasePackage(package);

      // Ödeme başarılı mı kontrol et
      // purchases_flutter newer APIs return a PurchaseResult which contains `customerInfo`.
      // Older versions returned a purchaserInfo with `entitlements` directly.
      // Use dynamic casts to support either shape.
      final customerInfo = (purchaseResult as dynamic).customerInfo;
      final bool isPremiumActive =
          (customerInfo?.entitlements?.all['premium']?.isActive == true) ||
          ((purchaseResult as dynamic).entitlements?.all['premium']?.isActive ==
              true);

      if (isPremiumActive) {
        if (!mounted) return;

        // Ödeme başarılı - Generate ekranına git
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const CustomTabBarWidget()),
          (route) => false,
        );
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ödeme hatası: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
