import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';

class AnimatedCharacterImage extends StatefulWidget {
  const AnimatedCharacterImage({
    super.key,
    required this.imageUrl,
    this.size = 132,
  });

  final String imageUrl;
  final double size;

  @override
  State<AnimatedCharacterImage> createState() => _AnimatedCharacterImageState();
}

class _AnimatedCharacterImageState extends State<AnimatedCharacterImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _tapPulse = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _tapPulse++;
        });
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: foodSurface,
            borderRadius: BorderRadius.circular(widget.size * 0.23),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final value = _controller.value;
                final segment = (value * 3).floor().clamp(0, 2);
                final progress = (value * 3) - segment;
                final wave = math.sin(progress * math.pi * 2);

                var translateX = 0.0;
                var translateY = 0.0;
                var rotation = 0.0;
                var scaleX = 1.0;
                var scaleY = 1.0;

                if (segment == 0) {
                  final step = math.sin(progress * math.pi * 4);
                  translateX = wave * 10;
                  translateY = -step.abs() * 3;
                  rotation = step * 0.035;
                } else if (segment == 1) {
                  final crouch = (1 - math.cos(progress * math.pi * 2)) / 2;
                  translateY = crouch * 16;
                  scaleX = 1 + crouch * 0.1;
                  scaleY = 1 - crouch * 0.22;
                } else {
                  final recline = math.sin(progress * math.pi).clamp(0.0, 1.0);
                  translateX = recline * 8;
                  translateY = recline * 22;
                  rotation = recline * 1.18;
                  scaleX = 1 - recline * 0.12;
                  scaleY = 1 - recline * 0.12;
                }

                return TweenAnimationBuilder<double>(
                  key: ValueKey(_tapPulse),
                  tween: Tween(begin: _tapPulse == 0 ? 1 : 1.08, end: 1),
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.elasticOut,
                  builder: (context, tapScale, animatedChild) {
                    return Transform.translate(
                      offset: Offset(translateX, translateY),
                      child: Transform.rotate(
                        angle: rotation,
                        child: Transform.scale(
                          scaleX: scaleX * tapScale,
                          scaleY: scaleY * tapScale,
                          child: animatedChild,
                        ),
                      ),
                    );
                  },
                  child: child,
                );
              },
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return const Center(
                    child: Icon(Icons.person, color: foodMuted),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
