import 'package:flutter/material.dart';

class SelectionBorderPainter extends CustomPainter {
  final Color color;
  final double cutoutRadius;
  final double borderRadius;

  SelectionBorderPainter({
    required this.color,
    this.cutoutRadius = 60.0,
    this.borderRadius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(cutoutRadius, 0)
      ..lineTo(w - borderRadius, 0)
      ..arcToPoint(Offset(w, borderRadius), radius: Radius.circular(borderRadius))
      ..lineTo(w, h - borderRadius)
      ..arcToPoint(Offset(w - borderRadius, h), radius: Radius.circular(borderRadius))
      ..lineTo(borderRadius, h)
      ..arcToPoint(Offset(0, h - borderRadius), radius: Radius.circular(borderRadius))
      ..lineTo(0, cutoutRadius)
      ..arcToPoint(
        Offset(cutoutRadius, 0),
        radius: Radius.circular(cutoutRadius),
        clockwise: false,
      );
    
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant SelectionBorderPainter oldDelegate) {
    return color != oldDelegate.color || cutoutRadius != oldDelegate.cutoutRadius || borderRadius != oldDelegate.borderRadius;
  }
}