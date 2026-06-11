import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodshare/New_or_login.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/asking_page1.dart';
import 'package:foodshare/legal_pages.dart';
import 'package:http/http.dart' as http;

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController verificationCodeController =
      TextEditingController();
  bool _agreedTerms = false;
  bool _agreedPrivacy = false;
  bool _agreedLocation = false;
  bool _isSendingCode = false;
  bool _isVerifying = false;
  bool _isEmailVerified = false;
  String _message = '';
  int _debugTapCount = 0;
  DateTime? _lastDebugTapAt;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_handleInputChanged);
    passwordController.addListener(_handleInputChanged);
    verificationCodeController.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    emailController.removeListener(_handleInputChanged);
    passwordController.removeListener(_handleInputChanged);
    verificationCodeController.removeListener(_handleInputChanged);
    emailController.dispose();
    passwordController.dispose();
    verificationCodeController.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _requestVerificationCode() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _message = 'メールアドレスを入力してください';
      });
      return;
    }

    setState(() {
      _isSendingCode = true;
      _message = '';
      _isEmailVerified = false;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/request-email-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _message = '認証コードを送信しました。開発中はサーバーログで確認できます。';
        });
      } else {
        setState(() {
          _message = '認証コードを送信できませんでした';
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
          _isSendingCode = false;
        });
      }
    }
  }

  Future<void> _verifyEmail() async {
    setState(() {
      _isVerifying = true;
      _message = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'code': verificationCodeController.text.trim(),
        }),
      );

      if (!mounted) return;

      setState(() {
        _isEmailVerified = response.statusCode == 200;
        _message = _isEmailVerified ? 'メール認証が完了しました' : '認証コードが違います';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = '通信エラーが発生しました';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  bool get _canContinue =>
      emailController.text.trim().isNotEmpty &&
      passwordController.text.isNotEmpty &&
      _isEmailVerified &&
      _agreedTerms &&
      _agreedPrivacy &&
      _agreedLocation;

  void _handleDebugNextTap() {
    if (!kDebugMode) {
      return;
    }

    final now = DateTime.now();
    if (_lastDebugTapAt == null ||
        now.difference(_lastDebugTapAt!) > const Duration(seconds: 2)) {
      _debugTapCount = 0;
    }

    _lastDebugTapAt = now;
    _debugTapCount += 1;

    if (_debugTapCount < 2) {
      return;
    }

    _debugTapCount = 0;
    final email = emailController.text.trim().isEmpty
        ? 'debug-${DateTime.now().millisecondsSinceEpoch}@test.com'
        : emailController.text.trim();
    final password = passwordController.text.isEmpty
        ? 'debug-password'
        : passwordController.text;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionPage(email: email, password: password),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FoodScaffold(
      children: [
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleDebugNextTap,
          child: const Text(
            "アカウント作成",
            style: TextStyle(
              color: foodInk,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "まずはログインに使う情報を登録します。",
          style: TextStyle(color: foodMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 28),
        FoodCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "メールアドレス",
                  hintText: "example@gmail.com",
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "パスワード",
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: verificationCodeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'メール認証コード',
                        prefixIcon: Icon(Icons.verified_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _isSendingCode ? null : _requestVerificationCode,
                    icon: _isSendingCode
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    onPressed: _isVerifying ? null : _verifyEmail,
                    icon: _isEmailVerified
                        ? const Icon(Icons.check_circle)
                        : const Icon(Icons.check),
                  ),
                ],
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(_message, style: const TextStyle(color: foodMuted)),
              ],
              const SizedBox(height: 16),
              _AgreementTile(
                value: _agreedTerms,
                text: '利用規約に同意します',
                documentType: LegalDocumentType.terms,
                onChanged: (value) => setState(() => _agreedTerms = value),
              ),
              _AgreementTile(
                value: _agreedPrivacy,
                text: 'プライバシーポリシーに同意します',
                documentType: LegalDocumentType.privacy,
                onChanged: (value) => setState(() => _agreedPrivacy = value),
              ),
              _AgreementTile(
                value: _agreedLocation,
                text: '位置情報の取り扱いに同意します',
                documentType: LegalDocumentType.location,
                onChanged: (value) => setState(() => _agreedLocation = value),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _canContinue
                    ? () {
                        final email = emailController.text.trim();
                        final password = passwordController.text.trim();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                QuestionPage(email: email, password: password),
                          ),
                        );
                      }
                    : null,
                child: const Text("次へ"),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const NewOrLoginPage()),
                  );
                },
                child: const Text("戻る"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgreementTile extends StatelessWidget {
  const _AgreementTile({
    required this.value,
    required this.text,
    required this.documentType,
    required this.onChanged,
  });

  final bool value;
  final String text;
  final LegalDocumentType documentType;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (next) => onChanged(next ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LegalDocumentPage(type: documentType),
            ),
          );
        },
        child: const Text('内容を確認する'),
      ),
    );
  }
}
