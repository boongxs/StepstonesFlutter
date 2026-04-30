import 'package:flutter/material.dart';

class PrimarySearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final Future<List<String>> Function(String partial, List<String> exclude)? onSuggest;

  final double? width;
  final double? height;
  final double? fontSize;

  const PrimarySearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSuggest,
    this.width = 600,
    this.height = 72,
    this.fontSize = 32,
  });

  @override
  State<PrimarySearchBar> createState() => _PrimarySearchBarState();
}

class _PrimarySearchBarState extends State<PrimarySearchBar> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final ScrollController _suggestionsScrollController = ScrollController();
  bool _hasFocus = false;
  bool _disposed = false;
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];

  static const _borderColor = Color.fromARGB(255, 117, 117, 117);
  static const _borderSide = BorderSide(color: _borderColor, width: 2);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!_disposed && !_focusNode.hasFocus) _hideSuggestions();
        });
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _suggestionsScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getLastPartial(String text) {
    final words = text.trimLeft().split(RegExp(r'\s+'));
    return words.isEmpty ? '' : words.last;
  }

  List<String> _getAlreadyTyped(String text) {
    final words = text.trim().toLowerCase().split(RegExp(r'\s+'));
    if (words.length <= 1) return [];
    return words.sublist(0, words.length - 1);
  }

  Future<void> _updateSuggestions(String text) async {
    if (widget.onSuggest == null) return;
    final partial = _getLastPartial(text);
    if (partial.isEmpty) {
      _hideSuggestions();
      return;
    }
    final overlay = Overlay.of(context);
    final exclude = _getAlreadyTyped(text);
    final results = await widget.onSuggest!(partial, exclude);
    if (_disposed) return;
    if (results.isEmpty) {
      _hideSuggestions();
    } else {
      setState(() => _suggestions = results);
      if (_overlayEntry == null) {
        _overlayEntry = _buildOverlay();
        overlay.insert(_overlayEntry!);
      } else {
        _overlayEntry!.markNeedsBuild();
      }
    }
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!_disposed) setState(() => _suggestions = []);
  }

  void _acceptSuggestion(String tag) {
    final current = widget.controller.text;
    final parts = current.trimLeft().split(RegExp(r'\s+'));
    if (parts.isNotEmpty) parts[parts.length - 1] = tag;
    final newText = '${parts.join(' ')} ';
    widget.controller.text = newText;
    widget.onChanged?.call(newText);
    _hideSuggestions();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        widget.controller.selection = TextSelection.collapsed(offset: newText.length);
      }
    });
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (_) => Positioned(
        width: widget.width ?? 600,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, widget.height ?? 72),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: const BoxDecoration(
                color: Color(0xff303030),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                border: Border(
                  left: _borderSide,
                  right: _borderSide,
                  bottom: _borderSide,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(
                    color: Color(0xFF555555),
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  Flexible(
                    child: RawScrollbar(
                      controller: _suggestionsScrollController,
                      thumbVisibility: true,
                      child: ScrollConfiguration(
                        behavior: const ScrollBehavior().copyWith(scrollbars: false),
                        child: ListView.builder(
                          controller: _suggestionsScrollController,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          itemBuilder: (_, i) => _SuggestionItem(
                            label: _suggestions[i],
                            onTap: () => _acceptSuggestion(_suggestions[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showSuggestions = _suggestions.isNotEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: const Color(0xff303030),
              borderRadius: showSuggestions
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    )
                  : BorderRadius.circular(10),
              border: showSuggestions
                  ? const Border(
                      top: _borderSide,
                      left: _borderSide,
                      right: _borderSide,
                    )
                  : Border.all(
                      color: _hasFocus ? _borderColor : Colors.transparent,
                      width: 2,
                    ),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              style: TextStyle(fontSize: widget.fontSize, height: 1.0),
              textAlignVertical: TextAlignVertical.center,
              cursorColor: const Color.fromARGB(255, 161, 161, 161),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
                hintText: "Search...",
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (text) {
                widget.onChanged?.call(text);
                _updateSuggestions(text);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionItem extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionItem({required this.label, required this.onTap});

  @override
  State<_SuggestionItem> createState() => _SuggestionItemState();
}

class _SuggestionItemState extends State<_SuggestionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0xFF3D3D3D) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(widget.label, style: const TextStyle(fontSize: 14)),
          ),
        ),
      ),
    );
  }
}
