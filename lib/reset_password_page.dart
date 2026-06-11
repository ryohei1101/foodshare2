import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';
import 'package:http/http.dart' as http;

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    await _post('/request-password-reset', {
      'email': _emailController.text.trim(),
    }, successMessage: '認証コードを送信しました。開発中はサーバーログで確認できます。');
  }

  Future<void> _resetPassword() async {
    await _post('/reset-password', {
      'email': _emailController.text.trim(),
      'code': _codeController.text.trim(),
      'new_password': _passwordController.text,
    }, successMessage: 'パスワードを更新しました。');
  }

  Future<void> _post(
    String path,
    Map<String, String> body, {
    required String successMessage,
  }) async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _message = successMessage;
        });
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _message = data['detail'] as String? ?? '処理に失敗しました';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = '通信エラーが発生しました';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FoodScaffold(
      title: 'パスワード再設定',
      children: [
        FoodCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'メールアドレス'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isLoading ? null : _requestCode,
                child: const Text('認証コードを送る'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: '認証コード'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '新しいパスワード'),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: Text(_isLoading ? '処理中' : '更新する'),
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_message, style: const TextStyle(color: foodMuted)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
