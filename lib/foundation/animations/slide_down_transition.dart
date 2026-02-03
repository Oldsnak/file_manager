import 'package:flutter/material.dart';

class SlideDownTransition extends PageRouteBuilder {
  final Widget page;

  SlideDownTransition(this.page)
      : super(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0.0, -1.0),
        end: Offset.zero,
      ).animate(animation);

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}
