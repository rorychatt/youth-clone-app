import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CircularGauge extends StatelessWidget {
  final double score;
  final String label;

  const CircularGauge({super.key, required this.score, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 140, // Increased height to push text down
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          CustomPaint(
            size: const Size(240, 120),
            painter: GaugePainter(score: score),
          ),
          Positioned(
            top: 24, // Push the number down slightly
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${score.toInt()}',
                  style: AppTheme.logo.copyWith(
                    color: AppColors.white,
                    fontSize: 64,
                    height: 1.0,
                  ),
                ),
                Text(
                  label,
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 8,
            child: Text('0', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const Positioned(
            bottom: 0,
            right: 8,
            child: Text('100', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  final double score;

  GaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 8;
    
    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Foreground arc
    final fgPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
