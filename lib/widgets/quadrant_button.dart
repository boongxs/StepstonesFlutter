import 'package:flutter/material.dart';

class QuadrantButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color hoverColor;

  const QuadrantButton({
    required this.icon,
    required this.onTap,
    required this.hoverColor,
  });

  @override
  State<QuadrantButton> createState() => _QuadrantButtonState();
}

class _QuadrantButtonState extends State<QuadrantButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // MouseRegion tracks hover for this specific quadrant
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,

        // GestureDetector handles clicks
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Icon(
              widget.icon,
              size: 48,
              color: _isHovered ? widget.hoverColor : Colors.white,
            )
          )
        )
      )
    );
  }
}