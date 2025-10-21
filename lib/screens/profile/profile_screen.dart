import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/auth_provider.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Consumer<AuthProvider>(
              builder: (context, auth, child) {
                final isPremium =
                    auth.userData?['subscriptionPlan'] == 'premium';

                return Column(
                  children: [
                    const SizedBox(height: 12),

                    // Compact account header always at top (less vertical space)
                    _buildCompactAccountHeader(context, auth),

                    const SizedBox(height: 12),

                    // Premium Welcome Banner (only for premium users) shown under account header
                    if (isPremium) ...[
                      _buildPremiumWelcomeBanner(),
                      const SizedBox(height: 16),
                    ],

                    // Pro Features Section (hide for premium users)
                    if (!isPremium) ...[
                      _buildProFeaturesSection(),
                      const SizedBox(height: 18),
                    ],

                    // Subscription Section (hide for premium users)
                    if (!isPremium) ...[
                      _buildSubscriptionSection(context),
                      const SizedBox(height: 24),
                    ],

                    // Premium Features List (only for premium users)
                    if (isPremium) ...[
                      _buildPremiumFeaturesList(),
                      const SizedBox(height: 20),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactAccountHeader(BuildContext context, AuthProvider auth) {
    final plan = auth.userData?['subscriptionPlan'] ?? 'free';
    return Container(
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
                      ? (auth.userData!['displayName'] ?? 'Kullanıcı')
                      : 'Misafir',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  auth.user != null
                      ? (auth.user!.email ?? '')
                      : 'Giriş yap veya kayıt ol',
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            height: 36,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              color: auth.user != null
                  ? Colors.redAccent.withOpacity(0.1)
                  : Colors.lime.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              onPressed: () {
                if (auth.user == null) {
                  Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const AuthScreen()),
                  );
                } else {
                  _showSignOutDialog(context, auth);
                }
              },
              child: Icon(
                auth.user != null
                    ? CupertinoIcons.square_arrow_right
                    : CupertinoIcons.person_badge_plus,
                size: 18,
                color: auth.user != null ? Colors.red : Colors.lime,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF691110), Color(0xFFD9B6AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF691110).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              CupertinoIcons.person_fill,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hoş Geldiniz!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Quiz deneyiminizi kişiselleştirin',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'Nunito',
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
            '🎉 Premium Plus Aktif!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tüm özelliklerin kilidini açtınız',
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
                  'Sınırsız Kullanım',
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

  Widget _buildPremiumFeaturesList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
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
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.purple.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.star_fill,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Premium Özellikleriniz',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  color: CupertinoColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildActivePremiumFeature(
            '🤖',
            'AI Destekli Quiz Oluşturma',
            'GPT-4 ile sınırsız akıllı sorular',
            Colors.blue,
          ),
          _buildActivePremiumFeature(
            '📸',
            'Görsel Tanıma',
            'Fotoğraflardan otomatik quiz',
            Colors.green,
          ),
          _buildActivePremiumFeature(
            '📄',
            'Tüm Dosya Formatları',
            'PDF, Word, Excel, PowerPoint desteği',
            Colors.red,
          ),
          _buildActivePremiumFeature(
            '∞',
            'Sınırsız Quiz',
            'İstediğin kadar quiz oluştur',
            Colors.orange,
          ),
          _buildActivePremiumFeature(
            '📊',
            'Detaylı Analitik',
            'İlerleme takibi ve raporlar',
            Colors.purple,
          ),
          _buildActivePremiumFeature(
            '🚫',
            'Reklamsız Deneyim',
            'Hiç kesinti olmadan çalış',
            Colors.teal,
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

  Widget _buildAuthSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
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
              Text(
                auth.user != null ? 'Hesap Yönetimi' : 'Hesap İşlemleri',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  color: CupertinoColors.black,
                ),
              ),
              const SizedBox(height: 16),

              // Giriş yapmamış kullanıcılar için
              if (auth.user == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton.filled(
                        color: Colors.lime,
                        onPressed: () => Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => const AuthScreen(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: const Text(
                          'Giriş Yap',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton(
                        color: CupertinoColors.systemGrey5,
                        onPressed: () => Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => const AuthScreen(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: const Text(
                          'Kayıt Ol',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Giriş yapmış kullanıcılar için
              if (auth.user != null) ...[
                // Kullanıcı bilgileri
                if (auth.userData != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.lime.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.lime.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.lime.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.person_fill,
                            color: Colors.lime,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.userData!['displayName'] ?? 'Kullanıcı',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Nunito',
                                  color: CupertinoColors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                auth.user!.email ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Nunito',
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: _getPlanGradient(
                              auth.userData!['subscriptionPlan'] ?? 'free',
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _getPlanColor(
                                  auth.userData!['subscriptionPlan'] ?? 'free',
                                ).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (auth.userData!['subscriptionPlan'] ==
                                  'premium') ...[
                                const Icon(
                                  CupertinoIcons.sparkles,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                _getPlanName(
                                  auth.userData!['subscriptionPlan'] ?? 'free',
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
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
                  ),
                  const SizedBox(height: 16),
                ],

                // Çıkış Yap Butonu
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    color: Colors.red,
                    onPressed: auth.isLoading
                        ? null
                        : () => _showSignOutDialog(context, auth),
                    borderRadius: BorderRadius.circular(12),
                    child: auth.isLoading
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text(
                            'Çıkış Yap',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
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

  Color _getPlanColor(String plan) {
    switch (plan) {
      case 'pro':
        return Colors.orange;
      case 'premium':
        return Colors.purple;
      default:
        return Colors.grey;
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

  void _showSignOutDialog(BuildContext context, AuthProvider auth) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Çıkış Yap', style: TextStyle(fontFamily: 'Nunito')),
        content: const Text(
          'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
          style: TextStyle(fontFamily: 'Nunito'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal', style: TextStyle(fontFamily: 'Nunito')),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await auth.signOut();
              // Show success message
              showCupertinoDialog(
                context: context,
                builder: (_) => CupertinoAlertDialog(
                  title: const Text(
                    'Başarılı',
                    style: TextStyle(fontFamily: 'Nunito'),
                  ),
                  content: const Text(
                    'Çıkış işlemi tamamlandı.',
                    style: TextStyle(fontFamily: 'Nunito'),
                  ),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Tamam',
                        style: TextStyle(fontFamily: 'Nunito'),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProFeaturesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.sparkles,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PomeAI Premium',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito',
                        color: CupertinoColors.black,
                      ),
                    ),
                    Text(
                      'Tüm özelliklerin kilidini aç',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Nunito',
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Öne Çıkan Özellikler
          _buildPremiumFeatureItem(
            '🤖',
            'AI Destekli Quiz Oluşturma',
            'OpenAI GPT-4 ile akıllı sorular',
            Colors.blue,
          ),
          _buildPremiumFeatureItem(
            '📸',
            'Görsel Tanıma & Çoklu Fotoğraf',
            'Kamerayla çektiğin notlardan quiz oluştur',
            Colors.green,
          ),
          _buildPremiumFeatureItem(
            '📄',
            'Dosya Desteği (PDF, Word, Excel, PPT)',
            'Ders notlarından otomatik quiz',
            Colors.red,
          ),
          _buildPremiumFeatureItem(
            '🎯',
            'Özel Zorluk Seviyeleri',
            'Kolay, orta ve zor sorular',
            Colors.orange,
          ),
          _buildPremiumFeatureItem(
            '📊',
            'İstatistikler & Analiz',
            'İlerleme takibi ve performans raporları',
            Colors.purple,
          ),
          _buildPremiumFeatureItem(
            '💾',
            'Sınırsız Quiz Geçmişi',
            'Tüm quizlerini sakla ve tekrar çöz',
            Colors.teal,
          ),

          const SizedBox(height: 16),

          // Premium CTA Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              children: [
                Text(
                  '🎉 Özel Fırsat!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'İlk ay %50 indirimli',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '₺9.99 yerine sadece ₺4.99',
                  style: TextStyle(
                    fontSize: 20,
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
                'Planını Seç',
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

          // Free Plan
          _buildPlanCard(
            'Ücretsiz',
            '₺0',
            '/ay',
            [
              '✓ 5 Quiz/ay',
              '✓ Temel özellikler',
              '✓ Metin girişi',
              '✗ Dosya yükleme yok',
              '✗ Görsel tanıma yok',
            ],
            Colors.grey,
            false,
            context,
            isCurrentPlan: true,
          ),

          const SizedBox(height: 12),

          // Pro Plan - En Popüler
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
                  'Pro',
                  '₺9.99',
                  '/ay',
                  [
                    '✓ Sınırsız Quiz',
                    '✓ PDF, Word, Excel, PPT desteği',
                    '✓ Kamera ile quiz oluştur',
                    '✓ Çoklu fotoğraf yükleme',
                    '✓ Detaylı istatistikler',
                    '✓ 3 zorluk seviyesi',
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
                      '🔥 EN POPÜLER',
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

          // Premium Plan
          _buildPlanCard(
            'Premium',
            '₺19.99',
            '/ay',
            [
              '✓ Tüm Pro özellikleri',
              '✓ Öncelikli AI işleme',
              '✓ Gelişmiş analitik',
              '✓ Quiz şablonları',
              '✓ Paylaşım özellikleri',
              '✓ 7/24 öncelikli destek',
              '✓ Reklamsız deneyim',
            ],
            Colors.purple,
            true,
            context,
            isRecommended: true,
          ),

          const SizedBox(height: 16),

          // Güven Rozeti
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
                  'Güvenli ödeme • İstediğin zaman iptal et',
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
                              '⭐ Önerilen',
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
                    'Mevcut',
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
                onPressed: () => Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                ),
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  isPopular ? '🚀 Hemen Başla' : 'Planı Seç',
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
            child: const Text('Tamam'),
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
        'Hata',
        'Lütfen geçerli bir e-posta ve en az 6 haneli parola girin.',
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate auth
    setState(() => _isLoading = false);

    _showAlert('Başarılı', 'Giriş başarılı.');
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
      navigationBar: const CupertinoNavigationBar(middle: Text('Giriş Yap')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                placeholder: 'E-posta',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(CupertinoIcons.mail),
                ),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _passwordController,
                obscureText: true,
                placeholder: 'Parola',
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
                      : const Text('Giriş Yap'),
                ),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                onPressed: () =>
                    _showAlert('Bilgi', 'Kayıt akışı burada yer alır.'),
                child: const Text('Hesap Oluştur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlan = 'free';
  bool _isProcessing = false;

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
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _upgrade() async {
    if (_selectedPlan == 'free') {
      _showAlert('Bilgi', 'Lütfen bir ücretli plan seçin.');
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isProcessing = false);

    _showAlert(
      'Tebrikler',
      'Abonelik yükseltme işlemi başarılı: $_selectedPlan',
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Abonelik / Upgrade'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Planlar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              CupertinoSegmentedControl<String>(
                groupValue: _selectedPlan,
                children: const {
                  'free': Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Free'),
                  ),
                  'pro': Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Pro'),
                  ),
                  'premium': Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Premium'),
                  ),
                },
                onValueChanged: (v) => setState(() => _selectedPlan = v),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _selectedPlan == 'free'
                      ? 'Free (Ücretsiz) - Temel özellikler'
                      : _selectedPlan == 'pro'
                      ? 'Pro - Aylık 9.99 ₺ - Daha fazla özellik'
                      : 'Premium - Aylık 19.99 ₺ - Tüm özellikler',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _isProcessing ? null : _upgrade,
                  child: _isProcessing
                      ? const CupertinoActivityIndicator()
                      : const Text('Abone Ol / Yükselt'),
                ),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                onPressed: () => _showAlert(
                  'Yardım',
                  'Ödeme bilgileriniz güvenli bir biçimde işlenecektir.',
                ),
                child: const Text('Ödeme hakkında daha fazla bilgi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
