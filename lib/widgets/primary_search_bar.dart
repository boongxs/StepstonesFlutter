import 'package:flutter/material.dart';

class PrimarySearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const PrimarySearchBar({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  State<PrimarySearchBar> createState() => _PrimarySearchBarState();
}

class _PrimarySearchBarState extends State<PrimarySearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          width: 600,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xff303030),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hasFocus ? const Color.fromARGB(255, 117, 117, 117) : Colors.transparent,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 7),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            style: const TextStyle(fontSize: 32, height: 1.0),
            textAlignVertical: TextAlignVertical.center,
            cursorColor: const Color.fromARGB(255, 161, 161, 161),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isCollapsed: true,
              hintText: "Search...",
              hintStyle: TextStyle(color: Colors.grey),
            ),
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}