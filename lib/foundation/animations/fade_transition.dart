import 'package:flutter/material.dart';

class FadeTransitionRoute extends PageRouteBuilder {
  final Widget page;

  FadeTransitionRoute(this.page)
      : super(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
