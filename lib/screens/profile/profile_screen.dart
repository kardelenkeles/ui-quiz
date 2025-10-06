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
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Profile Header
                _buildProfileHeader(),

                const SizedBox(height: 30),

                // Auth Section
                _buildAuthSection(context),

                const SizedBox(height: 25),

                // Pro Features Section
                _buildProFeaturesSection(),

                const SizedBox(height: 25),

                // Subscription Section
                _buildSubscriptionSection(context),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
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
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getPlanColor(
                              auth.userData!['subscriptionPlan'] ?? 'free',
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getPlanName(
                              auth.userData!['subscriptionPlan'] ?? 'free',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Nunito',
                            ),
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
        return 'Premium';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.star_fill, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Pro Özellikler',
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
          _buildFeatureItem('🎯', 'Sınırsız Quiz Oluşturma'),
          _buildFeatureItem('📊', 'Detaylı İstatistikler ve Analiz'),
          _buildFeatureItem('🎨', 'Özel Temalar ve Renkler'),
          _buildFeatureItem('📱', 'Offline Quiz Çözme'),
          _buildFeatureItem('🏆', 'Liderlik Tablosu Erişimi'),
          _buildFeatureItem('💾', 'Quiz Geçmişi Yedeği'),
          _buildFeatureItem('🔔', 'Özel Bildirimler'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Nunito',
                color: CupertinoColors.black,
              ),
            ),
          ),
        ],
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
          const Text(
            'Abonelik Planları',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
              color: CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 16),

          // Free Plan
          _buildPlanCard(
            'Ücretsiz',
            '₺0/ay',
            'Temel özellikler',
            Colors.grey,
            false,
            context,
          ),

          const SizedBox(height: 12),

          // Pro Plan
          _buildPlanCard(
            'Pro',
            '₺9.99/ay',
            'Gelişmiş özellikler',
            Colors.lime,
            true,
            context,
          ),

          const SizedBox(height: 12),

          // Premium Plan
          _buildPlanCard(
            'Premium',
            '₺19.99/ay',
            'Tüm özellikler + öncelik desteği',
            Colors.orange,
            true,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    String name,
    String price,
    String description,
    Color color,
    bool isUpgrade,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                    color: color == Colors.grey ? CupertinoColors.black : color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                    color: color == Colors.grey
                        ? CupertinoColors.systemGrey
                        : color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          if (isUpgrade)
            CupertinoButton.filled(
              color: color,
              onPressed: () => Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const SubscriptionScreen()),
              ),
              borderRadius: BorderRadius.circular(8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                'Seç',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
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
