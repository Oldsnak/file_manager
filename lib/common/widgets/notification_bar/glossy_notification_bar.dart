import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../foundation/constants/colors.dart';
import '../../../foundation/helpers/helper_functions.dart';

class GlossyNotificationBar {
  static void show(
      BuildContext context, {
        required String title,
        required String message,
        IconData icon = Icons.notifications,
        bool isError = false,
        Duration duration = const Duration(seconds: 3),
      }) {
    final bool isDarkMode = THelperFunctions.isDarkMode(context);
    final overlay = Overlay.of(context);

    if (overlay == null) return;

    final overlayEntry = OverlayEntry(
      builder: (context) => _GlossyNotificationWidget(
        title: title,
        message: message,
        icon: icon,
        isError: isError,
        isDarkMode: isDarkMode,
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}

class _GlossyNotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final bool isError;
  final bool isDarkMode;
  final Duration duration;

  const _GlossyNotificationWidget({
    required this.title,
    required this.message,
    required this.icon,
    required this.isError,
    required this.isDarkMode,
    required this.duration,
  });

  @override
  State<_GlossyNotificationWidget> createState() =>
      _GlossyNotificationWidgetState();
}

class _GlossyNotificationWidgetState
    extends State<_GlossyNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _slideAnimation =
        Tween(begin: const Offset(0, -1.0), end: const Offset(0, 0))
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation =
        Tween(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    Future.delayed(widget.duration - const Duration(milliseconds: 300), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode
        ? TColors.darkPrimaryContainer.withOpacity(0.85)
        : TColors.lightPrimaryContainer.withOpacity(0.85);

    final borderColor = widget.isError
        ? TColors.error.withOpacity(0.6)
        : TColors.primary.withOpacity(0.6);

    final iconColor = widget.isError ? TColors.error : TColors.primary;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(2, 4),
                      blurRadius: 10,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      offset: const Offset(-2, -2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.icon, color: iconColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.message,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: widget.isDarkMode
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.black.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
