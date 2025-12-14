import 'package:flutter/material.dart';

class SyncStatusCard extends StatelessWidget {
  final String text;
  final bool isVisible;
  final bool isLoading;

  const SyncStatusCard({
    super.key,
    required this.text,
    required this.isVisible,
    required this.isLoading
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer( // if invisible, ignore presses
        ignoring: !isVisible,
        child: Card(
          elevation: 4,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading) ...[
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2)
                  ),
                  const SizedBox(width: 12),
                ] else ...[
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 12),
                ],
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              ]
            )
          )
        )
      )
    );
  }
}