import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../controllers/gallery_controller.dart';
import '../data/app_database.dart';
import '../services/media_action_service.dart';
import 'universal_player_mobile.dart';

class MediaViewerDialogMobile extends StatefulWidget {
  final int initialIndex;

  const MediaViewerDialogMobile({
    super.key,
    required this.initialIndex,
  });

  @override
  State<MediaViewerDialogMobile> createState() => _MediaViewerDialogMobileState();
}

class _MediaViewerDialogMobileState extends State<MediaViewerDialogMobile> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showToolbars = true;
  static const double _kBottomToolbarHeight = 90.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    imageCache.clear();
    imageCache.clearLiveImages();
    super.dispose();
  }

  void _toggleToolbars() {
    setState(() {
      _showToolbars = !_showToolbars;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<GalleryController>(
          builder: (context, gallery, _) {
            final MediaItem? currentItem = gallery.getItem(_currentIndex);

            return Stack(
              children: [
                // 1. swipeable pager
                PageView.builder(
                  controller: _pageController,
                  itemCount: gallery.totalItemCount,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = gallery.getItem(index);

                    if (item == null) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    final fullPath = p.join(item.mediaFolderPath, item.hashedFileName);

                    if (item.fileType == 'image' || item.fileType =='gif') {
                      // InteractiveViewer adds pinch-to-zoom and panning
                      return GestureDetector(
                        onTap: _toggleToolbars,
                        child: InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Image.file(
                            File(fullPath),
                            key: ValueKey(item.id),
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => const Center(
                              child: Icon(Icons.broken_image, color: Colors.white, size: 48),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return UniversalPlayerMobile(
                        key: ValueKey(item.id),
                        filePath: fullPath,
                        isAudio: item.fileType == 'audio',
                        showControls: _showToolbars,
                        onTap: _toggleToolbars,
                        bottomInset: _kBottomToolbarHeight,
                      );
                    }
                  },
                ),

                // 2. bottom toolbar
                if (currentItem != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildFadeWrapper(
                      child: _buildBottomToolbar(context, currentItem),
                    ),
                  ),
                
                // 3. top-left counter (e.g. 5 / 120)
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildFadeWrapper(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "${_currentIndex + 1} / ${gallery.totalItemCount}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // helper widget to handle fade animation and ignore touches when hidden
  Widget _buildFadeWrapper({required Widget child}) {
    return AnimatedOpacity(
      opacity: _showToolbars ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !_showToolbars,
        child: child,
      ),
    );
  }

  Widget _buildBottomToolbar(BuildContext context, MediaItem item) {
    return Container(
      height: _kBottomToolbarHeight,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        border: const Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // share
          _MobileToolbarButton(
            icon: Icons.share_rounded,
            label: "Share",
            color: Colors.white,
            onPressed: () => MediaActionService.onShare(context, item),
          ),

          // edit tags
          _MobileToolbarButton(
            icon: Icons.edit_rounded,
            label: "Tags",
            color: Colors.white,
            onPressed: () => MediaActionService.onEdit(context, item),
          ),

          // delete
          _MobileToolbarButton(
            icon: Icons.delete_outline_rounded,
            label: "Delete",
            color: Colors.white,
            onPressed: () async {
              await MediaActionService.onDelete(
                context,
                item,
                onConfirm: () {
                  // pop the viewer after deleting item
                  Navigator.pop(context);
                }
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MobileToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _MobileToolbarButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}