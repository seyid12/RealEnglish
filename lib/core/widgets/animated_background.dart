import 'package:flutter/material.dart';
import '../theme/color_palette.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark cosmic background
        Container(color: ColorPalette.background),
        // Animated glowing meshes
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _GlowPainter(_controller.value),
              child: Container(),
            );
          },
        ),
        // Main content
        widget.child,
      ],
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double animationValue;

  _GlowPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Primary Glow (Top Left moving towards center)
    final primaryCenter = Offset(
      size.width * 0.2 + (animationValue * size.width * 0.1),
      size.height * 0.2 + (animationValue * size.height * 0.1),
    );
    final primaryPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          ColorPalette.primary.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.2, 1.0],
      ).createShader(Rect.fromCircle(center: primaryCenter, radius: size.width * 0.8));
    canvas.drawRect(Offset.zero & size, primaryPaint);

    // Secondary Glow (Bottom Right)
    final secondaryCenter = Offset(
      size.width * 0.8 - (animationValue * size.width * 0.1),
      size.height * 0.8 - (animationValue * size.height * 0.1),
    );
    final secondaryPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          ColorPalette.secondary.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.2, 1.0],
      ).createShader(Rect.fromCircle(center: secondaryCenter, radius: size.width * 0.8));
    canvas.drawRect(Offset.zero & size, secondaryPaint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
