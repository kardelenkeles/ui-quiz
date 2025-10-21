import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _answerLanguage = 'Auto';

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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Ayarlar')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Account actions
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hesap',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (auth.user != null) ...[
                      Text('Girişli: ${auth.user?.email ?? ''}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton.filled(
                              color: Colors.red,
                              onPressed: auth.isLoading
                                  ? null
                                  : () => auth.signOut(),
                              child: auth.isLoading
                                  ? const CupertinoActivityIndicator()
                                  : const Text('Çıkış Yap'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CupertinoButton(
                              color: CupertinoColors.systemGrey5,
                              onPressed: auth.isLoading
                                  ? null
                                  : () => _showConfirmDelete(auth),
                              child: const Text('Hesabı Sil'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text('Giriş yapılmadı'),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Support
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yardım & Destek',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('E-posta: support@pomeai.app'),
                    const SizedBox(height: 8),
                    CupertinoButton(
                      onPressed: () {
                        // TODO: open mail client
                      },
                      child: const Text('Bize Ulaşın'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // About
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hakkında',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Study smarter with AI: Quiz Maker\nVersion 1.0',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Answer language
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Answer language',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoSegmentedControl<String>(
                      groupValue: _answerLanguage,
                      children: const {
                        'Auto': Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Auto'),
                        ),
                        'English': Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('English'),
                        ),
                        'Turkish': Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Turkish'),
                        ),
                      },
                      onValueChanged: (v) =>
                          setState(() => _answerLanguage = v),
                    ),
                    const SizedBox(height: 8),
                    Text('Selected:   '),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // App info / legal links could go here
            ],
          ),
        ),
      ),
    );
  }
}
