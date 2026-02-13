import 'package:flutter/material.dart';

class ToolbarButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const ToolbarButton({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        hoverColor: color.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}