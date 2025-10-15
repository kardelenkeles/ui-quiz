import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/auth_provider.dart';
import 'package:ui_quiz/widgets/custom_tab_bar.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;

  String _selectedPlan = 'yearly'; // 'weekly' or 'yearly'
  final double _weeklyPrice = 249.99; // TRY
  final double _yearlyPrice = 2849.99; // TRY

  final List<PremiumFeature> _features = [
    PremiumFeature(
      icon: Icons.auto_awesome,
      title: "Sınırsız Quiz Oluşturma",
      description: "İstediğiniz kadar quiz oluşturun",
    ),
    PremiumFeature(
      icon: Icons.picture_as_pdf,
      title: "PDF Desteği",
      description: "PDF dosyalarından otomatik sorular",
    ),
    PremiumFeature(
      icon: Icons.analytics,
      title: "Detaylı Raporlar",
      description: "Quiz sonuçlarınızı analiz edin",
    ),
    PremiumFeature(
      icon: Icons.cloud_sync,
      title: "Cloud Senkronizasyon",
      description: "Tüm cihazlarınızda erişim",
    ),
  ];

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
                  IconButton(
                    onPressed: () {
                      // Navigate to home tab instead of popping to avoid black screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomTabBarWidget(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.close,
                      color: const Color.fromARGB(255, 146, 115, 115),
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
              // Non-scrollable single-page layout
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(height: 8),

                    // Title
                    const Text(
                      "Premium'a Geçin",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      "Tüm premium özelliklerin kilidini açın ve sınırsız quiz deneyiminin tadını çıkarın",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

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

                    const SizedBox(height: 12),
                    // Pricing selection
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Abonelik Seçin",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 12),

                          // Weekly option
                          GestureDetector(
                            onTap: () =>
                                setState(() => _selectedPlan = 'weekly'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: _selectedPlan == 'weekly'
                                    ? Colors.lime.withOpacity(0.12)
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedPlan == 'weekly'
                                      ? Colors.lime
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Haftalık',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₺${_weeklyPrice.toStringAsFixed(2)} / hafta',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    _selectedPlan == 'weekly'
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: _selectedPlan == 'weekly'
                                        ? Colors.lime.shade700
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Yearly option
                          GestureDetector(
                            onTap: () =>
                                setState(() => _selectedPlan = 'yearly'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: _selectedPlan == 'yearly'
                                    ? Colors.lime.withOpacity(0.12)
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedPlan == 'yearly'
                                      ? Colors.lime
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Yıllık',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₺${_yearlyPrice.toStringAsFixed(2)} / yıl',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    _selectedPlan == 'yearly'
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: _selectedPlan == 'yearly'
                                        ? Colors.lime.shade700
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
                          const Text(
                            'Not: Abonelik satın alındığında hemen ücretlendirme başlar. İadesi ve deneme süresi platform politikalarına tabidir.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
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
                                  ? "Haftalık ₺${_weeklyPrice.toStringAsFixed(2)}"
                                  : "Yıllık ₺${_yearlyPrice.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Terms and conditions
                  Text(
                    "Satın alımınızla Kullanım Koşulları ve Gizlilik Politikası'nı kabul etmiş olursunuz",
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.lime.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(feature.icon, size: 20, color: Colors.lime.shade700),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
        // Ask the user to sign in or register first.
        final goToProfile = await showDialog<bool?>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Giriş Gerekiyor'),
            content: const Text(
              'Premium satın almak için lütfen hesabınızla giriş yapın. Hesabınız yoksa kayıt olun.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Giriş Yap'),
              ),
            ],
          ),
        );

        if (goToProfile == true) {
          // Navigate to profile/sign-in screen so user can authenticate.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const CustomTabBarWidget(initialIndex: 2),
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomTabBarWidget()),
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

  PremiumFeature({
    required this.icon,
    required this.title,
    required this.description,
  });
}
