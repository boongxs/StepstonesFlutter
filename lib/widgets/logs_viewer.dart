import 'package:flutter/material.dart';
import '../services/logger_service.dart';

class LogsViewer extends StatefulWidget {
  const LogsViewer({super.key});

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

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              Color textColor = Colors.white70;
              if (log.contains("[ERROR]")) textColor = Colors.redAccent;
              else if (log.contains("[WARN]")) textColor = Colors.orangeAccent;
              else if (log.contains("[DEBUG]")) textColor = Colors.blueGrey;
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