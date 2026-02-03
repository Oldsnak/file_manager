import 'package:flutter/material.dart';

class RotateTransitionRoute extends PageRouteBuilder {
  final Widget page;

  RotateTransitionRoute(this.page)
      : super(
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return RotationTransition(
        turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
        child: child,
      );
    },
  );
}
