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
            child: const Text('OK', style: TextStyle(fontFamily: 'Nunito')),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog(AuthProvider auth) {
    final emailController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text(
          'Reset Password',
          style: TextStyle(fontFamily: 'Nunito'),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            children: [
              const Text(
                'Enter your email address to receive a password reset link.',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 14),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                placeholder: 'Email',
                style: const TextStyle(fontFamily: 'Nunito'),
                placeholderStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Nunito')),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                Navigator.of(context).pop();
                _showAlert('Error', 'Please enter a valid email address.');
                return;
              }
              Navigator.of(context).pop();
              await auth.resetPassword(email);
              if (auth.error.isEmpty) {
                _showAlert(
                  'Success',
                  'Password reset link sent to your email.',
                );
              } else {
                _showAlert('Error', auth.error);
              }
            },
            child: const Text('Send', style: TextStyle(fontFamily: 'Nunito')),
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
        middle: Text('Sign In', style: TextStyle(fontFamily: 'Nunito')),
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
                _isSignUpMode ? 'Create Account' : 'Sign In with Email',
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
                ? 'Create your new account'
                : 'Sign in with your email and password',
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
            placeholder: 'Enter your email',
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
            placeholder: 'Enter your password',
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
              placeholder: 'Confirm your password',
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
                          'Error',
                          'Please enter a valid email address.',
                        );
                        return;
                      }
                      if (password.isEmpty || password.length < 6) {
                        _showAlert(
                          'Error',
                          'Password must be at least 6 characters.',
                        );
                        return;
                      }

                      if (_isSignUpMode) {
                        // Register mode
                        final confirmPassword = _confirmPasswordController.text
                            .trim();
                        if (password != confirmPassword) {
                          _showAlert('Error', 'Passwords do not match.');
                          return;
                        }
                        await auth.register(email, password);
                        if (auth.error.isEmpty && auth.user != null) {
                          _showAlert('Success', 'Account created! Welcome.');
                        }
                      } else {
                        // Sign in mode
                        await auth.signIn(email, password);
                        if (auth.error.isEmpty && auth.user != null) {
                          _showAlert('Success', 'Login successful! Welcome.');
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
                        _showAlert('Login Error', auth.error);
                      }
                    },
              borderRadius: BorderRadius.circular(12),
              child: auth.isLoading
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : Text(
                      _isSignUpMode ? 'Sign Up' : 'Sign In',
                      style: const TextStyle(
                        decoration: TextDecoration.none,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Forgot Password link (only in sign in mode)
          if (!_isSignUpMode)
            Center(
              child: GestureDetector(
                onTap: () => _showForgotPasswordDialog(auth),
                child: Text(
                  'Forgot your password?',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          if (!_isSignUpMode) const SizedBox(height: 12),
          // Sign up/Sign in toggle link
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
                    ? 'Already have an account? Sign in'
                    : 'Don\'t have an account? Sign up',
                style: const TextStyle(
                  color: Colors.grey,
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
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Image.asset('asset/icon/google.png', fit: BoxFit.fill),
              ),
              const SizedBox(width: 18),
              const Text(
                'Quick Sign In',
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
            'Sign in with one click using your Google account',
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
                          'Success',
                          'Google sign in successful! Welcome.',
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
                        _showAlert('Login Error', auth.error);
                      }
                    },
              borderRadius: BorderRadius.circular(12),
              child: auth.isLoading
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 8),
                        const Text(
                          'Sign In with Google',
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
