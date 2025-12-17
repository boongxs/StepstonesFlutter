import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/main_provider.dart';
import '../data/app_database.dart';
import '../utils/min_extra_delegate.dart';

class MediaGrid extends StatelessWidget {
  const MediaGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MainProvider>(
      builder: (context, vm, _) {
        // empty state
        if (vm.mediaFolderPath == null) {
          return const Center(child: Text("Select a folder to begin"));
        }

        // show "no items" only if we are not currently syncing to avoid flicker on startup
        if (vm.totalItemCount == 0 && !vm.isSyncingWorkInProgress) {
          return const Center(child: Text("No media items found"));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(10),

          // virtualization: exact count ensures scrollbar is correct
          itemCount: vm.totalItemCount,

          // responsive layout
          gridDelegate: const SliverGridDelegateWithMinCrossAxisExtent(
            minCrossAxisExtent: 270, // cells will be around 500px wide
            mainAxisExtent: 250, // cells will be exactly 250px tall
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),

          itemBuilder: (context, index) {
            // ask provider for data, if null trigger fetch
            final MediaItem? item = vm.getItem(index);
            return _MediaCell(item: item, index: index);
          },
        );
      },
    );
  }
}

class _MediaCell extends StatelessWidget {
  final MediaItem? item;
  final int index;

  const _MediaCell({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    // loading state (cache miss)
    if (item == null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2)
          ),
        ),
      );
    }

    // loaded state
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            item!.originalFileName,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}