import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Tooltip(
        message: tooltip,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF404040),
            foregroundColor: const Color(0xFFf0f0f0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }
}