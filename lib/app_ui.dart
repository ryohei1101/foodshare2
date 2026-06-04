import 'package:flutter/material.dart';

const foodPrimary = Color(0xFFE97132);
const foodInk = Color(0xFF241812);
const foodMuted = Color(0xFF7D6E63);
const foodLine = Color(0xFFE8DED5);
const foodSurface = Color(0xFFFFFBF7);

class FoodScaffold extends StatelessWidget {
  const FoodScaffold({
    super.key,
    required this.children,
    this.title,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 28),
    this.actions = const [],
  });

  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(title: Text(title!), actions: actions),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 44,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class FoodSectionTitle extends StatelessWidget {
  const FoodSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: foodInk,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class FoodCard extends StatelessWidget {
  const FoodCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: foodLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F241812),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
