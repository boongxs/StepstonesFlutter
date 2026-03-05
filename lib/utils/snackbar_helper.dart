import 'package:flutter/material.dart';

extension SnackBarHelper on ScaffoldMessengerState {
  void showStepstonesSnackBar(String message, {bool isError = false}) {
    clearSnackBars();

    final iconColor = isError ? Colors.redAccent : Colors.greenAccent;
    final iconData = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

    showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: iconColor),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF303030),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        width: 350,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// extension to call it directly on BuildContext
extension ContextSnackBarHelper on BuildContext {
  void showStepstonesSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showStepstonesSnackBar(message, isError: isError);
  }
}