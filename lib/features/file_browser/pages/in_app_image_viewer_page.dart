// lib/features/file_browser/pages/in_app_image_viewer_page.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/browser_item.dart';

class InAppImageViewerPage extends StatefulWidget {
  const InAppImageViewerPage({
    super.key,
    required this.initialItem,
    required this.playlist,
  });

  final BrowserItem initialItem;
  final List<BrowserItem> playlist;

  @override
  State<InAppImageViewerPage> createState() => _InAppImageViewerPageState();
}

class _InAppImageViewerPageState extends State<InAppImageViewerPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _closeAnimationController;
  late Animation<Offset> _closeSlideAnimation;
  late Animation<double> _closeFadeAnimation;
  int _currentIndex = 0;
  bool _showOverlay = false;
  Timer? _hideOverlayTimer;
  static const Duration _overlayVisibleDuration = Duration(seconds: 5);
  static const double _swipeVelocityThreshold = 400;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.playlist.indexWhere((e) => e.id == widget.initialItem.id);
    if (_currentIndex < 0) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);

    _closeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _closeSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 0.25),
    ).animate(CurvedAnimation(
      parent: _closeAnimationController,
      curve: Curves.easeInOut,
    ));
    _closeFadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _closeAnimationController, curve: Curves.easeOut),
    );
    _closeAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Get.back();
      }
    });
  }

  @override
  void dispose() {
    _hideOverlayTimer?.cancel();
    _closeAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_showOverlay) {
      _hideOverlayTimer?.cancel();
      setState(() => _showOverlay = false);
    } else {
      setState(() => _showOverlay = true);
      _hideOverlayTimer?.cancel();
      _hideOverlayTimer = Timer(_overlayVisibleDuration, () {
        if (mounted) setState(() => _showOverlay = false);
      });
    }
  }

  void _closeWithAnimation() {
    if (_closeAnimationController.isAnimating) return;
    _closeAnimationController.forward();
  }

  void _showDetailsSheet() {
    final item = widget.playlist.isNotEmpty && _currentIndex < widget.playlist.length
        ? widget.playlist[_currentIndex]
        : widget.initialItem;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ImageDetailsCard(item: item),
    );
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > _swipeVelocityThreshold) {
      _closeWithAnimation();
    } else if (velocity < -_swipeVelocityThreshold) {
      _showDetailsSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlist = widget.playlist;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _closeAnimationController,
        builder: (context, child) {
          return Opacity(
            opacity: _closeFadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _closeSlideAnimation.value.dy * MediaQuery.sizeOf(context).height),
              child: child,
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: _onTap,
              onVerticalDragEnd: _onVerticalDragEnd,
              child: PageView.builder(
                controller: _pageController,
                itemCount: playlist.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, i) {
                  final item = playlist[i];
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Center(
                      child: Image.file(
                        File(item.path),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                                child: Icon(Icons.broken_image,
                                    size: 64, color: Colors.white54)),
                      ),
                    ),
                  );
                },
              ),
            ),
            AnimatedOpacity(
              opacity: _showOverlay ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showOverlay,
                child: SafeArea(
                  child: Column(
                    children: [
                      AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Get.back(),
                        ),
                        title: Text(
                          playlist.isNotEmpty && _currentIndex < playlist.length
                              ? playlist[_currentIndex].name
                              : widget.initialItem.name,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageDetailsCard extends StatelessWidget {
  const _ImageDetailsCard({required this.item});
  final BrowserItem item;

  String _formatSize(int bytes) {
    if (bytes <= 0) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final onSurface = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Image details',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _DetailRow(
                icon: Icons.title,
                label: 'Title',
                value: item.name,
                onSurface: onSurface,
              ),
              _DetailRow(
                icon: Icons.folder_outlined,
                label: 'Location',
                value: item.path,
                onSurface: onSurface,
              ),
              _DetailRow(
                icon: Icons.data_usage,
                label: 'Size',
                value: _formatSize(item.sizeBytes),
                onSurface: onSurface,
              ),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Modified',
                value: _formatDate(item.modified),
                onSurface: onSurface,
              ),
              _DetailRow(
                icon: Icons.category_outlined,
                label: 'Type',
                value: item.mimeType.isNotEmpty ? item.mimeType : '—',
                onSurface: onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onSurface,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: onSurface.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: onSurface,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
