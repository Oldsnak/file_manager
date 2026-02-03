import 'package:flutter/material.dart';

class SlideRightTransition extends PageRouteBuilder {
  final Widget page;

  SlideRightTransition(this.page)
      : super(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(animation);

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}
