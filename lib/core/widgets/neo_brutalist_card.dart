import 'package:flutter/material.dart';
import '../theme/color_palette.dart';

class NeoBrutalistCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final Offset shadowOffset;

  const NeoBrutalistCard({
    super.key,
    required this.child,
    this.color,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderWidth = 3.0,
    this.shadowOffset = const Offset(6, 6),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? ColorPalette.surface,
          border: Border.all(color: ColorPalette.textDark, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: ColorPalette.textDark,
              offset: shadowOffset,
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
