import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/auth_provider.dart';
import 'package:ui_quiz/screens/onboarding/onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showConfirmDelete(AuthProvider auth) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
          'Hesabınızı kalıcı olarak silmek istediğinize emin misiniz?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await auth.deleteAccount();
                // show success and pop to root
                showCupertinoDialog(
                  context: context,
                  builder: (_) => CupertinoAlertDialog(
                    title: const Text('Silindi'),
                    content: const Text('Hesabınız silindi.'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Tamam'),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                showCupertinoDialog(
                  context: context,
                  builder: (_) => CupertinoAlertDialog(
                    title: const Text('Hata'),
                    content: Text(e.toString()),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Tamam'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Hesabı Sil'),
          ),
        ],
      ),
    );
  }

  void _showConfirmCancel(AuthProvider auth) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Aboneliği İptal Et'),
        content: const Text(
          'Premium aboneliğinizi iptal etmek istediğinize emin misiniz?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await auth.updateSubscriptionPlan('free');
                showCupertinoDialog(
                  context: context,
                  builder: (_) => CupertinoAlertDialog(
                    title: const Text('İptal Edildi'),
                    content: const Text('Premium aboneliğiniz iptal edildi.'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Tamam'),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                showCupertinoDialog(
                  context: context,
                  builder: (_) => CupertinoAlertDialog(
                    title: const Text('Hata'),
                    content: Text(e.toString()),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Tamam'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Settings',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account info (without buttons)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: CupertinoColors.systemGrey4,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                          color: CupertinoColors.black,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (auth.user != null) ...[
                        Text(
                          'Logged in: ${auth.user?.email ?? ''}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            color: CupertinoColors.systemGrey,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'Not logged in',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: CupertinoColors.systemGrey,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Support
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: CupertinoColors.systemGrey4,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Help & Support',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                          color: CupertinoColors.black,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Email: support@pomeai.app',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          onPressed: () {
                            // TODO: open mail client
                          },
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: const Text(
                            'Contact Us',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: CupertinoColors.black,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // About
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: CupertinoColors.systemGrey4,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                          color: CupertinoColors.black,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Study smarter with AI: Quiz Maker\nVersion 1.0',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Log out and Delete account buttons (at the bottom)
                if (auth.user != null) ...[
                  // Show cancel premium button when user has premium plan
                  if (auth.userData?['subscriptionPlan'] == 'premium') ...[
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: CupertinoColors.systemGrey6,
                        onPressed: auth.isLoading
                            ? null
                            : () => _showConfirmCancel(auth),
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: const Text(
                          'Cancel Premium',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: CupertinoColors.black,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      color: Colors.red,
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              await auth.signOut();
                              // Navigate to onboarding screen after logout
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  CupertinoPageRoute(
                                    builder: (_) => const OnboardingScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: auth.isLoading
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Log Out',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: TextDecoration.none,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: CupertinoColors.systemGrey6,
                      onPressed: auth.isLoading
                          ? null
                          : () => _showConfirmDelete(auth),
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: const Text(
                        'Delete Account',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: CupertinoColors.black,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                // App info / legal links could go here
              ],
            ),
          ),
        ),
      ),
    );
  }
}
