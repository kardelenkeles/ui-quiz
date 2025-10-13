import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/auth_provider.dart';
import 'package:ui_quiz/widgets/custom_tab_bar.dart';

class AuthScreen extends StatefulWidget {
  final bool initialSignUp;
  const AuthScreen({super.key, this.initialSignUp = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUpMode = false;

  @override
  void initState() {
    super.initState();
    // If the screen was opened with initialSignUp true, default to sign up mode
    _isSignUpMode = widget.initialSignUp;
  }

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title, style: const TextStyle(fontFamily: 'Nunito')),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message, style: const TextStyle(fontFamily: 'Nunito')),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam', style: TextStyle(fontFamily: 'Nunito')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Giriş Yap', style: TextStyle(fontFamily: 'Nunito')),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Auth sections (sadece giriş yapmamışsa göster)
                if (auth.user == null) ...[
                  // Email/Password Section
                  _buildEmailPasswordSection(auth),

                  const SizedBox(height: 25),

                  // Google Sign In Section
                  _buildGoogleSignInSection(auth),
                ],

                // Error Display
                if (auth.error.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildErrorDisplay(auth.error),
                ],

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailPasswordSection(AuthProvider auth) {
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
              Icon(CupertinoIcons.mail_solid, color: Colors.lime, size: 24),
              const SizedBox(width: 8),
              Text(
                _isSignUpMode ? 'Hesap Oluştur' : 'Email ile Giriş',
                style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  color: CupertinoColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isSignUpMode
                ? 'Yeni hesabınızı oluşturun'
                : 'Email ve şifrenizle giriş yapın',
            style: TextStyle(
              decoration: TextDecoration.none,
              fontSize: 14,
              fontFamily: 'Nunito',
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 16),
          // Email Field
          CupertinoTextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            placeholder: 'Email adresinizi girin',
            style: const TextStyle(
              fontFamily: 'Nunito',
              decoration: TextDecoration.none,
            ),
            placeholderStyle: const TextStyle(
              fontFamily: 'Nunito',
              color: CupertinoColors.systemGrey,
            ),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(
                CupertinoIcons.mail,
                color: CupertinoColors.systemGrey,
              ),
            ),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          // Password Field
          CupertinoTextField(
            controller: _passwordController,
            obscureText: true,
            placeholder: 'Şifrenizi girin',
            style: const TextStyle(fontFamily: 'Nunito'),
            placeholderStyle: const TextStyle(
              decoration: TextDecoration.none,
              fontFamily: 'Nunito',
              color: CupertinoColors.systemGrey,
            ),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(
                CupertinoIcons.lock,
                color: CupertinoColors.systemGrey,
              ),
            ),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // Confirm Password Field (only in sign up mode)
          if (_isSignUpMode) ...[
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _confirmPasswordController,
              obscureText: true,
              placeholder: 'Şifreyi tekrarlayın',
              style: const TextStyle(fontFamily: 'Nunito'),
              placeholderStyle: const TextStyle(
                decoration: TextDecoration.none,
                fontFamily: 'Nunito',
                color: CupertinoColors.systemGrey,
              ),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(
                  CupertinoIcons.lock,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              color: Colors.lime,
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      final email = _emailController.text.trim();
                      final password = _passwordController.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        _showAlert(
                          'Hata',
                          'Lütfen geçerli bir email adresi girin.',
                        );
                        return;
                      }
                      if (password.isEmpty || password.length < 6) {
                        _showAlert('Hata', 'Şifre en az 6 karakter olmalıdır.');
                        return;
                      }

                      if (_isSignUpMode) {
                        // Register mode
                        final confirmPassword = _confirmPasswordController.text
                            .trim();
                        if (password != confirmPassword) {
                          _showAlert('Hata', 'Şifreler eşleşmiyor.');
                          return;
                        }
                        await auth.register(email, password);
                        if (auth.error.isEmpty && auth.user != null) {
                          _showAlert(
                            'Başarılı',
                            'Hesap oluşturuldu! Hoş geldiniz.',
                          );
                        }
                      } else {
                        // Sign in mode
                        await auth.signIn(email, password);
                        if (auth.error.isEmpty && auth.user != null) {
                          _showAlert(
                            'Başarılı',
                            'Giriş başarılı! Hoş geldiniz.',
                          );
                        }
                      }

                      if (auth.error.isEmpty && auth.user != null) {
                        // Navigate to main tabbed screen after successful login
                        Future.delayed(const Duration(seconds: 1), () {
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              CupertinoPageRoute(
                                builder: (_) => const CustomTabBarWidget(),
                              ),
                              (route) => false,
                            );
                          }
                        });
                      } else if (auth.error.isNotEmpty) {
                        _showAlert('Giriş Hatası', auth.error);
                      }
                    },
              borderRadius: BorderRadius.circular(12),
              child: auth.isLoading
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : Text(
                      _isSignUpMode ? 'Kayıt Ol' : 'Giriş Yap',
                      style: const TextStyle(
                        decoration: TextDecoration.none,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Kayıt ol linki
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isSignUpMode = !_isSignUpMode;
                  _emailController.clear();
                  _passwordController.clear();
                  _confirmPasswordController.clear();
                });
              },
              child: Text(
                _isSignUpMode
                    ? 'Zaten hesabınız var mı? Giriş yapın'
                    : 'Hesabınız yok mu? Kayıt olun',
                style: const TextStyle(
                  color: Colors.lime,
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInSection(AuthProvider auth) {
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
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  CupertinoIcons.globe,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Hızlı Giriş',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  color: CupertinoColors.black,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Google hesabınızla tek tıkla giriş yapın',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Nunito',
              color: CupertinoColors.systemGrey,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              color: Colors.red,
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      await auth.signInWithGoogle();
                      if (auth.error.isEmpty && auth.user != null) {
                        _showAlert(
                          'Başarılı',
                          'Google ile giriş başarılı! Hoş geldiniz.',
                        );
                        // Navigate to main tabbed screen after successful login
                        Future.delayed(const Duration(seconds: 1), () {
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              CupertinoPageRoute(
                                builder: (_) => const CustomTabBarWidget(),
                              ),
                              (route) => false,
                            );
                          }
                        });
                      } else if (auth.error.isNotEmpty) {
                        _showAlert('Giriş Hatası', auth.error);
                      }
                    },
              borderRadius: BorderRadius.circular(12),
              child: auth.isLoading
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Icon(
                            CupertinoIcons.globe,
                            size: 14,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Google ile Giriş',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Colors.red,
                fontFamily: 'Nunito',
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
