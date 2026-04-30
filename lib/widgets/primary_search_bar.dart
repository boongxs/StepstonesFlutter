import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrimarySearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSearch;
  final Future<List<({String name, int count})>> Function(String partial, List<String> exclude)? onSuggest;

  final double? width;
  final double? height;
  final double? fontSize;

  const PrimarySearchBar({
    super.key,
    required this.controller,
    this.onSearch,
    this.onSuggest,
    this.width = 600,
    this.height = 72,
    this.fontSize = 32,
  });

  @override
  State<PrimarySearchBar> createState() => _PrimarySearchBarState();
}

class _PrimarySearchBarState extends State<PrimarySearchBar> {
  late final FocusNode _focusNode;
  final LayerLink _layerLink = LayerLink();
  final ScrollController _suggestionsScrollController = ScrollController();
  bool _hasFocus = false;
  bool _disposed = false;
  OverlayEntry? _overlayEntry;
  List<({String name, int count})> _suggestions = [];
  int _selectedIndex = -1;
  String? _textBeforeNavigation;

  static const _borderColor = Color.fromARGB(255, 117, 117, 117);
  static const _borderSide = BorderSide(color: _borderColor, width: 2);
  static const _itemHeight = 40.0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(onKeyEvent: (_, event) => _handleKeyEvent(event));
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _updateSuggestions(widget.controller.text);
      } else {
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

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_selectedIndex >= 0 && _selectedIndex < _suggestions.length) {
        _acceptSuggestion(_suggestions[_selectedIndex].name);
      } else {
        widget.onSearch?.call();
      }
      return KeyEventResult.handled;
    }

    if (_suggestions.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final next = (_selectedIndex + 1).clamp(0, _suggestions.length - 1);
      if (next != _selectedIndex) {
        if (_selectedIndex == -1) _textBeforeNavigation = widget.controller.text;
        _selectedIndex = next;
        _overlayEntry?.markNeedsBuild();
        _scrollToSelected();
        _previewSuggestion(_suggestions[_selectedIndex].name);
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_selectedIndex > 0) {
        _selectedIndex--;
        _overlayEntry?.markNeedsBuild();
        _scrollToSelected();
        _previewSuggestion(_suggestions[_selectedIndex].name);
      } else if (_selectedIndex == 0) {
        _selectedIndex = -1;
        _overlayEntry?.markNeedsBuild();
        _restoreTextBeforeNavigation();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _restoreTextBeforeNavigation();
      _hideSuggestions();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollToSelected() {
    if (_selectedIndex < 0) return;
    if (!_suggestionsScrollController.hasClients) return;
    const topPadding = 8.0;
    final itemTop = topPadding + _selectedIndex * _itemHeight;
    final itemBottom = itemTop + _itemHeight;
    final offset = _suggestionsScrollController.offset;
    final viewportHeight = _suggestionsScrollController.position.viewportDimension;

    if (itemTop < offset) {
      _suggestionsScrollController.jumpTo(itemTop);
    } else if (itemBottom > offset + viewportHeight) {
      _suggestionsScrollController.jumpTo(itemBottom - viewportHeight);
    }
  }

  void _previewSuggestion(String tag) {
    final base = _textBeforeNavigation ?? widget.controller.text;
    final parts = base.trimLeft().split(RegExp(r'\s+'));
    if (parts.isNotEmpty) parts[parts.length - 1] = tag;
    final newText = parts.join(' ');
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  void _restoreTextBeforeNavigation() {
    if (_textBeforeNavigation == null) return;
    widget.controller.value = TextEditingValue(
      text: _textBeforeNavigation!,
      selection: TextSelection.collapsed(offset: _textBeforeNavigation!.length),
    );
    _textBeforeNavigation = null;
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
      if (text.trim().isEmpty) widget.onSearch?.call();
      return;
    }
    final overlay = Overlay.of(context);
    final exclude = _getAlreadyTyped(text);
    final results = await widget.onSuggest!(partial, exclude);
    if (_disposed) return;
    if (results.isEmpty) {
      _hideSuggestions();
    } else {
      setState(() {
        _suggestions = results;
        _selectedIndex = -1;
      });
      if (_overlayEntry == null) {
        _overlayEntry = _buildOverlay();
        overlay.insert(_overlayEntry!);
      } else {
        _overlayEntry!.markNeedsBuild();
      }
    }
  }

  void _hideSuggestions() {
    _textBeforeNavigation = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!_disposed) {
      setState(() {
        _suggestions = [];
        _selectedIndex = -1;
      });
    }
  }

  void _acceptSuggestion(String tag) {
    final base = _textBeforeNavigation ?? widget.controller.text;
    final parts = base.trimLeft().split(RegExp(r'\s+'));
    if (parts.isNotEmpty) parts[parts.length - 1] = tag;
    final newText = '${parts.join(' ')} ';
    widget.controller.text = newText;
    _hideSuggestions();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        widget.controller.selection = TextSelection.collapsed(offset: newText.length);
      }
    });
    widget.onSearch?.call();
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shrinkWrap: true,
                          itemExtent: _itemHeight,
                          itemCount: _suggestions.length,
                          itemBuilder: (_, i) => _SuggestionItem(
                            label: _suggestions[i].name,
                            count: _suggestions[i].count,
                            isSelected: i == _selectedIndex,
                            onTap: () => _acceptSuggestion(_suggestions[i].name),
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
            padding: const EdgeInsets.only(left: 16),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              style: TextStyle(fontSize: widget.fontSize, height: 1.0),
              textAlignVertical: TextAlignVertical.center,
              cursorColor: const Color.fromARGB(255, 161, 161, 161),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
                hintText: "Search...",
                hintStyle: const TextStyle(color: Colors.grey),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Tooltip(
                    message: 'Search',
                    child: IconButton(
                      onPressed: widget.onSearch,
                      icon: const Icon(Icons.search_rounded),
                      color: Colors.grey,
                      iconSize: (widget.fontSize ?? 32) * 1.0,
                      splashRadius: 24,
                    ),
                  ),
                ),
              ),
              onChanged: _updateSuggestions,
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionItem extends StatefulWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _SuggestionItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SuggestionItem> createState() => _SuggestionItemState();
}

class _SuggestionItemState extends State<_SuggestionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 11, 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: (widget.isSelected || _isHovered)
                  ? const Color(0xFF3D3D3D)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Text(widget.label, style: const TextStyle(fontSize: 14)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF484848),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9A9A9A)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
