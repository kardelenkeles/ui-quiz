import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ui_quiz/screens/profile/auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Profil')),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.person,
                    size: 48,
                    color: CupertinoColors.white,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: 220,
                  child: CupertinoButton.filled(
                    color: Colors.lime,
                    onPressed: () => Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const AuthScreen()),
                    ),
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 220,
                  child: CupertinoButton(
                    color: Colors.lime,
                    onPressed: () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: const Text('Upgrade'),
                  ),
                ),
              ],
            ),
          ),
        ),
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
