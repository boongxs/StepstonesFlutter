import 'package:flutter/material.dart';

class EditTagsDialog extends StatefulWidget {
  final String initialTags;

  const EditTagsDialog({
    super.key,
    required this.initialTags
  });

  @override
  State<EditTagsDialog> createState() => _EditTagsDialogState();
}

class _EditTagsDialogState extends State<EditTagsDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    // pre-fill text field with existing tags, if any
    _controller = TextEditingController(text: widget.initialTags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // dialog returns the text string on Save, or null on Cancel
    return Dialog(
      backgroundColor: const Color(0xFF282828),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 700,
        height: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            const Text(
              "Tags",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // input area
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null, // allow multiline
                  expands: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: Theme.of(context).colorScheme.primary,
                  decoration: const InputDecoration(
                    hintText: "Type space separated tags here (e.g. apple monkey...)",
                    hintStyle: TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context), // return null
                  child: const Text("Cancel"),
                ),

                const SizedBox(width: 16),

                FilledButton(
                  onPressed: () {
                    // return text content
                    Navigator.pop(context, _controller.text);
                  },
                  child: const Text("Save"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}