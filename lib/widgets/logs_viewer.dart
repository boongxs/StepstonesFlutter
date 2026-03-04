import 'package:flutter/material.dart';
import '../services/logger_service.dart';

class LogsViewer extends StatefulWidget {
  final int lastSeenLogCount;

  const LogsViewer({
    super.key,
    required this.lastSeenLogCount,
  });

  @override
  State<LogsViewer> createState() => _LogsViewerState();
}

class _LogsViewerState extends State<LogsViewer> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(child: Divider(
            color: Colors.redAccent,
            thickness: 1,
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              "New Logs",
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.redAccent,
              thickness: 1
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: ValueListenableBuilder<List<String>>(
        valueListenable: LogService.liveLogs,
        builder: (context, logs, child) {
          // auto-scroll after new items
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

          // determine if we need to show separator between old and new logs
          final bool showSeparator = widget.lastSeenLogCount > 0 && widget.lastSeenLogCount < logs.length;
          final int totalItems = showSeparator ? logs.length + 1 : logs.length;

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: totalItems,
            itemBuilder: (context, index) {
              // draw separator at "last seen" boundary
              if (showSeparator && index == widget.lastSeenLogCount) {
                return _buildSeparator();
              }

              // adjust index mapping because separator took up a slot in ListView
              int actualLogIndex = index;
              if (showSeparator && index > widget.lastSeenLogCount) {
                actualLogIndex = index - 1;
              }

              final log = logs[actualLogIndex];
              Color textColor = Colors.white70;

              if (log.contains("[ERROR]")) {
                textColor = Colors.redAccent;
              } else if (log.contains("[WARN]")) {
                textColor = Colors.orangeAccent;
              } else if (log.contains("[DEBUG]")) {
                textColor = Colors.blueGrey;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: SelectableText(
                  log,
                  style: TextStyle(
                    color: textColor,
                    fontFamily: "monospace",
                    fontSize: 13,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}