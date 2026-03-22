import 'package:flutter/material.dart';

import 'api.dart';
import 'log_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await AuthApi.loadToken();
      if (!mounted) return;

      if (AuthApi.accessToken != null && AuthApi.accessToken!.isNotEmpty) {
        final ok = await AuthApi.verifyToken();
        if (!mounted) return;

        if (!ok) {
          return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LogPage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = '請輸入帳號與密碼';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await AuthApi.login(username: username, password: password);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LogPage()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登入'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '帳號',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  onSubmitted: (_) {
                    if (!_isLoading) {
                      _login();
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: '密碼',
                  ),
                ),
                const SizedBox(height: 16),
                if (_errorText != null) ...[
                  Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('登入'),
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
