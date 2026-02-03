import 'package:flutter/material.dart';

class SharedAxisTransitionRoute extends PageRouteBuilder {
  final Widget page;

  SharedAxisTransitionRoute(this.page)
      : super(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, secondary, child) {
      final scale = Tween<double>(begin: 0.9, end: 1.0).animate(animation);
      final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(animation);

      return FadeTransition(
        opacity: opacity,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}
