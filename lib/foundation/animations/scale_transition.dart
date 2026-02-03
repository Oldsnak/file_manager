import 'package:flutter/material.dart';

class ScaleTransitionRoute extends PageRouteBuilder {
  final Widget page;

  ScaleTransitionRoute(this.page)
      : super(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        ),
        child: child,
      );
    },
  );
}
