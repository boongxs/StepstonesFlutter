import 'package:flutter/material.dart';

class PrimarySearchBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;

  const PrimarySearchBar({
    super.key,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xff303030),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 7),
      child: TextField(
        style: const TextStyle(fontSize: 32, height: 1.0),
        textAlignVertical: TextAlignVertical.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isCollapsed: true,
          hintText: "Search...",
          hintStyle: TextStyle(color: Colors.grey),
        ),
        onChanged: onChanged,
      ),
    );
  }
}