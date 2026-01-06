import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/main_provider.dart';

class SelectionModeCard extends StatelessWidget {
  const SelectionModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MainProvider>();
    final selection = vm.selection;

    // if not in selection mode, don't render anything
    if (!selection.isSelectionMode) return const SizedBox.shrink();

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181a1a),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title
          Text(
            "Selected ${selection.selectedCount} items",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          // select all / unselect all button
          _HoverButton(
            height: 40,
            baseColor: Colors.transparent,
            hoverColor: const Color(0xFF202b29),
            contentColor: const Color(0xFF65c2b2),
            defaultContentColor: Colors.white,
            onTap: selection.toggleSelectAll,
            builder: (isHovered) {
              final color = isHovered ? const Color(0xFF65c2b2) : Colors.white;
              return Row(
                children: [
                  Icon(
                    selection.areAllSelected
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                    color: color,
                    size: 20,
                  ),
                  
                  const SizedBox(width: 12),

                  Text(
                    selection.areAllSelected ? "Unselect all" : "Select all",
                    style: TextStyle(color: color, fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),

          // delete selected button
          if (selection.areAllSelected || selection.selectedCount > 0) ...[
            _HoverButton(
              height: 40,
              baseColor: Colors.transparent,
              hoverColor: const Color(0xFF2e1e1e),
              contentColor: const Color(0xFFf87171),
              defaultContentColor: Colors.white,
              onTap: selection.isDeleting ? () {} : selection.deleteSelected,
              builder: (isHovered) {
                // if deleting, show spinner
                if (selection.isDeleting) {
                  return Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: const Color(0xFFf87171),
                      ),
                    ),
                  );
                }

                // otherwise, show standard icon + text
                final color = isHovered ? const Color(0xFFf87171) : Colors.white;
                return Row(
                  children: [
                    Icon(Icons.delete_outline, color: color, size: 20),

                    const SizedBox(width: 12),

                    Text(
                      "Delete selected",
                      style: TextStyle(color: color, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 16),

          // cancel button (bottom right)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _HoverButton(
                isFullWidth: false,
                baseColor: Colors.transparent,
                hoverColor: const Color(0xFF432323),
                contentColor: const Color(0xFFf87171),
                defaultContentColor: const Color(0xFFf87171),
                onTap: selection.toggleSelectionMode,
                builder: (isHovered) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Color(0xFFf87171),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// helper widget to handle hover logic
class _HoverButton extends StatefulWidget {
  final double? height;
  final bool isFullWidth;
  final Color baseColor;
  final Color hoverColor;
  final Color contentColor;
  final Color defaultContentColor;
  final VoidCallback onTap;
  final Widget Function(bool isHovered) builder;

  const _HoverButton({
    this.height,
    this.isFullWidth = true,
    required this.baseColor,
    required this.hoverColor,
    required this.contentColor,
    required this.defaultContentColor,
    required this.onTap,
    required this.builder,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: widget.height,
          width: widget.isFullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor : widget.baseColor,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: widget.height == null ? null : const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          child: widget.builder(_isHovered),
        ),
      ),
    );
  }
}