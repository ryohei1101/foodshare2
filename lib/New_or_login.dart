import 'package:flutter/material.dart';
import 'package:foodshare/SignUpPage.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/login.dart';

class NewOrLoginPage extends StatelessWidget {
  const NewOrLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    const softGray = Color(0xFFF4F0EC);
    const softOrange = Color(0xFFFFEFE3);

    return Scaffold(
      backgroundColor: softGray,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentMinHeight = constraints.maxHeight <= 50
                ? 0.0
                : constraints.maxHeight - 50;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: contentMinHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: foodLine),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: foodPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight < 720 ? 52 : 96),
                    const Text(
                      'Food Share',
                      style: TextStyle(
                        color: foodInk,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [foodPrimary, Color(0x00E97132)],
                        ),
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight < 720 ? 56 : 118),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: foodLine),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A241812),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: foodPrimary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                            ),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('新規作成'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: foodInk,
                              backgroundColor: softOrange,
                              minimumSize: const Size.fromHeight(52),
                              side: const BorderSide(color: foodLine),
                            ),
                            icon: const Icon(Icons.login),
                            label: const Text('ログイン'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Curated by people, not noise.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foodMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
