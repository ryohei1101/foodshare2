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
                var scale = 1.0;

                if (segment == 0) {
                  translateY = wave * 4;
                  scale = 1 + wave.abs() * 0.012;
                } else if (segment == 1) {
                  translateX = wave * 2.5;
                  rotation = wave * 0.035;
                } else {
                  final hop = math.max(0.0, wave);
                  translateY = -hop * 6;
                  scale = 1 + hop * 0.035;
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
                          scale: scale * tapScale,
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
