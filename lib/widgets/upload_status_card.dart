import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../locator.dart';
import '../providers/upload_status_provider.dart';

class UploadStatusCard extends StatelessWidget
{
  const UploadStatusCard({super.key});

  @override
  Widget build(BuildContext context)
  {
    return ChangeNotifierProvider.value(
      value: getIt<UploadStatusProvider>(),
      child: Consumer<UploadStatusProvider>(
        builder: (context, vm, _) {
          if (!vm.isVisible) return const SizedBox.shrink();

          return Container(
            width: 300,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF2b2b2b),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF404040), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vm.statusTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    // expand button
                    IconButton(
                      icon: Icon(
                        vm.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: vm.toggleExpanded,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 10),

                    // close button
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: vm.close,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                // active file progress
                if (vm.currentFileName.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    vm.currentFileName,
                    style: const TextStyle(color: Color(0xFFadadad), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: vm.currentFileProgress,
                    backgroundColor: const Color(0xFF404040),
                    color: Colors.deepPurpleAccent,
                    minHeight: 4,
                  ),
                ],

                // expanded summary
                if (vm.isExpanded) ...[
                  const SizedBox(height: 10),
                  _buildSummaryLine(vm.summarySuccess),
                  _buildSummaryLine(vm.summaryDuplicates),
                  _buildSummaryLine(vm.summaryFailed),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryLine(String text)
  {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFadadad), fontSize: 12),
      ),
    );
  }
}