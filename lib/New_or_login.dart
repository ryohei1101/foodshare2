import 'package:flutter/material.dart';
import 'package:foodshare/SignUpPage.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/login.dart';

class NewOrLoginPage extends StatelessWidget {
  const NewOrLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF15110E);
    const gold = Color(0xFFC7A15B);
    const ivory = Color(0xFFFFFCF7);

    return Scaffold(
      backgroundColor: dark,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: gold, width: 1.2),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: gold,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight < 720 ? 52 : 96),
                    const Text(
                      'Food Share',
                      style: TextStyle(
                        color: ivory,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '記憶に残る一皿と、信頼できる人の店選びをひとつに。',
                      style: TextStyle(
                        color: Color(0xFFD8CEC2),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 34),
                    Container(
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [gold, Color(0x0015110E)],
                        ),
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight < 720 ? 56 : 118),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: ivory,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE8DED5)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 28,
                            offset: Offset(0, 18),
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
                              backgroundColor: dark,
                              foregroundColor: ivory,
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
                              foregroundColor: dark,
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
                        color: Color(0xFF9B8D7C),
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
