import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AstraBrandGlyph extends StatelessWidget {
  final double size;

  const AstraBrandGlyph({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: 45 * math.pi / 180,
        child: Container(
          width: size * 0.76,
          height: size * 0.76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.16),
            border: Border.all(
              color: AppTheme.cyan,
              width: size * 0.20,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cyan.withOpacity(0.4),
                blurRadius: 16,
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.all(size * 0.05),
            decoration: BoxDecoration(
              color: AppTheme.obsidian,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }
}

class AstraBrand extends StatelessWidget {
  final bool compact;
  final double size;

  const AstraBrand({
    super.key,
    this.compact = false,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AstraBrandGlyph(size: size),
        if (!compact) ...[
          const SizedBox(width: 10),
          const Text(
            'ASTRA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
            ),
          ),
        ],
      ],
    );
  }
}

class AstraLiveDot extends StatelessWidget {
  final double size;

  const AstraLiveDot({super.key, this.size = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.cyan,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.cyan.withOpacity(0.9),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
