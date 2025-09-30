import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_quiz/providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _linkController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Giriş (Email Link)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Email link ile giriş\nGöndereceğimiz bağlantıya tıklayarak giriş yapabilirsiniz. (Aynı cihazda açın)',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        final email = _emailController.text.trim();
                        await auth.sendEmailLink(email);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Giriş bağlantısı gönderildi. Gelen kutunuzu kontrol edin.',
                            ),
                          ),
                        );
                      },
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Giriş Bağlantısı Gönder'),
              ),

              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Elinizdeki bağlantıyı yapıştırarak da giriş yapabilirsiniz',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Email link (tam URL)',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        final email = _emailController.text.trim();
                        final link = _linkController.text.trim();
                        try {
                          await auth.signInWithLink(email, link);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Giriş hatası: $e')),
                          );
                        }
                      },
                child: const Text('Link ile Giriş Yap'),
              ),

              const Divider(),
              ElevatedButton.icon(
                onPressed: auth.isLoading
                    ? null
                    : () => auth.signInWithGoogle(),
                icon: const Icon(Icons.login),
                label: const Text('Google ile Giriş'),
              ),

              if (auth.error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(auth.error, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _linkController.dispose();
    super.dispose();
  }
}
