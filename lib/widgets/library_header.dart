import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../controllers/session_controller.dart';
import '../controllers/gallery_controller.dart';
import '../models/media_sort_option.dart';

class LibraryHeader extends StatelessWidget {
  const LibraryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final gallery = context.watch<GalleryController>();
    final themeColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 29),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xff222222),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Folder name & item count
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.folder_open_rounded, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    session.mediaFolderPath != null
                        ? p.basename(session.mediaFolderPath!)
                        : "No Folder Selected",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text("•", style: TextStyle(color: Colors.grey[600])),
                ),
                Text(
                  "Currently showing ${gallery.totalItemCount} media items",
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),

          // Sort dropdown
          Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: PopupMenuThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF555555)),
                ),
              ),
            ),
            child: PopupMenuButton<void>(
              tooltip: "",
              constraints: const BoxConstraints(maxWidth: 195),
              padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Sort",
                    style: TextStyle(fontSize: 13, color: Color.fromARGB(255, 202, 202, 202)),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.sort_rounded, size: 18),
              ],
            ),
            itemBuilder: (menuCtx) {
              final ctrl = context.read<GalleryController>();
              final field = gallery.currentSortField;
              final dir = gallery.currentSortDirection;

              // called by direction buttons (Date Added, Media Date)
              void pick(SortField f, SortDirection d) {
                Navigator.pop(menuCtx);
                ctrl.setSortFieldAndDirection(f, d);
              }

              // called by File Type sort option
              void pickField(SortField f) {
                Navigator.pop(menuCtx);
                ctrl.setSortField(f);
              }

              return [
                PopupMenuItem<void>(
                  enabled: false,
                  padding: EdgeInsets.zero,
                  child: _SortItem(
                    label: 'Date Added',
                    themeColor: themeColor,
                    showDirectionButtons: true,
                    ascActive: field == SortField.dateAdded && dir == SortDirection.asc,
                    descActive: field == SortField.dateAdded && dir == SortDirection.desc,
                    onAscTap: () => pick(SortField.dateAdded, SortDirection.asc),
                    onDescTap: () => pick(SortField.dateAdded, SortDirection.desc),
                  ),
                ),
                PopupMenuItem<void>(
                  enabled: false,
                  padding: EdgeInsets.zero,
                  child: _SortItem(
                    label: 'Media Date',
                    themeColor: themeColor,
                    showDirectionButtons: true,
                    ascActive: field == SortField.mediaDate && dir == SortDirection.asc,
                    descActive: field == SortField.mediaDate && dir == SortDirection.desc,
                    onAscTap: () => pick(SortField.mediaDate, SortDirection.asc),
                    onDescTap: () => pick(SortField.mediaDate, SortDirection.desc),
                  ),
                ),
                PopupMenuItem<void>(
                  enabled: false,
                  padding: EdgeInsets.zero,
                  child: _SortItem(
                    label: 'File Type',
                    isActive: field == SortField.fileType,
                    themeColor: themeColor,
                    onTap: () => pickField(SortField.fileType),
                  ),
                ),
              ];
            },
          ),
          ),
        ],
      ),
    );
  }
}

class _SortItem extends StatefulWidget {
  final String label;
  final bool? isActive;
  final Color themeColor;
  final bool showDirectionButtons;
  final bool ascActive;
  final bool descActive;
  final VoidCallback? onTap;
  final VoidCallback? onAscTap;
  final VoidCallback? onDescTap;

  const _SortItem({
    required this.label,
    required this.themeColor,
    this.isActive,
    this.showDirectionButtons = false,
    this.ascActive = false,
    this.descActive = false,
    this.onTap,
    this.onAscTap,
    this.onDescTap,
  });

  @override
  State<_SortItem> createState() => _SortItemState();
}

class _SortItemState extends State<_SortItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.showDirectionButtons
        ? (widget.ascActive || widget.descActive)
        : (widget.isActive ?? false);
    final textColor = (isActive || _isHovered) ? widget.themeColor : Colors.white;

    final label = Padding(
      padding: const EdgeInsets.only(left: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.showDirectionButtons
              ? (widget.ascActive ? widget.onDescTap : widget.onAscTap)
              : widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(widget.label, style: TextStyle(color: textColor)),
          ),
        ),
      ),
    );

    if (!widget.showDirectionButtons) return label;

    return Row(
      children: [
        label,
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 16, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DirectionButton(
                isAscButton: true,
                isActive: widget.ascActive,
                themeColor: widget.themeColor,
                onTap: widget.onAscTap!,
              ),
              _DirectionButton(
                isAscButton: false,
                isActive: widget.descActive,
                themeColor: widget.themeColor,
                onTap: widget.onDescTap!,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DirectionButton extends StatelessWidget {
  final bool isAscButton;
  final bool isActive;
  final Color themeColor;
  final VoidCallback onTap;

  const _DirectionButton({
    required this.isAscButton,
    required this.isActive,
    required this.themeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const gray = Color(0xFF6f6f6f);
    const arrowGray = Color.fromARGB(255, 175, 175, 175);
    final upColor = isAscButton ? themeColor : arrowGray;
    final downColor = isAscButton ? arrowGray : themeColor;
    final br = isAscButton
        ? const BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4))
        : const BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4));
    final borderColor = isActive ? themeColor : gray;

    final side = BorderSide(color: borderColor);
    final innerSide = isActive ? side : BorderSide.none;

    return InkWell(
      onTap: onTap,
      borderRadius: br,
      child: Container(
        width: 26,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? themeColor.withValues(alpha: 0.35) : Colors.transparent,
          borderRadius: br,
          border: Border(
            top: side,
            bottom: side,
            left: isAscButton ? side : innerSide,
            right: isAscButton ? innerSide : side,
          ),
        ),
        child: IconTheme(
          data: const IconThemeData(opacity: 1.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_drop_up, size: 16, color: upColor),
              Icon(Icons.arrow_drop_down, size: 16, color: downColor),
            ],
          ),
        ),
      ),
    );
  }
}
