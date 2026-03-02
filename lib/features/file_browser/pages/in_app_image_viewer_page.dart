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

class _InAppImageViewerPageState extends State<InAppImageViewerPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showOverlay = true;
  Timer? _hideOverlayTimer;
  static const Duration _overlayVisibleDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.playlist.indexWhere((e) => e.id == widget.initialItem.id);
    if (_currentIndex < 0) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _hideOverlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onTap() {
    setState(() => _showOverlay = true);
    _hideOverlayTimer?.cancel();
    _hideOverlayTimer = Timer(_overlayVisibleDuration, () {
      if (mounted) setState(() => _showOverlay = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlist = widget.playlist;
    final hasMultiple = playlist.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _onTap,
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
                          const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.white54)),
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
              child: Container(
                color: Colors.black54,
                child: SafeArea(
                  child: Column(
                    children: [
                      AppBar(
                        backgroundColor: Colors.transparent,
                        leading: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Get.back(),
                        ),
                        title: Text(
                          playlist.isNotEmpty && _currentIndex < playlist.length
                              ? playlist[_currentIndex].name
                              : widget.initialItem.name,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasMultiple) ...[
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, color: Colors.white),
                              onPressed: _currentIndex > 0
                                  ? () {
                                      _pageController.previousPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  : null,
                            ),
                            Text(
                              '${_currentIndex + 1} / ${playlist.length}',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, color: Colors.white),
                              onPressed: _currentIndex < playlist.length - 1
                                  ? () {
                                      _pageController.nextPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
