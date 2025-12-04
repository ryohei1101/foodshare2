import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PopTitle extends StatelessWidget {
  const PopTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 背景の爆発エフェクト風
        Container(
          width: 240,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            gradient: const RadialGradient(
              colors: [Colors.red, Colors.orange],
              center: Alignment(0.0, 0.0),
              radius: 1.0,
            ),
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: const [
              BoxShadow(color: Colors.black54, offset: Offset(5, 5), blurRadius: 5)
            ],
          ),
        ),
        // テキスト本体
        Text(
          'FOOD SHARE',
          textAlign: TextAlign.center,
          style: GoogleFonts.bangers(
            textStyle: TextStyle(
              fontSize: 44,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 6
                ..color = Colors.black, // 黒い縁取り
              shadows: const [
                Shadow(offset: Offset(4, 4), color: Colors.black54, blurRadius: 4),
              ],
            ),
          ),
        ),
        // 塗りつぶしテキスト（縁の中）
        Text(
          'FOOD SHARE',
          textAlign: TextAlign.center,
          style: GoogleFonts.bangers(
            textStyle: const TextStyle(
              fontSize: 44,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: Colors.yellow,
              shadows: [
                Shadow(offset: Offset(2, 2), color: Colors.red, blurRadius: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
