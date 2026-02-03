import 'package:flutter/material.dart';

class SizeTransitionRoute extends PageRouteBuilder {
  final Widget page;

  SizeTransitionRoute(this.page)
      : super(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return Align(
        child: SizeTransition(
          sizeFactor: animation,
          child: child,
        ),
      );
    },
  );
}
