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
  bool _hasFocus = false;
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
      if (!_focusNode.hasFocus) {
        // Delay so an overlay tap can complete before the overlay is removed.
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_focusNode.hasFocus) _hideSuggestions();
        });
      }
    });
  }

  @override
  void dispose() {
    _hideSuggestions();
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
    final exclude = _getAlreadyTyped(text);
    final results = await widget.onSuggest!(partial, exclude);
    if (!mounted) return;
    setState(() => _suggestions = results);
    if (results.isEmpty) {
      _hideSuggestions();
    } else {
      _showSuggestions();
    }
  }

  void _acceptSuggestion(String tag) {
    final current = widget.controller.text;
    final parts = current.trimLeft().split(RegExp(r'\s+'));
    if (parts.isNotEmpty) parts[parts.length - 1] = tag;
    final newText = '${parts.join(' ')} ';
    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(offset: newText.length);
    widget.onChanged?.call(newText);
    _hideSuggestions();
  }

  void _showSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _suggestions = []);
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (ctx) => Positioned(
        width: widget.width ?? 600,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, (widget.height ?? 72) + 4),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: const Color(0xff303030),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF555555)),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (_, i) => InkWell(
                  onTap: () => _acceptSuggestion(_suggestions[i]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(_suggestions[i], style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: CompositedTransformTarget(
          link: _layerLink,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: const Color(0xff303030),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hasFocus ? const Color.fromARGB(255, 117, 117, 117) : Colors.transparent,
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
