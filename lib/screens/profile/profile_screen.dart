import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/auth_provider.dart';
import 'auth_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text(
              'Profile',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: auth.user != null
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Image.asset(
                      'asset/icon/settings.png',
                      width: 26,
                      height: 26,
                    ),
                  )
                : null,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Builder(
                  builder: (context) {
                    final isPremium =
                        auth.userData?['subscriptionPlan'] == 'premium';

                    return Column(
                      children: [
                        _buildCompactAccountHeader(context, auth),

                        const SizedBox(height: 12),

                        // Premium Welcome Banner (only for premium users) shown under account header
                        if (isPremium) ...[
                          _buildPremiumWelcomeBanner(),
                          const SizedBox(height: 16),
                        ],

                        // Subscription Section (hide for premium users)
                        if (!isPremium) ...[
                          _buildSubscriptionSection(context),
                          const SizedBox(height: 24),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactAccountHeader(BuildContext context, AuthProvider auth) {
    final plan = auth.userData?['subscriptionPlan'] ?? 'free';
    return GestureDetector(
      onTap: auth.user == null
          ? () {
              Navigator.of(
                context,
              ).push(CupertinoPageRoute(builder: (_) => const AuthScreen()));
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.systemGrey4, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.lime.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.person_fill, color: Colors.lime),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.userData != null
                        ? (auth.userData!['displayName'] ?? 'User')
                        : 'Guest',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    auth.user != null
                        ? (auth.user!.email ?? '')
                        : 'Sign in or register',
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Nunito',
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (auth.user != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: _getPlanGradient(plan),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getPlanName(plan),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              CupertinoIcons.sparkles,
              size: 35,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '🎉 Premium Plus Active!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ve unlocked all features',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Nunito',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Unlimited Usage',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

  Widget _buildActivePremiumFeature(
    String emoji,
    String title,
    String description,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.3),
                    accentColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Nunito',
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.checkmark,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPlanName(String plan) {
    switch (plan) {
      case 'pro':
        return 'Pro';
      case 'premium':
        return 'Premium Plus';
      default:
        return 'Free';
    }
  }

  LinearGradient _getPlanGradient(String plan) {
    switch (plan) {
      case 'pro':
        return LinearGradient(colors: [Colors.orange, Colors.deepOrange]);
      case 'premium':
        return LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade700],
        );
      default:
        return LinearGradient(colors: [Colors.grey, Colors.grey.shade600]);
    }
  }

  Widget _buildPremiumFeatureItem(
    String emoji,
    String title,
    String description,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Nunito',
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: accentColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CupertinoColors.systemGrey4, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.lime.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.rocket_fill,
                  color: Colors.lime,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Choose Your Plan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  color: CupertinoColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Monthly Plan - Most Popular
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.lime, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.lime.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                _buildPlanCard(
                  'Monthly',
                  '₺9.99',
                  '/month',
                  [
                    '✓ Unlimited Quizzes',
                    '✓ PDF, Word, Excel, PPT support',
                    '✓ Create quizzes with camera',
                    '✓ Multiple photo upload',
                    '✓ Detailed statistics',
                    '✓ 3 difficulty levels',
                  ],
                  Colors.lime,
                  true,
                  context,
                  isPopular: true,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🔥 MOST POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Yearly Plan
          _buildPlanCard(
            'Yearly',
            '₺99.99',
            '/year',
            [
              '✓ All Monthly features',
              '✓ Priority AI processing',
              '✓ Advanced analytics',
              '✓ Quiz templates',
              '✓ Sharing features',
              '✓ 24/7 priority support',
              '✓ Ad-free experience',
              '✓ Save 17% annually',
            ],
            Colors.purple,
            true,
            context,
            isRecommended: true,
          ),

          const SizedBox(height: 16),

          // Trust Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.shield_fill,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Secure payment • Cancel anytime',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Nunito',
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    String name,
    String price,
    String period,
    List<String> features,
    Color color,
    bool isUpgrade,
    BuildContext context, {
    bool isCurrentPlan = false,
    bool isPopular = false,
    bool isRecommended = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPopular ? color.withOpacity(0.05) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(isPopular ? 0.3 : 0.2),
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Nunito',
                            color: color == Colors.grey
                                ? CupertinoColors.black
                                : color,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '⭐ Recommended',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Nunito',
                            color: color == Colors.grey
                                ? CupertinoColors.systemGrey
                                : color,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 2),
                          child: Text(
                            period,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Nunito',
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isCurrentPlan)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Features list
          ...features.map((feature) {
            final isIncluded = feature.startsWith('✓');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    isIncluded
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.xmark_circle_fill,
                    size: 16,
                    color: isIncluded
                        ? Colors.green
                        : Colors.red.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature.substring(2), // Remove ✓ or ✗
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Nunito',
                        color: isIncluded
                            ? CupertinoColors.black
                            : CupertinoColors.systemGrey,
                        decoration: isIncluded
                            ? TextDecoration.none
                            : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (isUpgrade) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                color: color,
                onPressed: () {
                  // TODO: Implement subscription logic
                },
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  isPopular ? '🚀 Get Started' : 'Choose Plan',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final pw = _passwordController.text;
    if (!email.contains('@') || pw.length < 6) {
      _showAlert(
        'Error',
        'Please enter a valid email and a password of at least 6 characters.',
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate auth
    setState(() => _isLoading = false);

    _showAlert('Success', 'Login successful.');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Sign In')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                placeholder: 'Email',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(CupertinoIcons.mail),
                ),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _passwordController,
                obscureText: true,
                placeholder: 'Password',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(CupertinoIcons.lock),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CupertinoActivityIndicator()
                      : const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                onPressed: () =>
                    _showAlert('Info', 'Registration flow goes here.'),
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
